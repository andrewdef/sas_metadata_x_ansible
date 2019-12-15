%macro metautil_create_association / PARMBUFF;
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;
	
	%local this_call_sequence;
	%let this_call_sequence = &call_sequence.;
	
	%local i opt object_uri association_name association_type association_object regexp_id quoted_paramstring association_cardinality association_object_sharable;
	
	%let quoted_paramstring = %superq(SYSPBUFF);
	
	%let regexp_id = %sysfunc(prxparse(/\((.+?)%str(,)(.+?)%str(,)(.*?)%str(,)(.+)\)/));
	%if %sysfunc(prxmatch(&regexp_id., &quoted_paramstring.)) %then %do;
		%let object_uri = %sysfunc(prxposn(&regexp_id., 1, &quoted_paramstring.));
		%let association_name = %sysfunc(prxposn(&regexp_id., 2, &quoted_paramstring.));
		%let association_type = %sysfunc(prxposn(&regexp_id., 3, &quoted_paramstring.));
		%let association_object = %sysfunc(prxposn(&regexp_id., 4, &quoted_paramstring.));
	%end;
	%else %do;
		%errhandle_throw_exception(INVALID_ARGUMENT, <&this_macroname.-&this_call_sequence.> Macro arguments are not in the format (object_uri%str(,)association_name%str(,)association_type%str(,)association_object))
		%return;
	%end;
	
	%if "&object_uri." = "" %then %do;
		%errhandle_throw_exception(NO_OBJECTNAME_SPECIFIED, <&this_macroname.-&this_call_sequence.> object_uri cannot be missing)
		%return;
	%end;
	%else %if "&association_name." = "" %then %do;
		%errhandle_throw_exception(NO_OBJECTNAME_SPECIFIED, <&this_macroname.-&this_call_sequence.> association_name cannot be missing)
		%return;
	%end;
	%else %if %superq(association_object) = %then %do;
		%errhandle_throw_exception(NO_OBJECTNAME_SPECIFIED, <&this_macroname.-&this_call_sequence.> association_object cannot be missing)
		%return;
	%end;
	
	%do i = 1 %to %sysfunc(countw(&association_type.,  %str(|)));
		%let opt = %upcase(%scan(&association_type., &i., %str(|)));
		
		%if "&opt." = "ONETOMANY" or "&opt." = "ONETOONE" %then
			%let association_cardinality = &opt.;
		%else %if "&opt." = "SHARED" or "&opt." = "NOTSHARED" %then
			%let association_object_sharable = &opt.;
	%end;
	
	%if "&association_cardinality." = "" %then
		%let association_cardinality = ONETOMANY;
		
	%if "&association_object_sharable." = "" %then
		%let association_object_sharable = SHARED;	
			
	%local uri_of_object_to_associate object_was_changed association_to_create_tab parent_to_create_tab attributes_to_assign_tab object_main_info_tab
		   associated_object_type associated_object_name;
	%let object_was_changed = 0;
	
	%let association_to_create_tab = assoc_&this_call_sequence.;
	%let attributes_to_assign_tab = attrib_&this_call_sequence.;
	%let parent_to_create_tab = parent_&this_call_sequence.;
	%let object_main_info_tab = main_&this_call_sequence.;
	
	%_metautil_parse_object_string(&association_to_create_tab., &attributes_to_assign_tab., &parent_to_create_tab., &object_main_info_tab., &association_object.)
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.-&this_call_sequence.> Start creating object to associate)
	
	%if "&association_object_sharable." = "NOTSHARED" %then %do;
		data _null_;
			set &object_main_info_tab.;
			
			if ATTRIBUTE_NAME = '_name' then
				call symputx("associated_object_name", ATTRIBUTE_VALUE, 'L');
			else if ATTRIBUTE_NAME = '_type' then
				call symputx("associated_object_type", ATTRIBUTE_VALUE, 'L');
		run;
		%if &SYSCC. > 4 %then %return;
		
		%_metautil_find_associated_object(&object_uri., &association_name., &associated_object_type., &associated_object_name., uri_of_object_to_associate)
		%if &SYSCC. > 4 %then %return;
		
		%if "%superq(uri_of_object_to_associate)" = "" %then %do;
			%metautil_create_object(&association_to_create_tab., &attributes_to_assign_tab., &parent_to_create_tab., &object_main_info_tab.)
			%if &SYSCC. > 4 %then %return;
		%end;
		%else %do;
			%metautil_create_object(&association_to_create_tab., &attributes_to_assign_tab., &parent_to_create_tab., &object_main_info_tab., created_object_uri=%superq(uri_of_object_to_associate))
			%if &SYSCC. > 4 %then %return;
		%end;
		
		%let uri_of_object_to_associate = &_METAUTIL_LAST_OBJECT_URI.;
		%let object_was_changed = %eval(&object_was_changed. + &_METAUTIL_LAST_OBJECT_WAS_CHANGD.);
	%end;
	%else %do;
		%metautil_create_object(&association_to_create_tab., &attributes_to_assign_tab., &parent_to_create_tab., &object_main_info_tab.)
		%if &SYSCC. > 4 %then %return;
		
		%let uri_of_object_to_associate = &_METAUTIL_LAST_OBJECT_URI.;
		%let object_was_changed = %eval(&object_was_changed. + &_METAUTIL_LAST_OBJECT_WAS_CHANGD.);
	%end;
	
	%util_print_log(<&this_macroname.-&this_call_sequence.> Object to associate created)
	
	%util_print_log(<&this_macroname.-&this_call_sequence.> Start creating association &association_name.)
	
	%local error_message;
	data _null_;
		length associated_object_uri $ 128;

		found_already_existing_object = 0;
		object_was_changed = 0;
		
		n = 1;		
		do while ( 1 );
			call missing(associated_object_uri);
			
			rc = metadata_getnasn("&object_uri.", "&association_name.", n, associated_object_uri);
			if rc = -4 then
				leave;
				
			%_metautil_stop_if_error(metadata_getnasn, &association_name.)
			
			if associated_object_uri = "&uri_of_object_to_associate." then do;
				found_already_existing_object = 1;
				leave;
			end;
				
			n = n + 1;
		end;
		
		if not found_already_existing_object then do;
			put "<&this_macroname.-&this_call_sequence.> Object was not already associated, an new association will be created";
			
			if "&association_cardinality." = "ONETOMANY" then do;
				rc = metadata_setassn("&object_uri.", "&association_name.", "Merge", "&uri_of_object_to_associate.");
			end;
			else do;
				rc = metadata_setassn("&object_uri.", "&association_name.", "Replace", "&uri_of_object_to_associate.");
			end;
			%_metautil_stop_if_error(metadata_setnasn, &association_name.)
			
			object_was_changed = 1;
		end;
		else do;
			put "<&this_macroname.-&this_call_sequence.> The object was already associated within association &association_name., will not be associated again";
		end;
		
		call symputx("object_was_changed", object_was_changed + &object_was_changed., 'L');
	run;
	%if %superq(error_message) ^= %then %do;
		%errhandle_throw_exception(METADATA_ERROR, <&this_macroname.-&this_call_sequence.> %superq(error_message))
	%end;
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.-&this_call_sequence.> Association created)
	
	%global _METAUTIL_LAST_OBJECT_URI _METAUTIL_LAST_OBJECT_WAS_CHANGD;
	%let _METAUTIL_LAST_OBJECT_URI = &object_uri.;
	%let _METAUTIL_LAST_OBJECT_WAS_CHANGD = &object_was_changed.;
	
%mend metautil_create_association;