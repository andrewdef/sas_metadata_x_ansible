/** 
* Deletes the file or directory specified as input parameter. If it is a directory, it must be empty to be deleted,
* otherwise the macro fails. If delete operation fails (eg. the file does not exist) an error is written 
* to the SAS log and SYSCC is set to 5. The macro also returns 0 if the operation is successful, ^= 0 otherwise.
*
* @param filename full path to the directory or file to be deleted
* @returns 0 if delete operation is successful, ^= 0 otherwise
*/

%macro fsutil_delete_file(filename);
    %local rc _T;
    %let rc=9999;

    %let rc = %sysfunc(filename(_T, %superq(filename)));
    %let rc = %sysfunc(fdelete(&_T.)); 

	%if &rc. ^= 0 %then %do;
		%put ERROR: <&SYSMACRONAME.> There was an error while deleting file %superq(filename);
		%put ERROR: <&SYSMACRONAME.> Error was: %qsysfunc(sysmsg());
	%end;
	
	&rc.

    %let rc = %sysfunc(filename(_T));           
%mend fsutil_delete_file;