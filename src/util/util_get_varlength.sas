/** 
* Returns the length of the variable in the dataset specified as input parameter 
*
* @param var variable name
* @param input_table member table for the variable
* @returns length of the variable in bytes
*/
	
%macro util_get_varlength(var, input_table);
	%local ds_id rc ret_value;
	%let ds_id = %sysfunc(open(&input_table.));

	%let ret_value = %sysfunc(varlen(&ds_id., %sysfunc(varnum(&ds_id., &var.))));

	&ret_value.

	%let rc = %sysfunc(close(&ds_id.));
%mend util_get_varlength;
