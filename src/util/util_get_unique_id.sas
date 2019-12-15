%macro util_get_unique_id(namespace);
	%local this_macroname is_initialized dsid;
	%let this_macroname = &SYSMACRONAME.;
	
	%let is_initialized = 1;
	%if not %sysfunc(exist(work.arace_functions)) %then %do;
		%let is_initialized = 0;
	%end;
	%else %do;
		%let dsid = %sysfunc(open(work.arace_functions(where=(upcase(_KEY_) = "F.UTIL.GET_UNIQUE_ID")), i));
		%if &dsid. = 0 %then %do;
			%errhandle_throw_exception(CANNOT_OPEN_DATASET,  <&this_macroname.> Error during INITIALIZATION%str(,) cannot open work.arace_functions: %qsysfunc(sysmsg()));
			%return;
		%end;

		%let is_initialized = %eval(%sysfunc(attrn(&dsid., NLOBSF)) > 0);

		%let dsid = %sysfunc(close(&dsid.));
	%end;
	
	%if "%upcase(&namespace.)" = "_INITIALIZE" %then %do;
		%if &is_initialized. %then
			%return;
			
		proc fcmp outlib=work.arace_functions.util;
			function get_unique_id(namespace $);
				length namespace $ 32 id 8;
				declare hash id_provider;
				
				static id_provider is_first_call 1;
				if is_first_call then do;
					rc = id_provider.defineKey("namespace");
					rc = id_provider.defineData("id");
					rc = id_provider.defineDone();

					is_first_call = 0;
				end;
				
				call missing(id);
				rc = id_provider.find();
				
				id = sum(id, 1);
				if rc = 0 then
					rc = id_provider.replace();
				else
					rc = id_provider.add();
				
				return (id);				
			endsub;
		run; quit;

		options insert = cmplib work.arace_functions;
		%return;
	%end;
	
	%if not &is_initialized. %then %do;
		%errhandle_throw_exception(FUNCTION_NOT_INITIALIZED, <&this_macroname.> Cannot find function get_unique_id in catalog work.arace_functions.util);
		%errhandle_throw_exception(FUNCTION_NOT_INITIALIZED, <&this_macroname.> Make sure to call this macro with argument _INITIALIZE first);
		%return;
	%end;
	
	%sysfunc(get_unique_id(&namespace.))
%mend;
