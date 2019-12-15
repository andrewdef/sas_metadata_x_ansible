/** 
* Creates a directory, including intermediate directories that do not alredy
* exist. If the directory specified is the root directory (/, Unix systems)
* or a drive unit (eg C: in Windows systems) or the directory already exists,
* nothing is done. If the creation fails for some reason, the reason is printed
* as an ERROR in the log and SYSCC is set to 5. The directory can be specified
* with or without the trailing separator (eg C:\foo or C:\foo\)
*
* @param dir full path of the directory to be created
*/

%macro fsutil_mkdirs(dir);

	%local lastchar child parent;

	%*------------------------------------------------------------------;
	%* Examine the last character of the pathname.  If it is a colon,   ;
	%* then the path is an unadorned drive letter like c: or d:         ;
	%* Do nothing in that case - the drive is assumed to exists for now ;
	%*------------------------------------------------------------------;

	%let lastchar = %substr(&dir, %length(&dir));
	%if (%bquote(&lastchar) eq %str(:)) %then
	  %return;

	%*------------------------------------------------------------------;
	%* Check whether the last character is a path separator, either the ;
	%* Unix or Windows version                                          ;
	%*------------------------------------------------------------------;

	%if (%bquote(&lastchar) eq %str(/)) or
	   (%bquote(&lastchar) eq %str(\)) %then %do;

		%*---------------------------------------------------------------;
		%* If the whole path consists only of this path separator, then  ;
		%* the path implies the root directory of the current drive,     ;
		%* which is assumed to exist.  Nothing further needs to be done  ;
		%* with it.                                                      ;
		%*---------------------------------------------------------------;

		%if (%length(&dir) eq 1) %then
			%return;

		%*---------------------------------------------------------------;
		%* Otherwise, strip off the final path separator so that the     ;
		%* path looks like this:                                         ;
		%*                                                               ;
		%*       /something/parent/child                                 ;
		%*                                                               ;
		%* instead of this:                                              ;
		%*                                                               ;
		%*       /something/parent/child/                                ;
		%*---------------------------------------------------------------;

		%let dir = %substr(&dir, 1, %length(&dir)-1);

	%end;

   %*------------------------------------------------------------------;
   %* If the path already exists, there is nothing further to do       ;
   %*------------------------------------------------------------------;

   %if (%sysfunc(fileexist(%bquote(&dir))) = 0) %then %do;

		%*---------------------------------------------------------------;
		%* Get the child directory name as the token after the last path ;
		%* separator character (either Windows or unix) or colon         ;
		%*---------------------------------------------------------------;

		%let child = %scan(&dir, -1, %str(/\:));

		%*---------------------------------------------------------------;
		%* If the child directory name is the same as the whole path,    ;
		%* then there are no parent directories to create.  Otherwise,   ;
		%* extract the parent directory name and call this macro         ;
		%* recursively to create the parent directory. If it already     ;
		%* exists, the macro call will simply return.                    ;
		%*---------------------------------------------------------------;

		%if (%length(&dir) gt %length(&child)) %then %do;
			%let parent = %substr(&dir, 1, %length(&dir)-%length(&child));
			%fsutil_mkdirs(&parent);
		%end;

		%*---------------------------------------------------------------;
		%* Now create the child directory in the parent.  If the         ;
		%* directory is not created for some reason, exit with an        ;
		%* error message                                                 ;
		%*---------------------------------------------------------------;

		%let dname = %sysfunc(dcreate(&child, &parent));
		%if (%bquote(&dname) eq ) %then %do;
			%put ERROR: Cannot create directory &child in directory &parent;
			%put ERROR: Error was %qsysfunc(sysmsg());
			%let SYSCC = 5;
			
			%return;
		%end;
   %end;
%mend fsutil_mkdirs;
