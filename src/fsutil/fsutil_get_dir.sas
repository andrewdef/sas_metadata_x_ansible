/** 
* Extracts the directory path from the full path specified as argument.
* The directory name is assumed to be everything that preceeds the last separator (\ for Windows, / for Unix).
* If full path ends with the separator, the trailing separator is stripped and the previous to last separator is used
* to extract the directory path; instead, if fullpath has no separator, a blank string is returned. 
* No checks are made for path existance.
* Examples:
* %fsutil_get_filename_w_extension(C:\foo\boo.txt) returns C:\foo
* %fsutil_get_filename_w_extension(/etc/passwd/) returns /etc
* %fsutil_get_filename_w_extension(/log) returns blank
* %fsutil_get_filename_w_extension(foo.min.js) returns blank
*
* @param fullpath full path to the file
* @returns directory containing the file
*/

%macro fsutil_get_dir(fullpath);
	%local path_sep index ret_value fullpath_length;
	%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
        %let path_sep = %str(\);
    %end;
    %else %do;
        %let path_sep = %str(/);
    %end;
	
	%let fullpath_length = %length(%superq(fullpath));
	%if %qsubstr(%superq(fullpath), &fullpath_length., 1) = &path_sep. %then
		%let fullpath_length = %eval(&fullpath_length. - 1);
		
	%let index = %sysfunc(find(%superq(fullpath), &path_sep., -&fullpath_length.));
	%if &index. > 0 %then %do;
		%let ret_value = %qsubstr(%superq(fullpath), 1, &index.);
	%end;
	%else %do;
		%let ret_value =;
	%end;
	
	%superq(ret_value)

%mend fsutil_get_dir;
