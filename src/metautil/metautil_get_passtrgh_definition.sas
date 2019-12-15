%macro filter_dbinfo;
	data filtered_db_info;
		set db_info;
		
		%if &filter_by_env. %then %do;
		where upcase(scan(LIB_NAME, -1, '_')) = "%sysget(AMBIENTE)";
		%end;
		
		PROPERTY_NAME = upcase(PROPERTY_NAME);
		
		do i = 1 to countw(sas_application_servers, '#');
			if scan(sas_application_servers, i, '#') = "&app_server." then do;
				output;
				leave;
			end;
		end;
	run;
%mend filter_dbinfo;
	
%macro metautil_get_passtrgh_definition(input_lib, app_server=);
	%local this_macroname rc found_library_info db_authdomain db_engine db_path db_schema db_datasrc db_dbname db_server;
	%let this_macroname = &SYSMACRONAME.;
	
	%if %superq(app_server) = %then %do;
		%if %symexist(_SASSERVERNAME) %then
			%let app_server = %sysfunc(tranwrd(&_SASSERVERNAME., %str(%'), %str()));
		%else
			%let app_server = SASApp;
	%end;
	
	%let rc = %sysfunc(dosubl('%metautil_get_library_info(&input_lib., db_info)'));
	%if &SYSCC. > 4 %then %return;
	
	%let found_library_info = %eval(%util_get_nobs(db_info) > 0);
	%if not &found_library_info. %then %do;
		%util_print_log(<&this_macroname.> Cannot find connection information to &input_lib. from metadata)
	%end;
	%else %do;
		%let db_engine = %sysfunc(tranwrd(%util_get_value_from_table(db_info, LIB_ENGINE), %str(%"), %str()));
		
		%util_print_log(<&this_macroname.> Engine libreria &input_lib. -> &db_engine.)
		
		%local filter_by_env;
		%let filter_by_env = %eval("%sysget(AMBIENTE)" ^= "" and %util_get_nobs(db_info(where=(upcase(scan(LIB_NAME, -1, '_')) = "%sysget(AMBIENTE)")) > 0));
		
		%let rc = %sysfunc(dosubl('%filter_dbinfo'));
		%if &SYSCC. > 4 %then %return;
		
		%if %util_get_nobs(filtered_db_info) = 0 %then %do;
			%util_print_log(<&this_macroname.> Cannot find a definition for library &input_lib. and Application Server &app_server.)
			%return;
		%end;
		
		%let db_schema = %util_get_value_from_table(filtered_db_info(where=(PROPERTY_NAME = 'SCHEMANAME')), PROPERTY_VALUE);
		%let db_datasrc = %util_get_value_from_table(filtered_db_info(where=(PROPERTY_NAME = 'DATASRC')), PROPERTY_VALUE);
		%let db_path = %util_get_value_from_table(filtered_db_info(where=(PROPERTY_NAME = 'PATH')), PROPERTY_VALUE);
		%let db_authdomain = %util_get_value_from_table(filtered_db_info(where=(PROPERTY_NAME = 'AUTHENTICATIONDOMAIN')), PROPERTY_VALUE);
		%let db_server = %util_get_value_from_table(filtered_db_info(where=(PROPERTY_NAME = 'SERVER')), PROPERTY_VALUE);
		%let db_dbname = %util_get_value_from_table(filtered_db_info(where=(PROPERTY_NAME = 'DATABASE')), PROPERTY_VALUE);
		
		%let db_schema =  %sysfunc(tranwrd(&db_schema., %str(%"), %str()));
		%let db_authdomain =  %trim(%sysfunc(tranwrd(&db_authdomain., %str(%"), %str())));
		%let db_datasrc =  %trim(%sysfunc(tranwrd(&db_datasrc., %str(%"), %str())));
		%let db_server =  %trim(%sysfunc(tranwrd(&db_server., %str(%"), %str())));
		%let db_dbname =  %trim(%sysfunc(tranwrd(&db_dbname., %str(%"), %str())));
		
		%if (&db_engine. eq NETEZZA) %then %do;
			&db_engine.:server="&db_server." database=&db_dbname. authdomain="&db_authdomain.":&db_schema.
		%end;
		%else  %if (&db_engine. ne ORACLE) %then %do;
			&db_engine.:datasrc="&db_datasrc." authdomain="&db_authdomain.":&db_schema.
		%end;
		%else %do;
			&db_engine.:path="&db_path." authdomain="&db_authdomain.":&db_schema.
		%end;
	%end;
	
%mend metautil_get_passtrgh_definition;