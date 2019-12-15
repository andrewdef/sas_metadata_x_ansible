/** 
* Returns 1 if the variable &var_name. exists in &input_table. dataset, 0 otherwise
*
* @param var variable name
* @param input_table member table for the variable
* @returns 1 if the variable &var_name. exists in &input_table. dataset, 0 otherwise
*/

%macro util_has_column(var_name, input_table);
	%local i ds_id rc ret_value;
	
	%let ds_id = %sysfunc(open(&input_table.));
	%if not &ds_id. %then %do;
		%errhandle_throw_exception(CANNOT_OPEN_DS, Impossibile aprire dataset &input_table. -> %sysfunc(sysmsg()));
		%return;
	%end;
	
	%let ret_value = %sysfunc(varnum(&ds_id., &var_name.));

	%let rc = %sysfunc(close(&ds_id.));
	
	&ret_value.
	
%mend util_has_column;
