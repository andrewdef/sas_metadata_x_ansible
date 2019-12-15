/**
 * Esegue il refresh di una tabella di configurazione a partire da un ddl in formato xml; questa macro viene richiamata da util_refresh_config_tables.
 * Il file xml deve avere una sezione iniziale racchiusa da un commento xml <!-- ... --> contenente le seguenti informazioni:
 *	- table_name: nome della tabella di configurazione da generare
 *  - table_path: percorso in cui va creata la tabella
 *  - [opzionale] table_creation_code: { codice sas da eseguire per creare la tabella }
 *
 * Esempio:
	<!--
		TABLE_NAME: workflow
		TABLE_PATH: %sysfunc(ifc(%symexist(SAS_SOLUTION_ROOT_PATH), &SAS_SOLUTION_ROOT_PATH., /sas/ifrs9))/config/default/	
		TABLE_CREATION_CODE: {
							  data tmp_cfg.foo; 
								set in_xml.workflow; 
							  run;
							  }
	-->

 *	La macro definisce una libreria IN_XML con engine xml che punta al file xml in oggetto; se esiste un file .map nella stessa directory e con lo stesso nome del ddl, tale
 *  mappa viene usata come xmlmap per la libreria, altrimenti utilizza l'automap dell'engine xmlv2 (vedere la documentazione ufficiale SAS per maggiori informazioni).
 *  Inoltre, definisce una libreria tmp_cfg che punta a <table_path>
 *  Infine esegue i seguenti passi per refreshare la tabella di configurazione:
 *	 - Se esiste <table_creation_code<, esegue tale codice
 *	 - Altrimenti, esegue un semplice passo di data che crea la tabella tmp_cfg.<table_name> leggendo da in_xml.<table_name>
 *  Il refresh viene eseguito solo se la data di ultima modifica del ddl o del map e' piu' recente di quella della tabella di configurazione da creare.
 * 
 * @param ddl_file file ddl da elaborare, completo di percorso
*/

%macro util_refresh_cfg_tab_from_xml(ddl_file);
	%local this_macroname ddl_last_moddate dataset_name dataset_dir table_last_moddate path ddl_map_lastmoddate has_sas_code_in_ddl ddl_dir ddl_filename ddl_map_file
		   validation_check_outcome;
	%let this_macroname = &SYSMACRONAME.;
	
	%let ddl_last_moddate = %fsutil_get_file_lastmoddate(&ddl_file.);
	%let ddl_dir = %fsutil_get_dir(&ddl_file.);
	%let ddl_filename = %fsutil_get_filename(&ddl_file.);

	%let ddl_map_file = %fsutil_path_combine(&ddl_dir., &ddl_filename..map);
	%if not %sysfunc(fileexist(&ddl_map_file.)) %then
		%let ddl_map_lastmoddate = 0;
	%else
		%let ddl_map_lastmoddate = %fsutil_get_file_lastmoddate(&ddl_map_file.);
		
	filename sascode temp;
		
	%let validation_check_outcome = 0;
	%let has_sas_code_in_ddl = 0;
	data _null_;
		infile "&ddl_file." end=eof;
		file sascode;
		
		if _N_ = 1 then do;
			retain prx_id_outpath prx_id_tabname prx_id_sascode;
			prx_id_tabname = prxparse("/^\s*table_name\s*:\s*([a-z0-9_]{1,32})/i");
			prx_id_outpath = prxparse("/^\s*table_path\s*:\s*(.+)/i");
			prx_id_sascode = prxparse("/^\s*table_creation_code\s*:\s*{([^}]+)(})?/i");
		end;
		length row sascode_row $ 256 dataset_dir $ 256 dataset_name $ 32 last_char $ 1;
		retain dataset_dir dataset_name;
		
		retain is_in_sascode 0;

		input;
		row = _INFILE_;
		
		if _N_ = 1 and index(row, '<!--') = 0 then do;
			put "ERROR: <&this_macroname.> DDL must start with a comment <!--";
			call symputx('validation_check_outcome', '1');
			stop;
		end;
		
		if is_in_sascode then do;
			if substr(reverse(strip(row)), 1, 1) = '}' then do;
				is_in_sascode = 0;
				row = tranwrd(row, '}', '');
			end;
			
			put row;
		end;
		else if prxmatch(prx_id_sascode, row) then do;
			call symputx('has_sas_code_in_ddl', '1');
			
			sascode_row = prxposn(prx_id_sascode, 1, row);
			put sascode_row;
			
			last_char = prxposn(prx_id_sascode, 2, row);
			if last_char ^= '}' then
				is_in_sascode = 1;
		end;
		else if prxmatch(prx_id_outpath, row) then do;
			dataset_dir = prxposn(prx_id_outpath, 1, row);
		end;
		else if prxmatch(prx_id_tabname, row) then do;
			dataset_name = prxposn(prx_id_tabname, 1, row);
		end;
		
		if index(row, '-->') then do;
			call symputx('dataset_dir', trim(dataset_dir));
			call symputx('dataset_name', trim(dataset_name));	
			
			stop;
		end;
	run;
	%if &validation_check_outcome. %then %do;
		%let SYSCC = 5;
		%return;
	%end;

	%if %superq(dataset_name) = %then %do;
		%util_print_log(<&this_macroname.> Cannot find the name of the target table in the DDL);
		%return;
	%end;
	%else %if %superq(dataset_dir) = %then %do;
		%util_print_log(<&this_macroname.> Cannot find the path of the target table in the DDL);
		%return;
	%end;
	
	%let path = %fsutil_path_combine(&dataset_dir., &dataset_name..sas7bdat);
	
	%if not %sysfunc(fileexist(&path.)) %then
		%let table_last_moddate = 0;
	%else
		%let table_last_moddate = %fsutil_get_file_lastmoddate(&path.);

	%if %sysevalf(&ddl_last_moddate. > &table_last_moddate.) or %sysevalf(&ddl_map_lastmoddate. > &table_last_moddate.) %then %do;
		%if not %sysfunc(fileexist(&ddl_map_file.)) %then %do;
			filename map temp;
			libname in_xml xmlv2 "&ddl_file." xmlmap=map automap=replace;
		%end;
		%else %do;
			filename map "&ddl_map_file.";
			libname in_xml xmlv2 "&ddl_file." xmlmap=map;
		%end;
		
		%util_alloc_lib_to_dir(TMP_CFG, &dataset_dir.);
		%if &SYSCC. > 4 %then %return;
		
		%if &has_sas_code_in_ddl. %then %do;
			%include sascode;
			%if &SYSCC. > 4 %then %return;
		%end;
		%else %do;
			data tmp_cfg.&dataset_name.;
				set in_xml.&dataset_name.;
			run;
			%if &SYSCC. > 4 %then %return;
		%end;
		
		libname in_xml clear;
		filename map clear;
		
		%util_print_log(<&this_macroname.> The table &path. was updated);
	%end;
	%else 
		%util_print_log(<&this_macroname.> The table &dataset_name. was not updated);
	
	filename sascode clear;
	
%mend util_refresh_cfg_tab_from_xml;