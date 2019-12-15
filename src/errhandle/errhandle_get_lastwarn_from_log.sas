/** 
* Returns the last WARNING message by parsing the SAS log file specified as input parameter. If
* no error is found, it returns either the content of the SYSERRORTEXT macro variable (if it exists)
* or the string "WARNING: cannot find error in SAS log". If the log file is not specified, the current log file
* is used.
*
* @param return_var name of the macro variable where the message is returned
* @param log_file full path to the log file to be parsed (default: blank)
*/

%macro errhandle_get_lastwarn_from_log(return_var, log_file=);
	%if %superq(log_file) = %then
		%errhandle_get_current_logfile(log_file);
		
	%errhandle_get_error_from_logfile(%superq(log_file), &return_var., error_type=WARNING, first_or_last=LAST);

%mend errhandle_get_lastwarn_from_log;
