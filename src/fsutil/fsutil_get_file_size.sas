/** 
* Returns the size in bytes for the file specified as input parameter. If the file
* does not exist or is a directory, an error message is printed and SYSCC is set to 5.
* The macro uses system commands to get the file size, so xcmd as to be enabled. Also,
* if the command fails for whatever reason, again an error is thrown. In all failed cases,
* the size returned is . (numeric missing).
*
* @param file full path to the file
* @returns file size in bytes
*/

%macro fsutil_get_file_size(file);
	%local rc_open_file fid rc size;
	%let size = .;

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
		%let rc = %sysutil_std_out(wmic datafile where name="%qsysfunc(tranwrd(%superq(file), &path_sep., &path_sep.&path_sep.))" get FileSize);
		%if not %index(%superq(rc), FileSize) %then %do;
			%put ERROR: <&SYSMACRONAME.> Cannot find size for file %superq(file);
			%put ERROR: <&SYSMACRONAME.> Error was %superq(rc);
			%let SYSCC = 5;
		%end;
		%else %do;
			%let size = %scan(%superq(rc), 2, |);
		%end;
	%end;
	%else %do;
		%let rc = %sysutil_std_out(ls -l "%superq(file)"); 
		%if "&rc." = "" %then %do;
			%put ERROR: <&SYSMACRONAME.> Cannot find size for file %superq(file);
			%put ERROR: <&SYSMACRONAME.> Error was %superq(rc);
			%let SYSCC = 5;
		%end;
		%else %do;
			%let size = %scan(&rc., 5, %str( ));
		%end;
	%end;
	
	%EXIT:
	&size.
%mend fsutil_get_file_size;
