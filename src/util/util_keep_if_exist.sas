/** 
* Returns the list of variables in the var_list parameter that exist in
* the input_table dataset; this list can be used in a keep option
*
* @param var_list list of variables to check
* @param list_separator separator char for var_list
* @param input_table member table for the variables
* @returns list of variables existing in input_table, space separated
*/

%macro util_keep_if_exist(var_list, list_separator, input_table);
	%local i ds_id rc num_var var ret_value;
	%let num_var = %sysfunc(countw(%superq(var_list), %superq(list_separator)));
	
	%let ds_id = %sysfunc(open(&input_table.));
	%if not &ds_id. %then %do;
		%errhandle_throw_exception(ICAAP_CANNOT_OPEN_DS, Impossibile aprire dataset &input_table. -> %sysfunc(sysmsg()));
		%return;
	%end;
	
	%do i = 1 %to &num_var.;
		%let var = %scan(%superq(var_list), &i., %superq(list_separator));
		
		%if %sysfunc(varnum(&ds_id., &var.)) ^= 0 %then
			%let ret_value = &ret_value. &var.;
	%end;
	
	%let rc = %sysfunc(close(&ds_id.));
	
	&ret_value.
	
%mend util_keep_if_exist;
