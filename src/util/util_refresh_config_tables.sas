/** 
 * La macro verifica tutte le ddl presente in ddl_dir ed eventuali sottodirectory e refresha le tabelle di configurazione
 * corrispondenti, se i ddl sono piu' aggiornati. La verifica dell'aggiornamento viene effettuata basandosi sulla data di
 * ultima modifica.
 * La macro elabora solo i file ddl con estensione xml e sas, richiamando le apposite macro util_refresh_cfg_tab_from_*
 * Maggiori informazioni sul formalismo richiesto dai file ddl sono presenti nelle suddette macro.
 *
 * @param ddl_dir directory contenente le ddl
*/

%macro util_refresh_config_tables(ddl_dir);
	options nosource nonotes;
	
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%macro refresh_callback(id=, type=, memname=, level=, parent=, context=, arg=);
		%if &type. = D %then %return;
		
		%local ext;
		
		%let ext = %lowcase(%fsutil_get_file_extension(&memname.));

		%if &ext. = sas %then %do;
			%util_refresh_cfg_tab_from_sas(&context.&pathsep.&memname.);
			%return;
		%end;
		%else %if &ext. = xml %then %do;
			%util_refresh_cfg_tab_from_xml(&context.&pathsep.&memname.);
			%return;
		%end;
		%else %do;
			%util_print_log(<&this_macroname.> Extention &ext. for file &context.&pathsep.&memname. not recognized);
			%return;
		%end;
	%mend refresh_callback;
	
	%util_print_log(<&this_macroname.> Start refresh configuration tables from ddl in directory &ddl_dir.);
	%fsutil_dirtree_walk_nores(&ddl_dir., callback=refresh_callback, maxdepth=-1);
	%util_print_log(<&this_macroname.> Refresh completed);
	
	options source notes;
%mend util_refresh_config_tables;