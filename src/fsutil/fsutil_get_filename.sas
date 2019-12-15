/** 
* Extracts the file name without extension from the full path specified as argument.
* The file name is assumed to be the token after the last path separator (\ for Windows, / for Unix), while
* the extension to be stripped is everything that follows the first dot (.) in the filename.
* If full path ends with the separator, a blank string is returned; instead, if fullpath has no separator,
* the entire fullpath string is returned. No checks are made for file existance or if the token returned
* is really a file.
* Examples:
* %fsutil_get_filename_w_extension(C:\foo\boo.txt) returns boo
* %fsutil_get_filename_w_extension(/etc/passwd) returns passwd
* %fsutil_get_filename_w_extension(/var/log/) returns blank
* %fsutil_get_filename_w_extension(/home/ad/foo.min.js) returns foo
*
* @param fullpath full path to the file
* @returns file name without extension
*/

%macro fsutil_get_filename(fullpath);
	%local path_sep index ret_value;
	%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
        %let path_sep = %str(\);
    %end;
    %else %do;
        %let path_sep = %str(/);
    %end;
	
	%let index = %sysfunc(find(%superq(fullpath), &path_sep., -32767));
	%if &index. > 0 %then %do;
		%let ret_value = %qsubstr(%superq(fullpath), %eval(&index.+1));
		%let ret_value = %qscan(%superq(ret_value), 1, .);
	%end;
	%else %do;
		%let ret_value = %qscan(%superq(fullpath), 1, .);
	%end;
	
	%superq(ret_value)

%mend fsutil_get_filename;