/** 
* Executes a SAS program using %include and provides timing information in the log.
*
* @param file_to_execute program tu execute, full path or fileref
* @param run_condition condition to check before running the program, if not true the program will not be execute, optional.
*/

%macro util_runsasfile(file_to_execute, run_condition=);
	%local this_macroname quit;
	%let this_macroname = &SYSMACRONAME.;
	
	%if %superq(run_condition)^=  %then %do;
		data _null_;
			if &run_condition. then 
				quit=0;
			else 
				quit=1;
			call symputx('quit',quit);
		run;		
		%if &quit. %then %do;
			%util_print_log(<&this_macroname.> Condition %superq(run_condition) not verified%str(,) the program will not be executed)
			%return;
		%end;
	%end;
	
	%if not %sysfunc(fileexist(&file_to_execute.)) %then %do;
		%errhandle_throw_exception(FILE_NOT_FOUND, <&this_macroname.> Program &file_to_execute. does not exist)
		%return;
	%end;
	
	%local __start_timestamp __end_timestamp __elapsed_time;

	%util_print_log(<&this_macroname.> Starting execution of program &file_to_execute.) 

	%let __start_timestamp = %sysfunc(datetime());

	%include "&file_to_execute.";
	
	%let __end_timestamp = %sysfunc(datetime());
	%let __elapsed_time = %sysevalf(&__end_timestamp. - &__start_timestamp.);

	%util_print_log(<&this_macroname.> Execution completed%str(,) time elapsed %sysfunc(putn(&__elapsed_time., time8.))) 

%mend util_runsasfile;