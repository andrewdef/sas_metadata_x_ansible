/** 
* Loads the options from the input table specied, in the form of macro variables
*
* @param options_table options table

*/ 

%macro util_init_options(options_table, environment_variable_name=AMBIENTE) ;

	%util_print_log(Start loading options from table &options_table.);
	
	%local environment index_of_bracket options_table_wo_conditions;
	
	%let index_of_bracket = %index(%superq(options_table), %str(%());
	%if &index_of_bracket. %then
		%let options_table_wo_conditions = %substr(%superq(options_table), 1, %eval(&index_of_bracket.-1));
	%else
		%let options_table_wo_conditions = &options_table.;
		
	%if not %sysfunc(exist(&options_table_wo_conditions.)) %then %do;
		%errhandle_throw_exception(ICAAP_OPT_TAB_NO_FOUND_EXCEPTION, Cannot find configuration table &options_table_wo_conditions.);
		%return;
	%end;

    data _null_ ;
        set &options_table;
		
		%if %sysutil_get_envvar_if_exist(&environment_variable_name., environment) and %util_has_column(ENVIRONMENT, &options_table_wo_conditions.) %then %do;
			%util_print_log(Filter table by ENVIRONMENT = &environment.);
			where upcase(ENVIRONMENT) in ("ALL", "%upcase(&environment.)");
		%end;
		
		if not symglobl(CONFIG_NAME) or CONFIG_NAME =: '__' then
			call symputx(CONFIG_NAME, CONFIG_VALUE, 'G');
    run;
	
	%util_print_log(Loading options completed);

%mend util_init_options ;