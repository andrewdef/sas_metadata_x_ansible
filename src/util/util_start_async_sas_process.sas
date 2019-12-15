%macro util_start_async_sas_process(sas_exe, sas_program_to_start, log_file, parameters, options=);
	%local argument_separator statement param_string num_params param_name i;
	
	%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
		options noxwait noxsync;
		%let argument_separator = |;
		%let statement = x;
	%end;
	%else %do;
		%let argument_separator = !;
		%let statement = systask command;
	%end;
	
	%let num_params = %sysfunc(countw(%nrbquote(&parameters.)));
	%do i = 1 %to &num_params.;
		%let param_name = %scan(%superq(parameters), &i., %str( ));
		
		%if %symexist(&param_name.) %then
			%let param_string = &param_string.&param_name.=&&&param_name..;
		%else
			%let param_string = &param_string.&param_name.=;
			
		%if &i. ^= &num_params. %then
			%let param_string = &param_string.&argument_separator.;
	%end;
	
	&statement. " &sas_exe. -xcmd -sysin &sas_program_to_start.
			   -log &log_file. -logparm ""rollover=session write=immediate""
			   -sysparm ""&param_string.""  &options. " nowait;

%mend util_start_async_sas_process;