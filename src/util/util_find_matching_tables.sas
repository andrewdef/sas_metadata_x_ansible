/** 
* Returns the list of tables in the input library whose name matches the regular 
* expression specified as matcher_regexp. The list returned is space separated.
*
* @param input_lib input library
* @param matcher_regexp matcher regular expression
* @returns list of matching variables, space separated
*/

%macro util_find_matching_tables(input_lib, matcher_regexp);
	%local ds_id rc ret_value regexp_id i table_name this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%let regexp_id = %sysfunc(prxparse(&matcher_regexp.));
	
	%let rc = %sysfunc(dosubl('proc contents data=&input_lib.._ALL_ out=cont noprint; run; %let subl_outcome=&SYSCC.;'));
	%if &rc. > 0 or &subl_outcome. > 4 %then %do;
		%errhandle_throw_exception(CANNOT_EXECUTE_CONTENTS, <&this_macroname.> Error during proc contents);
		%return;
	%end;
	
	%let rc = %sysfunc(dosubl('proc sql noprint; create table cont as select distinct MEMNAME from cont; quit; %let subl_outcome=&SQLRC.;'));
	%if &rc. > 0 or &subl_outcome. > 4 %then %do;
		%errhandle_throw_exception(CANNOT_EXECUTE_CONTENTS, <&this_macroname.> Error during proc contents);
		%return;
	%end;

	%let ds_id = %sysfunc(open(cont));
	%syscall set(ds_id);
	%do %while( %sysfunc(fetch(&ds_id.)) = 0 );
		%if %sysfunc(prxmatch(&regexp_id., &MEMNAME.)) %then
			%let ret_value = &ret_value. &MEMNAME.;
	%end;

	&ret_value.

	%let rc = %sysfunc(close(&ds_id.));
	%let rc = %sysfunc(dosubl('proc sql noprint; drop table cont; quit; %let subl_outcome=&SQLRC.;'));
	
%mend util_find_matching_tables;