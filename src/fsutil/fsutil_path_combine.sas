/** 
* Concatenetes the subpaths specified as arguments in a single path, using the system appropriate
* path separator (eg. \ in Windows systems, / in Unix systems). If the subpaths end with the separator,
* it will be stripped before concatenating, to avoid ending up with multiple separators.
* Examples:
* %fsutil_path_combine(foo, boo) will return foo/boo on Unix and foo\boo on Windows
* %fsutil_path_combine(/foo, boo/, moo.txt) will return /foo/boo/moo.txt on Unix
*
* @param subpaths subpaths to concatenate, variable arguments
*/

%macro fsutil_path_combine /PARMBUFF;
	%if %superq(SYSPBUFF) ^= %then %do;
		%let SYSPBUFF = %qsubstr(%superq(SYSPBUFF), 2, %eval(%length(%superq(SYSPBUFF))-2));
	%end;
	
	%local path_sep ret_var sub_path sub_path_length i;
	%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
        %let path_sep = %str(\);
    %end;
    %else %do;
        %let path_sep = %str(/);
    %end;
	
	%let i = 1;
	%do %while (1);
		%let sub_path = %qtrim(%qleft(%qscan(%superq(SYSPBUFF), &i., %nrstr(,))));
		%let sub_path_length = %length(%superq(sub_path));
		%if &sub_path_length. = 0 %then %goto break;

		%if %qsubstr(%superq(sub_path), &sub_path_length.) = %superq(path_sep) %then
			%let sub_path = %qsubstr(%superq(sub_path), 1, %eval(&sub_path_length. - 1));
			
		%if &i. = 1 %then
			%let ret_var = %superq(sub_path);
		%else
			%let ret_var = %superq(ret_var)&path_sep.%superq(sub_path);
			
		%let i = %eval(&i. + 1);
	%end;
	%break:
	
	%superq(ret_var)

%mend fsutil_path_combine;
