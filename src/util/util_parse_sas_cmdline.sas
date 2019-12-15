%macro util_parse_sas_cmdline;
	%local argument_separator num_params param param_name param_value i;
	
	%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
		options noxwait noxsync;
		%let argument_separator = |;
	%end;
	%else %do;
		%let argument_separator = !;
	%end;
	
	%let num_params = %listutil_get_list_size(%superq(SYSPARM), list_separator=&argument_separator.);
	%do i = 1 %to &num_params.;
		%let param = %scan(%superq(SYSPARM), &i., &argument_separator.);

		%let param_name = %scan(&param., 1, %str(=));
		%let param_value = %scan(&param., 2, %str(=));
		
		%global &param_name.;
		%let &param_name. = &param_value.;
	%end;

%mend util_parse_sas_cmdline;