/** 
* Splits the text file specified as input in N chunks of <max_rows_in_each_chunk> each.
* If the total number of rows in the file is not a multiple of max_rows_in_each_chunk, the last chunk will have less rows than max_rows_in_each_chunk.
* By default, the macro creates the chunks in the same directory of the source file; a different directory can be specified using the parameter output_dir.
* Also, by default the macro deletes the original file after splitting it; this behaviour can be overidden using the parameter delete_source_file.
* Finally, by default the name of the chunks is <root>n.<extension of the original file>, where <root> is <name of the original file without extension>_;
* a different <root> che be specified using the parameter output_files_root_name
*
* @param file_to_split full path of the file to split
* @param max_rows_in_each_chunk size of the chunks, specified as number of rows
* @param output_dir output directory for the chunks, optional
* @param output_files_root_name root filename of the chunks, optional
* @param delete_source_file delete source file after splitting it, optional
*/

%macro util_split_text_file(file_to_split, max_rows_in_each_chunk, output_dir=, output_files_root_name=, delete_source_file=1);
	%local this_macroname rc source_file_ext;
	%let this_macroname = &SYSMACRONAME.;
	
	%if %superq(output_dir) = %then
		%let output_dir = %fsutil_get_dir(&file_to_split.);
	
	%if %superq(output_files_root_name) = %then
		%let output_files_root_name = %fsutil_get_filename(&file_to_split.)_;

	%let source_file_ext = %fsutil_get_file_extension(&file_to_split.);
	
	%util_print_log(<&this_macroname.> Inizio split di file %superq(file_to_split) in pezzi da &max_rows_in_each_chunk. righe)
	
	data _null_;
		infile "&file_to_split." length=reclen;

		retain records_written_in_current_file current_file_id;

		if _N_ = 1 then do;
			records_written_in_current_file = 0;
			current_file_id = 1;
		end;

		if records_written_in_current_file = &max_rows_in_each_chunk. then do;
			current_file_id = current_file_id + 1;
			records_written_in_current_file = 0;
		end;

		output_file = cats("&output_dir./&output_files_root_name.", compress(put(current_file_id, best32.)), ".&source_file_ext.");
		file dummy filevar=output_file ;

		input;
		put _INFILE_ varying32767. reclen;

		records_written_in_current_file = records_written_in_current_file + 1;
	run;
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.> Split completato)
	
	%if &delete_source_file. %then %do;
		%let rc = %fsutil_delete_file(&file_to_split.);
	%end;

%mend util_split_text_file;
