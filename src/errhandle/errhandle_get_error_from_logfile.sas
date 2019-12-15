/** 
* Returns an ERROR or WARNING message by parsing the SAS log file specified as input parameter. If
* no error is found, it returns either the content of the SYSERRORTEXT macro variable (if it exists)
* or the string "WARNING: cannot find error in SAS log".
*
* @param log_file full path to the log file to be parsed
* @param return_var name of the macro variable where the message is returned
* @param error_type type of message to search for, either WARNING or ERROR (default: ERROR)
* @param first_or_last specifies whether to return the FIRST or LAST error (default: FIRST)
*/

%macro errhandle_get_error_from_logfile(log_file, return_var, error_type=ERROR, first_or_last=FIRST);
	%local rc log_file_copy regexp;
	
	%if &error_type. = WARNING %then
		%let regexp = /^WARNING:.+/;
	%else
		%let regexp = /^ERROR(\s+\d+\-\d+)?\:.+/;

	%if not %sysfunc(fileexist(%superq(log_file))) %then
		%return;
	  
	%let log_file_copy = %fsutil_path_combine(%sysfunc(pathname(work)), %sysfunc(uuidgen()));  
	%let rc = %sysutil_copy_file(%superq(log_file), %superq(log_file_copy));
	%if &SYSCC. > 4 %then %return;

	%if %symexist(SYSERRORTEXT) %then
		%let &return_var. = %superq(SYSERRORTEXT);
	%else
		%let &return_var. = %nrbquote(WARNING: cannot find error in SAS log );
	data _null_;
		infile "&log_file_copy." lrecl=32767;
		length regexp_id found 8 error_message $ 32767;
		retain regexp_id found 0 error_message "";

		if _N_ = 1 then do;
			regexp_id = prxparse("&regexp.");
		end;

		input;

		if prxmatch(regexp_id, _INFILE_) then do;
			if error_message = "" then
				error_message = _INFILE_;
			else
				error_message = catx('\n', error_message, _INFILE_);
			found = 1;
		end;
		else if found then do;
			call symputx("&return_var.", error_message);
			found = 0;
			error_message = "";
			%if &first_or_last. = FIRST %then %do;
			stop;
			%end;
		end;      
	run;
	
	%let rc = %fsutil_delete_file(&log_file_copy.);

%mend errhandle_get_error_from_logfile;
