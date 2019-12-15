/** 
* Returns the type of the variable in the dataset specified as input parameter 
*
* @param var variable name
* @param input_table member table for the variable
* @returns type of the variable, C=character, N=numeric
*/

%macro util_get_vartype(var, input_table);
	%local ds_id rc ret_value;
	%let ds_id = %sysfunc(open(&input_table.));

	%let ret_value = %sysfunc(vartype(&ds_id., %sysfunc(varnum(&ds_id., &var.))));

	&ret_value.

	%let rc = %sysfunc(close(&ds_id.));
%mend util_get_vartype;
