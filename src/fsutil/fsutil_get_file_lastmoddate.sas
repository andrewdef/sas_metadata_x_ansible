/** 
* Returns the last modification datetime for the file specified as input parameter, as a SAS datetime.
* If the file does not exist or is a directory, an error message is printed and SYSCC is set to 5.
* The macro uses system commands to get the last mod datetime, so xcmd as to be enabled. Also,
* if the command fails for whatever reason, again an error is thrown. In all failed cases,
* the timestamp returned is . (numeric missing).
*
* @param file full path to the file
* @returns file last modification datetime
*/

%macro fsutil_get_file_lastmoddate(file);
	%local rc_open_file rc fid last_mod_datetime date time path_sep;
	%let last_mod_datetime = .;
	
	%if not %sysfunc(fileexist(%superq(file))) %then %do;
		%put ERROR: <&SYSMACRONAME.> Cannot find file %superq(file);
		%let SYSCC = 5;
		%goto exit;
	%end;
	%else %if %fsutil_is_directory(%superq(file)) %then %do;
		%put ERROR: <&SYSMACRONAME.> File %superq(file) is a directory;
		%let SYSCC = 5;
		%goto exit;
	%end;

    %if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
        %let path_sep = %str(\);
    %end;
    %else %do;
        %let path_sep = %str(/);
    %end;

	%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do; /* Windows */
		%let rc = %sysutil_std_out(wmic datafile where name="%qsysfunc(tranwrd(%superq(file), &path_sep., &path_sep.&path_sep.))" get LastModified);
		%if not %index(%superq(rc), LastModified) %then %do;
			%put ERROR: <&SYSMACRONAME.> Cannot find last modification date for file %superq(file);
			%put ERROR: <&SYSMACRONAME.> Error was %superq(rc);
			%let SYSCC = 5;
		%end;
		%else %do;
			%let last_mod_datetime = %scan(%superq(rc), 2, |);
			%let last_mod_datetime = %sysfunc(inputn(%sysfunc(compress(&last_mod_datetime., .)), ND8601DZ.));
		%end;
	%end;
	%else %if %index(%upcase(&SYSSCP.), AIX) > 0 %then %do;
		%let rc = %sysutil_std_out(export LANG=C%nrstr(;) istat "%superq(file)" | grep "Last modified" 2>%nrstr(&1)); 
		%if "%superq(rc)" = "" or not %index(%superq(rc), Last modified) %then %do;
			%put ERROR: <&SYSMACRONAME.> Cannot find last modification date for file %superq(file);
			%put ERROR: <&SYSMACRONAME.> Error was %superq(rc);
			%let SYSCC = 5;
		%end;
		%else %do;
			%let last_mod_datetime = %sysfunc(tranwrd(%superq(rc), Last modified:, %str()));
			%let date = %sysfunc(compress(%scan(&last_mod_datetime., 3, %str( ))%scan(&last_mod_datetime., 2, %str( ))%scan(&last_mod_datetime., -1, %str( ))));
			%let time = %scan(&last_mod_datetime., 4 %str( ));
			%let last_mod_datetime = %sysfunc(inputn(&date.:&time., datetime18.));
		%end;
	%end;
	%else %do;
		/* stat -c %y <filename> is a Linux command that returns last mod datetime as Unix timestamp */
		%let rc = %sysutil_std_out(stat "%superq(file)" -c %nrstr(%Y) 2>%nrstr(&1)); 
		%if "%superq(rc)" = "" or %datatyp(%superq(rc)) ^= NUMERIC %then %do;
			%put ERROR: <&SYSMACRONAME.> Cannot find last modification date for file %superq(file);
			%put ERROR: <&SYSMACRONAME.> Error was %superq(rc);
			%let SYSCC = 5;
		%end;
		%else %do;
			%let last_mod_datetime = %sysfunc(intnx(DTyear, &rc., 10, s));
		%end;
	%end;
	
	%EXIT:
	&last_mod_datetime.
%mend fsutil_get_file_lastmoddate;
