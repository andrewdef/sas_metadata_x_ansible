%macro util_define_agg_fileref_cb(id=,type=, memname=, level=, parent=,context=,arg=);
	%if &type. = D %then %do;
		%let dirs_to_add = &dirs_to_add. "%fsutil_path_combine(&context., &memname.)";
	%end;	
%mend util_define_agg_fileref_cb;

%macro util_define_agg_fileref /PARMBUFF;
	%local fileref_type fileref_name main_dir i num_args;
	%if %superq(SYSPBUFF) ^= %then %do;
		%let SYSPBUFF = %qsubstr(%superq(SYSPBUFF), 2, %eval(%length(%superq(SYSPBUFF))-2));
	%end;

	%let fileref_type = %upcase(%unquote(%qtrim(%qleft(%listutil_get_element_by_index(%superq(SYSPBUFF), 1)))));

	%if &fileref_type. ^= LIBREF and &fileref_type. ^= FILEREF %then %do;
		%put ERROR: <&SYSMACRONAME.> Invalid value for FILEREF_TYPE parameter, accepted values are LIBREF|FILEREF;
		%let SYSCC = 5;
		%return;
	%end;

	%let fileref_name = %upcase(%unquote(%qtrim(%qleft(%listutil_get_element_by_index(%superq(SYSPBUFF), 2)))));
	
	%local dirs_to_add;
	
	%let num_args = %sysfunc(countw(%superq(SYSPBUFF), %str(,)));
	%do i = 3 %to &num_args.;
		%let main_dir = %unquote(%qtrim(%qleft(%listutil_get_element_by_index(%superq(SYSPBUFF), &i.))));
		
		%if %sysfunc(fileexist(&main_dir.)) %then %do;
			%let dirs_to_add = &dirs_to_add. "&main_dir.";
			
			%fsutil_dirtree_walk(%superq(main_dir), maxdepth=-1, callback=util_define_agg_fileref_cb);
		%end;
	%end;

	%sysfunc(ifc(&fileref_type. = LIBREF, libname, filename)) &fileref_name. (&dirs_to_add.);
	
%mend util_define_agg_fileref;