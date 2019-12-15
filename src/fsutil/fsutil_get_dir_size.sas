/** 
* Returns the size in bytes for the directory specified as input parameter by recursively
* traversing the directory and adding up the sizes of all files containd therein. If the directory
* is not a directory, an error message is printed and SYSCC is set to 5. If the directory does not exist,
* the size returned is . (numeric missing), but an exception is NOT thrown.
* The macro uses system commands to get the file size, so xcmd as to be enabled. Also,
* if the command fails for whatever reason, again an error is thrown. In all failed cases,
* the size returned is . (numeric missing).
*
* @param file full path to the file
* @returns file size in bytes
*/

%macro fsutil_get_dir_size_cb(id=,type=, memname=, level=, parent=,context=,arg=);
	%if &type. = F %then %do;
		%let &ret_var. = %sysfunc(sum(&&&ret_var.., %fsutil_get_file_size(&context.&path_sep.&memname.)));
	%end;
%mend fsutil_get_dir_size_cb;

%macro fsutil_get_dir_size(dir, ret_var);
	%local path_sep;
	%let &ret_var. = .;

	%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
        %let path_sep = %str(\);
    %end;
    %else %do;
        %let path_sep = %str(/);
    %end;
	
    %if %sysfunc(fileexist(&dir.)) %then %do;
       %fsutil_dirtree_walk(&dir, maxdepth=-1, callback=fsutil_get_dir_size_cb)
    %end;

%mend fsutil_get_dir_size;
