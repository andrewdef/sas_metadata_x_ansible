%macro util_order_and_keep_variables(input_table, variable_mapping_table, output_table, keep_unmapped_vars=1);
	%local this_macroname dsid i;
	%let this_macroname = &SYSMACRONAME.;
	
	%put %util_print_log(<&this_macroname.> Inizio ordinamento variabili per tabella &input_table.);
	
	proc contents data=&input_table. out=cont noprint;
	run;
	%if &SYSCC. > 4 %then %return;
	
	proc sql noprint;
		create table variable_list as
		select NAME as VAR_NAME
			  ,case
					when b.VAR_ORDER is not null then b.VAR_ORDER
					else 100000 + VARNUM
			   end as VAR_ORDER
		from cont a
			 left join
			 (select *
					,monotonic() as VAR_ORDER
			  from &variable_mapping_table. 
			 ) b
			 on upcase(a.NAME) = upcase(b.VAR_NAME)
		%if not &keep_unmapped_vars. %then %do;
		where b.VAR_ORDER is not null
		%end;
		order by VAR_ORDER
		;
	quit;
	%if &SQLRC. > 4 %then %return;
	
	%if &SQLOBS. = 0 %then %do;
		%errhandle_throw_exception(NO_VAR_TO_KEEP, <&this_macroname.> Nessuna variabile trovata in tabella mappatura &variable_mapping_table. per tabella &input_table.);
		%return;
	%end;
	
	%let dsid = %sysfunc(open(variable_list));
	%syscall set(dsid);
	
	%let i = 1;
	proc sql noprint;
		create table &output_table. as
		select %do %while( %sysfunc(fetch(&dsid.)) = 0 );
					%if &i. > 1 %then %do;
					,
					%end;
					&VAR_NAME.
				
					%let i = %eval(&i. + 1);
			  	%end;
				%let dsid = %sysfunc(close(&dsid.));
		from &input_table.;
	quit;
	%if &SQLRC. > 4 %then %return;
	
	%put %util_print_log(<&this_macroname.> Ordinamento completato);

%mend util_order_and_keep_variables;