/** 
* Returns the relative path of &source. in respect to the root path &relative_to. For example, if
* source is /var/log/httpd and relative_to is /var, the macro will return log/httpd. If source has
* less depth than relative_to or source and relative_to do not have a common root, the entire value
* of source is returned. The path separator used is the system separator (\ for Windows, / for Unix).
* Both path can also be relative, as long as they have a common root (eg. foo/boo/moo and foo/boo)
*
* @param source source path
* @param relative_to root path
* @returns the relative path of source against relative_to
*/

%macro fsutil_get_relative_path(source, relative_to);
	%local path_sep compare_opt ret_value num_tokens_source num_tokens_dest token_source token_dest i j;
	%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
        %let path_sep = %str(\);
		%let compare_opt = ,i;
    %end;
    %else %do;
        %let path_sep = %str(/);
		%let compare_opt =;
    %end;
	
	%let num_tokens_source = %sysfunc(countw(%superq(source), &path_sep.));
	%let num_tokens_dest = %sysfunc(countw(%superq(relative_to), &path_sep.));
	
	%if &num_tokens_source. < &num_tokens_dest. %then %do;
		%let ret_value = %superq(source);
		%goto exit;
	%end;
	
	%do i = 1 %to &num_tokens_source.;
		%let token_source = %qscan(%superq(source), &i., &path_sep.);
		%let token_dest = %qscan(%superq(relative_to), &i., &path_sep.);
		
		%if %sysfunc(compare(%superq(token_source), %superq(token_dest) &compare_opt.)) ^= 0 %then
			%goto build_return_value;
	%end;
	
	%build_return_value:
	%if &i. = 1 %then %do;
		%let ret_value = %superq(source);
		%goto exit;
	%end;
	
	%do j = &i. %to &num_tokens_source.;
		%let token_source = %qscan(%superq(source), &j., &path_sep.);
		%if &j. = &i. %then
			%let ret_value = %superq(token_source);
		%else
			%let ret_value = %superq(ret_value)&path_sep.%superq(token_source);
	%end;
	
	%exit:
	&ret_value.
%mend fsutil_get_relative_path;
