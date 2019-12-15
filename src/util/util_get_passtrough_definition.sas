/** 
* Consente di definire le connessioni in passtrough.
*
* @param IN_ID identificativo del passtrough

*/

%macro util_get_passtrough_definition(IN_ID);
	%local dsid ENV_CK rc sh this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%let sh=%sysutil_get_envvar_if_exist(ENVIRONMENT,ENV_CK);	
	%if (sh eq 0) %then %do;
		%errhandle_throw_exception(CANNOT_FIND_ENVIRONMENT, <&this_macroname.> La variabile d%str(%')ambiente ENVIRONMENT non e%str(%') definita);
		%return;
	%end;

	%let dsid=%sysfunc(open(cfg_sced.data_source_definition,in));
	%syscall set(dsid);
	%do %while (%sysfunc(fetch(&dsid.)) eq 0);
		%if (&ID. eq &IN_ID. AND (&ENV_CK.=&ENVIRONMENT. or &ENVIRONMENT.=ALL)) %then %do;
			%if (&ENGINE. ne oracle) %then %do;
				datasrc=&DATA_SOURCE. user="%sysfunc(trim(&USER.))" password="%sysfunc(trim(&PSW.))"
			%end;
			%else %do;
				path=&DATA_SOURCE. user="%sysfunc(trim(&USER.))" password="%sysfunc(trim(&PSW.))"
			%end;

			%goto EXIT;
		%end;
	%end;

	%errhandle_throw_exception(CANNOT_FIND_ID_FOR_LIBNAME,<&this_macroname.> Non esiste alcuna configurazione per una passtrough con id: &IN_ID.);

	%EXIT: 
	%let rc=%sysfunc(close(&dsid.));
%mend util_get_passtrough_definition;
