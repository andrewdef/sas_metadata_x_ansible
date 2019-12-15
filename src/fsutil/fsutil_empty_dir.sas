/** 
* Deletes all contents of the directory specified as input parameter, by recursively traversing the directory
* and deleting each file. If something fails (eg a file cannot be deleted) an error is thrown and the macro
* stops, so the directory can end up being partially deleted. If the directory does not exist, an error is thrown.
*
* @param dir full path to the directory to be emptied
*/

%macro fsutil_empty_dir_cb(id=,type=, memname=, level=, parent=,context=,arg=);
    %local path_sep ret_value;
     %if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
        %let path_sep = %str(\);
    %end;
    %else %do;
        %let path_sep = %str(/);
    %end;

	%let ret_value = %fsutil_delete_file(%superq(context)&path_sep%superq(memname));

	%if &ret_value. ^= 0 %then %do;
		%put ERROR: <&SYSMACRONAME.> There was an error while deleting file %superq(context)&path_sep%superq(memname);
		%let SYSCC = 5;
		%let ret_value = 0;
	%end;
	%else
		%let ret_value = 1;
	
	%exit:
	&ret_value.
%mend fsutil_empty_dir_cb;

%macro fsutil_empty_dir(dir);
    %if %sysfunc(fileexist(%superq(dir))) %then %do;
       	%fsutil_dirtree_walk(%superq(dir), maxdepth=-1, callback=fsutil_empty_dir_cb);
    %end;
	
	%if &SYSCC. > 4 %then 
		%put ERROR: <&SYSMACRONAME.> Cannot empty directory %superq(dir);
%mend fsutil_empty_dir;
