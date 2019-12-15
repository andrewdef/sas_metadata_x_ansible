/** 
* Lookups values from lookup_table dataset using key_variables as keys. The macro uses an hash to perform the lookup efficiently; also, it can be used
* inside a datastep, so in can be called multiple times with differente lookup tables or even the same one with different keys/filter, to maximize performances.
* The lookup performed is similar to a left join, with the difference that if there are multiple lookup values for the same key, a random one (and only one) 
* is selected, so the input table will always have the same number of records as the output table.
* If the keys have differente names between input and lookup dataset, they can be specified in the format name_in_input:name_in_lookup; multiple keys can be specified
* using space as separator. Also, if lookup variables should have different names in the output dataset, they can be specified in the format name_in_lookup:name_in_output
* Dataset options can be used in the specification of in_table and lookup_table, with the limitation that keep, drop and rename cannot be used for the lookup dataset 
* (and they should never be necessary).
* By default, the name of the hash object is the same as the name of the lookup table. If the macro is called multiple times in the same datastep with the same
* lookup table, a different, unique name should be specified in the hash_name parameter to avoid an error.
*
* @param in_table input dataset, if is_in_datastep is 1 this parameter is not used
* @param lookup_table lookup dataset
* @param key_variables list of key variables, space separated
* @param lookup_variables list of data variables, space separated
* @param out_table output dataset, if is_in_datastep is 1 this parameter is not used, if blank the same value of in_table is used
* @param is_in_datastep specifies whether the macro is being called inside a datastep or by itself
* @param hash_name name of the hash object used for the lookup, default is the name of the lookup table
*
*/

%macro util_quick_lookup(in_table, lookup_table, key_variables, lookup_variables, out_table=, is_in_datastep=0, hash_name=);
	%local this_macroname index_of_bracket tab_name_orig tab_name_without_lib table_options i source_var dest_var rename_statement keep_statement key_vars data_vars 
		   renamed_vars new_names_for_renamed_vars find_statement index_of_renamed_var vars_to_drop in_table_has_key_var unique_id;
	%let this_macroname = &SYSMACRONAME.;
	
	%let unique_id = %util_get_unique_id(&this_macroname.);
	
	%let index_of_bracket = %index(%superq(lookup_table), %str(%());
	%if &index_of_bracket. %then %do;
		%let tab_name_orig = %substr(%superq(lookup_table), 1, %eval(&index_of_bracket.-1));
		%let table_options = %substr(%superq(lookup_table), %eval(&index_of_bracket.+1), %eval(%length(%superq(lookup_table))) - &index_of_bracket. - 1);
	%end;
	%else
		%let tab_name_orig = %superq(lookup_table);
	
	%let tab_name_without_lib = %scan(&tab_name_orig., -1, .);
	%if "&hash_name." = "" %then %do;
		%let hash_name=_quick_lookup_&unique_id.;
	%end;

	%if %superq(out_table) = %then
		%let out_table = &in_table.;

	%let vars_to_drop = rc;

	%do i = 1 %to %sysfunc(countw(&lookup_variables., %str( )));
		%let source_var = %scan(%scan(&lookup_variables., &i., %str( )), 1, :);
		%let dest_var = %scan(%scan(&lookup_variables., &i., %str( )), 2, :);

		%let keep_statement = &keep_statement. &source_var.;
					
		%if &dest_var. ^= %then %do;
			%let data_vars = &data_vars. &dest_var.;
			%let rename_statement = &rename_statement. &source_var.=&dest_var.;
			%let renamed_vars = &renamed_vars. &source_var.;
			%let new_names_for_renamed_vars = &new_names_for_renamed_vars. &dest_var.;
		%end;
		%else %do;
			%let data_vars = &data_vars. &source_var.;
		%end;		
	%end;

	%do i = 1 %to %sysfunc(countw(&key_variables., %str( )));
		%let source_var = %scan(%scan(&key_variables., &i., %str( )), 1, :);
		%let dest_var = %scan(%scan(&key_variables., &i., %str( )), 2, :);

		%let find_statement = &find_statement. key:&source_var.;
		
		%if &dest_var. = %then
			%let dest_var = &source_var.;	
		
		%let index_of_renamed_var = %sysfunc(whichc(&dest_var., %listutil_tranlist_for_in_oper(&renamed_vars., NUM, %str( ))));
		
		/* If key variable has been renamed in the lookup variables */
		%if &index_of_renamed_var. %then %do;
			%let key_vars = &key_vars. %sysfunc(choosec(&index_of_renamed_var., %listutil_tranlist_for_in_oper(&new_names_for_renamed_vars., NUM, %str( ))));
		%end;
		%else %do;
			%let key_vars = &key_vars. &dest_var.;

			/* If key var in the source is not the same in the lookup, add to the keep_statement and drop afterwards, unless the var already
			   exists in the source table*/
			%if &source_var. ^= &dest_var. %then %do;
				%let keep_statement = &keep_statement. &dest_var.;
				
				%if %superq(in_table) ^= %then
					%let in_table_has_key_var = %util_has_column(&dest_var., &in_table.);
				%else
					%let in_table_has_key_var = 0;
					
				%if not &in_table_has_key_var. %then
					%let vars_to_drop = &vars_to_drop. &dest_var.;
			%end;
		%end;		
	%end;

	%if %superq(rename_statement) ^= %then 
		%let rename_statement = rename=(&rename_statement.);

	%if not &is_in_datastep. %then %do;
	data &out_table.;
		set &in_table.;
	%end;
	
		if 0 then set &tab_name_orig.(keep=&keep_statement. &rename_statement.);

		if not is_init_&unique_id. then do;
			declare hash &hash_name.(dataset: "&tab_name_orig.( &rename_statement. &table_options.)");
			&hash_name..defineKey(%listutil_tranlist_for_in_oper(&key_vars., STRING, %str( )));
			&hash_name..defineData(%listutil_tranlist_for_in_oper(&data_vars., STRING, %str( )));
			&hash_name..defineDone();
			
			retain is_init_&unique_id.;
			is_init_&unique_id. = 1;
		end;
					
		call missing(%listutil_tranlist_for_in_oper(&data_vars., NUM, %str( )));
		
		rc = &hash_name..find(%listutil_tranlist_for_in_oper(&find_statement., NUM, %str( )));
		
		drop &vars_to_drop. is_init_&unique_id.;
		
	%if not &is_in_datastep. %then %do;
	run;
	%end;
%mend util_quick_lookup;