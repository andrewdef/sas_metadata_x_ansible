/**
 * Esegue il refresh di una tabella di configurazione a partire da un ddl in formato sas, ovvero un programma SAS; questa macro viene richiamata da util_refresh_config_tables.
 * Il file sas deve avere:
 *  - Un'istruzione libname iniziale che definisca il percorso di output della tabella di configurazione
 *  - Un passo di data che crei la tabella nella libreria in oggetto
 *
 * Esempio:
	libname tmp_cfg "%sysfunc(ifc(%symexist(SAS_SOLUTION_ROOT_PATH), &SAS_SOLUTION_ROOT_PATH., /sas/ifrs9))/config/default/glossary";

	data tmp_cfg.variables_glossary;
		...
	run;
	
 *  Il refresh viene eseguito solo se la data di ultima modifica del ddl e' piu' recente di quella della tabella di configurazione da creare.
 * 
 * @param ddl_file file ddl da elaborare, completo di percorso
*/

%macro util_refresh_cfg_tab_from_sas(ddl_file);
	%local this_macroname ddl_last_moddate found_cfg_tab_name_in_ddl dataset_name dataset_dir table_last_moddate path diff;
	%let this_macroname = &SYSMACRONAME.;
	
	%let ddl_last_moddate = %fsutil_get_file_lastmoddate(&ddl_file.);

	%let found_cfg_tab_name_in_ddl = 0;
	data _null_;
		infile "&ddl_file." end=eof;
		
		if _N_ =1 then do;
			retain prx_id_libname prx_id_datastep;
			prx_id_datastep = prxparse("/^data/i");
			prx_id_libname = prxparse("/^libname\s+\w{1,8}\s+(.+)+?;/i");
		end;
		length row $ 256 dataset_dir $ 256 dataset_name $ 32;
		retain dataset_dir dataset_name;
		
		input;
		row = _INFILE_;
		
		if prxmatch(prx_id_libname, row) then do;
			call prxposn(prx_id_libname, 1, position, length);
			dataset_dir = compress(compress(substr(row, position, length), "'"), '"');
		end;
		else if prxmatch(prx_id_datastep, row) then do;
			dataset_name = lowcase(scan(row, 3, ' .;'));
			
			call symputx('dataset_dir', dataset_dir);
			call symputx('dataset_name', dataset_name);	
			
			stop;
		end;
		
		if eof then
			call symputx('found_cfg_tab_name_in_ddl', 1);
	run;		

	%if &found_cfg_tab_name_in_ddl. = 1 or &dataset_name. = %then %do;
		%util_print_log(<&this_macroname.> Non è stato trovato il nome della tabella di configurazione da aggiornare nel file);
		%return;
	%end;
	
	%let path = %fsutil_path_combine(&dataset_dir., &dataset_name..sas7bdat);
	
	%if not %sysfunc(fileexist(&path.)) %then
		%let table_last_moddate = 0;
	%else
		%let table_last_moddate = %fsutil_get_file_lastmoddate(&path.);
	
	%let diff = %sysfunc(sum(&ddl_last_moddate., - &table_last_moddate.));
	%if %sysevalf(&diff. > 0) %then %do;
		%if not %sysfunc(fileexist(&dataset_dir.)) %then %do;
			%fsutil_mkdirs(&dataset_dir.);
			%if &SYSCC. > 4 %then %return;
		%end;
		
		%include "&ddl_file." /lrecl=32767;
		%util_print_log(<&this_macroname.> Il path e il nome della tabella aggiornata e%str(%'): &path.);
	%end;
	%else 
		%util_print_log(<&this_macroname.> La tabella &dataset_name. non e%str(%') stata aggiornata);
		
%mend util_refresh_cfg_tab_from_sas;