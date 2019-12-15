%macro util_archive_obsolete_files(ds_config, reference_dt_sas);
	%local dsid this_macroname time_unit_regexp_id destination_dir action_only_name;
	%let this_macroname = &SYSMACRONAME.;
	
	%util_print_log(<&this_macroname.> Inizio archiviazione file obsoleti%str(,) data riferimento: %sysfunc(putn(&reference_dt_sas., date9.)));
	
	data __archive_obsolete_files_config(drop=DIRECTORY SUBDIRECTORY_FILTER RECURSION_DEPTH)
		 __directory_to_parse(keep=__DIRECTIVE_ID DIRECTORY SUBDIRECTORY_FILTER RECURSION_DEPTH);
		set &ds_config.(where=(VALID_FROM_DT < &reference_dt_sas. <= VALID_TO_DT));
		retain __DIRECTIVE_ID;
		
		if DIRECTORY ^= "" then do;
			__DIRECTIVE_ID = sum(__DIRECTIVE_ID, 1);
			output __directory_to_parse;
		end;
		
		IS_SQL_EXPRESSION = 0;
		if GET_FILE_REF_DATE_EXPRESSION =: 'SQL:' then do;
			IS_SQL_EXPRESSION = 1;
			
			GET_FILE_REF_DATE_EXPRESSION = substr(GET_FILE_REF_DATE_EXPRESSION, 5);
			index_of_from = index(upcase(GET_FILE_REF_DATE_EXPRESSION), 'FROM');
			GET_FILE_REF_DATE_EXPRESSION = catx(' ', substr(GET_FILE_REF_DATE_EXPRESSION, 1, index_of_from - 1), 'into :file_reference_dt', 
													substr(GET_FILE_REF_DATE_EXPRESSION, index_of_from));
		end;
		
		drop index_of_from;
		
		output __archive_obsolete_files_config;
	run;
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.> %util_attrn(__directory_to_parse, NOBS) directory da archiviare nella tabella &ds_config.);
	
	%let time_unit_regexp_id = %sysfunc(prxparse(/([0-9]+)\s*([a-zA-Z]+)/));
	
	%macro process_file(id=, type=, memname=, level=, parent=, context=, arg=);
		%local dsid directory_name file_name file_ext rc older_than_upper_treshold younger_than_lower_treshold date_diff time_units 
			   is_end_of_table oldness_lower_treshold_num oldness_upper_treshold_num i file_with_dir destination_zip;
		
		%if &type. ^= F %then %return;
		
		%let directory_name = %fsutil_get_filename(&context.);
		%let file_name = %fsutil_get_filename(&memname.);
		%let file_ext = %fsutil_get_file_extension(&memname.);
		%let file_with_dir = %fsutil_path_combine(&directory_name., &memname.);
		
		%let dsid = %sysfunc(open(__archive_obsolete_files_config(where=(__DIRECTIVE_ID = &__DIRECTIVE_ID. and prxmatch(FILENAME_FILTER, "&memname.")))));
		%syscall set(dsid);
		
		%if %sysfunc(attrn(&dsid., NLOBSF)) <= 0 %then %do;
			%util_print_log(<&this_macroname.> Nessuna regola configurata per file &file_with_dir.);
			%goto done;
		%end;
		
		%let is_end_of_table = %eval(%sysfunc(fetch(&dsid.)) ^= 0);
		
		%if &IS_SQL_EXPRESSION. %then %do;
			libname __lib__ "&context.";
			
			proc sql noprint;
			&GET_FILE_REF_DATE_EXPRESSION.;
			quit;
			%if &SQLRC. > 4 %then %goto done;
		%end;
		%else %do;
			%let file_reference_dt = &GET_FILE_REF_DATE_EXPRESSION.;
		%end;
		
		%if %datatyp(&file_reference_dt.) ^= NUMERIC %then %do;
			%errhandle_throw_exception(INVALID_REFERENCE_DATE, <&this_macroname.> Data di riferimento "&file_reference_dt." non valida per file &file_with_dir.);
			%goto done;
		%end;

		%util_print_log(<&this_macroname.> Data di riferimento per il file &file_with_dir.: %sysfunc(putn(&file_reference_dt., date9.)));
		
		%let i = 1;
		%do %while( not &is_end_of_table. );			
			%let older_than_upper_treshold = 1;
			%if &OLDNESS_UPPER_TRESHOLD. ^= %then %do;
				%let rc = %sysfunc(prxmatch(&time_unit_regexp_id., &OLDNESS_UPPER_TRESHOLD.));
				%let time_units = %sysfunc(prxposn(&time_unit_regexp_id., 2, &OLDNESS_UPPER_TRESHOLD.));
				%let oldness_upper_treshold_num = %sysfunc(prxposn(&time_unit_regexp_id., 1, &OLDNESS_UPPER_TRESHOLD.));
				
				%let date_diff = %sysfunc(intck(&time_units., &file_reference_dt.,  &reference_dt_sas.));
				%let older_than_upper_treshold = %eval(&date_diff. > &oldness_upper_treshold_num.);
			%end;
			
			%let younger_than_lower_treshold = 1;
			%if &OLDNESS_LOWER_TRESHOLD. ^= %then %do;
				%let rc = %sysfunc(prxmatch(&time_unit_regexp_id., &OLDNESS_LOWER_TRESHOLD.));
				%let time_units = %sysfunc(prxposn(&time_unit_regexp_id., 2, &OLDNESS_LOWER_TRESHOLD.));
				%let oldness_lower_treshold_num = %sysfunc(prxposn(&time_unit_regexp_id., 1, &OLDNESS_LOWER_TRESHOLD.));
				
				%let date_diff = %sysfunc(intck(&time_units., &file_reference_dt.,  &reference_dt_sas.));
				%let younger_than_lower_treshold = %eval(&date_diff. < &oldness_lower_treshold_num.);
			%end;			
			
			%util_print_log(<&this_macroname.> Valori di soglia regola &i. -> &=OLDNESS_LOWER_TRESHOLD. &=OLDNESS_UPPER_TRESHOLD.);
			
			%if &younger_than_lower_treshold. and &older_than_upper_treshold. %then %do;
				%util_print_log(<&this_macroname.> Eta del file compresa tra i valori di soglia%str(,) verra archiviato);
				%let action_only_name = %scan(%superq(ACTION), 1, {);
				%util_print_log(<&this_macroname.> Action: &action_only_name.);
				
				%if &action_only_name. = COMPRESS %then %do;
					%let destination_zip = %fsutil_path_combine(&context., &file_name..zip);
					%if %sysfunc(fileexist(&destination_zip.)) %then %do;
						%let rc = %fsutil_delete_file(&destination_zip.);
						%if &rc. ^= 0 %then %goto archive_error;
					%end;
					
					%sysutil_zip(%fsutil_path_combine(&context., &memname.), &destination_zip.);
					%if &SYSCC. > 4 %then %goto archive_error;
					
					%let rc = %fsutil_delete_file(%fsutil_path_combine(&context., &memname.));
				%end;
				%else %if &action_only_name. = DELETE %then %do;
					%let rc = %fsutil_delete_file(%fsutil_path_combine(&context., &memname.));
				%end;
				%else %if &action_only_name. = MOVE %then %do;
					%let destination_dir = %scan(%superq(ACTION), 2, {});
					
					%if not %sysfunc(fileexist(&destination_dir.)) %then %do;
						%fsutil_mkdirs(&destination_dir.);
						%if &SYSCC. > 4 %then %goto archive_error;
					%end;
					
					%sysutil_move(%fsutil_path_combine(&context., &memname.), %fsutil_path_combine(&destination_dir., &memname.))
					%if &SYSCC. > 4 %then %goto archive_error;
				%end;
				%else %if &action_only_name. = MOVE_AND_COMPRESS %then %do;
					%let destination_dir = %scan(%superq(ACTION), 2, {});
					
					%if not %sysfunc(fileexist(&destination_dir.)) %then %do;
						%fsutil_mkdirs(&destination_dir.);
						%if &SYSCC. > 4 %then %goto archive_error;
					%end;
					
					%sysutil_move(%fsutil_path_combine(&context., &memname.), %fsutil_path_combine(&destination_dir., &memname.))
					%if &SYSCC. > 4 %then %goto archive_error;
					
					%let destination_zip = %fsutil_path_combine(&destination_dir., &file_name..zip);
					%if %sysfunc(fileexist(&destination_zip.)) %then %do;
						%let rc = %fsutil_delete_file(&destination_zip.);
						%if &rc. ^= 0 %then %goto archive_error;
					%end;
					
					%sysutil_zip(%fsutil_path_combine(&destination_dir., &memname.), &destination_zip.);
					%if &SYSCC. > 4 %then %goto archive_error;
					
					%let rc = %fsutil_delete_file(%fsutil_path_combine(&destination_dir., &memname.));
				%end;
				
				%archive_error:
				%if &rc. ^= 0 %then %do;
					%errhandle_throw_exception(ARCHIVE_ERROR, <&this_macroname.> Errore durante l%str(%')archiviazione del file &file_with_dir.);
				%end;
				%else %do;				
					%util_print_log(<&this_macroname.> File archiviato correttamente);
				%end;
				
				%goto done;
			%end;
			%else %do;
				%util_print_log(<&this_macroname.> Il file non verra archiviato);
			%end;
			
			%let is_end_of_table = %eval(%sysfunc(fetch(&dsid.)) ^= 0);
			%let i = %eval(&i. + 1);
		%end;
		
		%done:
		%let dsid = %sysfunc(close(&dsid.));
	%mend process_file;
	
	%let dsid = %sysfunc(open(__directory_to_parse));
	%syscall set(dsid);
	
	%do %while( %sysfunc(fetch(&dsid.)) = 0 );
		%let DIRECTORY = %trim(&DIRECTORY.);
		
		%util_print_log(<&this_macroname.> Archivio directory &DIRECTORY.);
		
		%fsutil_dirtree_walk_nores(&DIRECTORY., dirname_regexp=&SUBDIRECTORY_FILTER., maxdepth=&RECURSION_DEPTH., callback=process_file);
		%if &SYSCC. > 4 or &SQLRC. > 4 %then %goto finally;
		
		%util_print_log(<&this_macroname.> Archiviazione directory completata);
	%end;
	
	%finally:
	%let dsid = %sysfunc(close(&dsid.));
	
	%util_print_log(<&this_macroname.> Archiviazione file obsoleti completata);
%mend util_archive_obsolete_files;