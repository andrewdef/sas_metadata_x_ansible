/** 
* Returns the first value of the variable in the dataset specified as input parameter.
* If there is an error (eg, table does not exist, column does not exist) it throws an exception; 
* if instead no value can be found for the specified filter, it returns a missing
* value appropriate for the type of variable ( for alphanumeric and . for numeric ).
* If the column is alphanumeric, the returned value is quoted, unless the parameter quote_char_var
* is set to 0.
*
* @param input_table dataset to read
* @param input_column variable to read
* @param quote_char_var quote return value if the column is char, optional
* @returns value of the variable
*/

%macro util_get_value_from_table(input_table, input_column, quote_char_var=1);
	%local ret_value this_macroname dsid input_column_type rc index_of_bracket tab_name_orig varnum;
	%let this_macroname = &SYSMACRONAME.;
	%let dsid = 0;

	%let index_of_bracket = %index(%superq(input_table), %str(%());
	%if &index_of_bracket. %then %do;
		%let tab_name_orig = %substr(%superq(input_table), 1, %eval(&index_of_bracket.-1));
	%end;
	%else
		%let tab_name_orig = %superq(input_table);
	
	%let tab_name_orig = %upcase(&tab_name_orig.);
	%let input_column = %upcase(&input_column.);

	%if not %sysfunc(exist(&tab_name_orig.)) %then %do;
		%errhandle_throw_exception(CANNOT_FIND_DATASET, <&this_macroname.> Input table &tab_name_orig. does not exist);
		%goto finally;
	%end;
	%else %if not %util_has_column(&input_column., &tab_name_orig.) %then %do;
		%errhandle_throw_exception(CANNOT_OPEN_DATASET, <&this_macroname.> Input column &input_column. does not exist in input table &tab_name_orig.);
		%goto finally;
	%end;
	
	%let dsid = %sysfunc(open(&input_table.));
	%if &dsid. = 0 %then %do;
		%errhandle_throw_exception(CANNOT_OPEN_DATASET, <&this_macroname.> Input table &tab_name_orig. cannot be opened because:);
		%put ERROR: %qsysfunc(sysmsg());
		%goto finally;
	%end;

	%let varnum = %sysfunc(varnum(&dsid., &input_column.));
	%let input_column_type = %sysfunc(vartype(&dsid., &varnum.));
	
	%let rc = %sysfunc(fetch(&dsid.));
	%if &rc. ^= 0 %then %do;
		%if &quote_char_var. %then
			%let ret_value = %sysfunc(ifc(&input_column_type. = C, "", .));
		%else
			%let ret_value = %sysfunc(ifc(&input_column_type. = C, , .));
	%end;
	%else %if &input_column_type. = C %then %do;
		%if &quote_char_var. %then
			%let ret_value = "%qsysfunc(getvarc(&dsid., &varnum.))";
		%else
			%let ret_value = %qsysfunc(getvarc(&dsid., &varnum.));
	%end;
	%else
		%let ret_value = %sysfunc(getvarn(&dsid., &varnum.));
	
	%finally:
	%if &dsid. %then
		%let dsid = %sysfunc(close(&dsid.));
			
	&ret_value.
%mend util_get_value_from_table;
