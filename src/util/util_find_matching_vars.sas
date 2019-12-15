/** 
* Returns the list of variables of the input dataset whose name matches the regular 
* expression specified as matcher_regexp. The list returned is space separated.
*
* @param input_table input table
* @param matcher_regexp matcher regular expression
* @returns list of matching variables, space separated
*/

%macro util_find_matching_vars(input_table, matcher_regexp);
	%local ds_id rc ret_value regexp_id i var_name;

	%let regexp_id = %sysfunc(prxparse(&matcher_regexp.));

	%let ds_id = %sysfunc(open(&input_table.));
	%do i = 1 %to %sysfunc(attrn(&ds_id., nvars));
		%let var_name = %sysfunc(varname(&ds_id., &i.));

		%if %sysfunc(prxmatch(&regexp_id., &var_name.)) %then
			%let ret_value = &ret_value. &var_name.;
	%end;

	&ret_value.

	%let rc = %sysfunc(close(&ds_id.));
%mend util_find_matching_vars;