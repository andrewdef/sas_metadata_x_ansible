/** 
* Checks whether the path specified as input parameter is a directory or not.
*
* @param path full path of the file/directory to be checked
* @returns 1 if path is a directory, 0 if it is not
*/

%macro fsutil_is_directory(path);
	%local rc did is_directory fref_t;
	
	%let is_directory = 0;
	%let rc = %sysfunc(filename(fref_t, %superq(path)));
	%let did = %sysfunc(dopen(&fref_t.));
	%if &did. ^= 0 %then %do;
	   %let is_directory = 1;
	   %let rc = %sysfunc(dclose(&did.));
	%end;
	%let rc = %sysfunc(filename(fref_t));
	
	&is_directory.
%mend fsutil_is_directory;
