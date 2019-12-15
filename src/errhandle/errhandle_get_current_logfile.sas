/** 
* Tries to found the current log file used by the SAS session, by scanning the ALTLOG and LOG system option, some commonly used
* environment variables, or examining the vextfl view if all else fails. If used in an interactive session (in the Enanched Editor, for example)
* it dumps the log in a temporary file in the work library. If a log file is not found, it returns an empty string, but does not raise an exception.
*
* @param return_var name of the macro variable where the full path to the log file is returned.
*/

%macro errhandle_get_current_logfile(return_var);
	%put <&SYSMACRONAME.> Beginning detection of log file;

	%local logfile begin_write path_sep;
	%if %qsysfunc(getoption(LOG)) ^= %then %do;
		%let logfile = %qsysfunc(getoption(LOG));
		%put <&SYSMACRONAME.> Log definition found in LOG option;
	%end;
	%else %if %qsysfunc(getoption(ALTLOG)) ^= %then %do;
		%let logfile = %qsysfunc(getoption(ALTLOG));
		%put <&SYSMACRONAME.> Log definition found in ALTLOG option;
	%end;
	%else %if %qsysfunc(getoption(ALTLOG)) ^= %then %do;
		%let logfile = %qsysfunc(getoption(ALTLOG));
		%put <&SYSMACRONAME.> Log definition found in ALTLOG option;
	%end;
	%else %if %sysutil_get_envvar_if_exist(LOGFILENAME, logfile) %then %do;
		%put <&SYSMACRONAME.> Log definition found in LOGFILENAME envvar;
	%end;
	%else %do;
		%put <&SYSMACRONAME.> Cannot find log in options or envvar%str(,) attempting to guess it from extfile table;

		%let begin_write = %sysfunc(datetime());
		%put <&SYSMACRONAME.> Time before writing is %sysfunc(putn(&begin_write., datetime20.)) (&begin_write);
		data _null_;
			putlog "errhandle_get_current_logfile";
		run;

		proc sql noprint;
			create table all_ext_files as
			select distinct XPATH 
			from sashelp.vextfl
			where fileexist(XPATH);
		quit;

		data all_ext_files;
			set all_ext_files;

			is_directory = input(resolve('%fsutil_is_directory(' || trim(XPATH) || ')'), 1.);
			if not is_directory then do;
				last_modified = input(resolve('%fsutil_get_file_lastmoddate(' || trim(XPATH) || ')'), best32.);

				if &begin_write.  < last_modified then do;
					call symputx('logfile', XPATH);
					stop;
				end;
			end;
		run;

		%if %superq(logfile) ^= %then
			%put <&SYSMACRONAME.> Found logfile from external files table;
		%else
			%put <&SYSMACRONAME.> Cannot find an external file with lastmoddate > &begin_write.;
	%end;

	%if %superq(logfile) = and %index(%superq(SYSPROCESSNAME),  DMS Process) %then %do;
		%put <&SYSMACRONAME.> Interactive environment detected%str(,) dumping the window log to an external file;

		%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
			%let path_sep = %str(\);
		%end;
		%else %do;
			%let path_sep = %str(/);
		%end;
	
		%let logfile = %sysfunc(pathname(work))&path_sep.%sysfunc(uuidgen()).log;
		dm log 'file "&logfile."';
		%put <&SYSMACRONAME.> Log has been dumped to &logfile.;
	%end;
	
	%let &return_var. = %superq(logfile);

	%if %superq(logfile) ^= %then
		%put <&SYSMACRONAME.> Log file found is %superq(logfile);
	%else
		%put <&SYSMACRONAME.> Cannot find a path for log file;

%mend errhandle_get_current_logfile;
