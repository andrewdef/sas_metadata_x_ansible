/** 
* Extracts the file extension from the full path specified as argument.
* The extension is assumed to bene everything that follows the last dot (.) in the filename.
* If full path ends with the separator or the filename has no ., a blank string is returned
* Examples:
* %fsutil_get_filename_w_extension(C:\foo\boo.txt) returns txt
* %fsutil_get_filename_w_extension(/etc/passwd) returns blank
* %fsutil_get_filename_w_extension(/var/log/) returns blank
* %fsutil_get_filename_w_extension(/home/ad/foo.min.js) returns js
*
* @param fullpath full path to the file
* @returns file extension
*/

%macro fsutil_get_file_extension(fullpath);
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
		%let ret_value = %qscan(%superq(ret_value), -1, .);
	%end;
	%else %do;
		%let ret_value = %qscan(%superq(fullpath), -1, .);
	%end;
	
	%superq(ret_value)

%mend fsutil_get_file_extension;