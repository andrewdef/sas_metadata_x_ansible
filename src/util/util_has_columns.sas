/** 
* Returns the list of variables in the var_list parameter that do not exist in
* the input_table dataset
*
* @param var_list list of variables to check, space separated
* @param input_table member table for the variables
* @returns list of variables absent from input_table, space separated
*/

%macro util_has_columns(var_list, input_table);
	%local i var rc ret_value;
	
	%do i = 1 %to %sysfunc(countw(&var_list.));
		%let var = %scan(&var_list., &i., %str( ));
		
		%let rc = %util_has_column(&var., &input_table.);
		%if &SYSCC. > 4 %then %return;
		
		%if &rc. = 0 %then
			%let ret_value = &ret_value. &var.;
	%end;
	
	&ret_value.
	
%mend util_has_columns;
