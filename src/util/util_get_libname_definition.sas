/** 
* Consente di definire le librerie che utilizzano una connessione odbc.
*
* @param in_id libref associata alla libreria

*/

%macro util_get_libname_definition(in_id, data_source_config_table, environment_variable_name=AMBIENTE);
	%local dsid env_ck rc sh this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%let sh = %sysutil_get_envvar_if_exist(&environment_variable_name., env_ck);
	%if (sh eq 0) %then %do;
		%errhandle_throw_exception(CANNOT_FIND_ENVIRONMENT, <&this_macroname.> La variabile d%str(%')ambiente &environment_variable_name. non e%str(%') definita);
		%return;
	%end;

	%let dsid=%sysfunc(open(&data_source_config_table., in));
	%if not &dsid. %then %do;
		%errhandle_throw_exception(CANNOT_OPEN_CONFIG_TABLE, <&this_macroname.> Impossibile aprire tabella &data_source_config_table. -> %qsysfunc(sysmsg()));
		%return;
	%end;
	
	%syscall set(dsid);
	%do %while (%sysfunc(fetch(&dsid.)) eq 0);
		%if (&ID. eq &in_id. and (&env_ck.=&ENVIRONMENT. or &ENVIRONMENT.=ALL)) %then %do;
			%if (&ENGINE. = base) %then %do;
				&ENGINE. "&DATA_SOURCE." &OPTIONS.;
			%end;
			%else %if (&ENGINE. ^= oracle) %then %do;
				&ENGINE. datasrc=&DATA_SOURCE. user="%sysfunc(trim(&USER.))" password="%sysfunc(trim(&PSW.))" schema=&SCHEMA. &OPTIONS.;
			%end;
			%else %do;
				&ENGINE. path=&DATA_SOURCE. user="%sysfunc(trim(&USER.))" password="%sysfunc(trim(&PSW.))" schema=&SCHEMA. &OPTIONS.;
			%end;

			%goto EXIT;
		%end;
	%end;

	%errhandle_throw_exception(CANNOT_FIND_ID_FOR_LIBNAME,<&this_macroname.> Non esiste alcuna configurazione per una libname con id: &in_id.);

	%EXIT: 
	%let rc=%sysfunc(close(&dsid.));
%mend util_get_libname_definition;
