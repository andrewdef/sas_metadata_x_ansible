%macro util_load_configuration_params(config_files_directory);
	%local this_macroname global_config_file host_specific_config_file;
	%let this_macroname = &SYSMACRONAME.;
	
	%let global_config_file = %fsutil_path_combine(&config_files_directory., config.properties);
	%let host_specific_config_file = %fsutil_path_combine(&config_files_directory., config-%lowcase(&SYSHOSTNAME.).properties);
	
	%if not %sysfunc(fileexist(&global_config_file.)) %then %do;
		%errhandle_throw_exception(CANNOT_FIND_CONFIG_FILE, <&this_macroname.> Cannot find required configuration file &global_config_file.);
		%return;
	%end;
	
	%macro load_config_file(config_file);
		%util_print_log(<&this_macroname.> Inizio caricamento file di configurazione &config_file.)
		data _null_;
			length config_name $ 32 config_value $ 1024;
			infile "&config_file." lrecl=1024;
			input;
			
			if substr(_INFILE_, 1, 1) ^= '#' then do;
				config_name = scan(_INFILE_, 1, '=');
				config_value = scan(_INFILE_, 2, '=');
				
				call symputx(config_name, config_value, 'G');
			end;
		run;
		%if &SYSCC. > 4 %then %return;
		
		%util_print_log(<&this_macroname.> Caricamento completato)
	%mend load_config_file;
	
	%load_config_file(&global_config_file.)
	%if &SYSCC. > 4 %then %return;
	
	%if %sysfunc(fileexist(&host_specific_config_file.)) %then %do;
		%load_config_file(&host_specific_config_file.)
		%if &SYSCC. > 4 %then %return;
	%end;	

%mend util_load_configuration_params;