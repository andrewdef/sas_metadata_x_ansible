%macro metautil_create_object / PARMBUFF;
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;
	
	%if not %symexist(call_sequence) %then
		%let call_sequence = 1;
	
	%local this_call_sequence;
	%let this_call_sequence = &call_sequence.;
	
	%local created_object_uri object_was_changed association_to_create_tab parent_to_create_tab attributes_to_assign_tab object_main_info_tab quoted_paramstring
		   regexp_id;
	%let object_was_changed = 0;
	
	%let quoted_paramstring = %superq(SYSPBUFF);

	%let regexp_id = %sysfunc(prxparse(/\(\s*([\da-z_]+?)\s*%str(,)\s*([\da-z_]+?)\s*%str(,)\s*([\da-z_]+?)\s*%str(,)\s*([\da-z_]+?)(\s*%str(,)\s*created_object_uri\s*=\s*[\da-z:\\\.]+)?\)/i));
	%if %sysfunc(prxmatch(&regexp_id., &quoted_paramstring.)) %then %do;
		%let association_to_create_tab = %sysfunc(prxposn(&regexp_id., 1, &quoted_paramstring.));
		%let attributes_to_assign_tab = %sysfunc(prxposn(&regexp_id., 2, &quoted_paramstring.));
		%let parent_to_create_tab = %sysfunc(prxposn(&regexp_id., 3, &quoted_paramstring.));
		%let object_main_info_tab = %sysfunc(prxposn(&regexp_id., 4, &quoted_paramstring.));
	%end;
	%else %do;
		%let association_to_create_tab = assoc_&this_call_sequence.;
		%let attributes_to_assign_tab = attrib_&this_call_sequence.;
		%let parent_to_create_tab = parent_&this_call_sequence.;
		%let object_main_info_tab = main_&this_call_sequence.;
		
		%_metautil_parse_object_string(&association_to_create_tab., &attributes_to_assign_tab., &parent_to_create_tab., &object_main_info_tab., 
										&SYSPBUFF.)
		%if &SYSCC. > 4 %then %return;
	%end;
	
	%let regexp_id = %sysfunc(prxparse(/created_object_uri\s*\=\s*([\da-z:\\\.]+)/i));
	%if %sysfunc(prxmatch(&regexp_id., &quoted_paramstring.)) %then %do;
		%let created_object_uri = %sysfunc(prxposn(&regexp_id., 1, &quoted_paramstring.));
	%end;

	%local object_name object_type object_folder object_parent object_parent_association has_parent rc;
	
	data _null_;
		set &object_main_info_tab.;
		
		if ATTRIBUTE_NAME = '_name' then
			call symputx("object_name", ATTRIBUTE_VALUE, 'L');
		else if ATTRIBUTE_NAME = '_type' then
			call symputx("object_type", ATTRIBUTE_VALUE, 'L');
		else if ATTRIBUTE_NAME = '_folder' then
			call symputx("object_folder", ATTRIBUTE_VALUE, 'L');
	run;
	%if &SYSCC. > 4 %then %return;

	%let has_parent = %util_get_nobs(&parent_to_create_tab.);

	%util_print_log(<&this_macroname.-&this_call_sequence.> Creating object &object_name.%str(,) type &object_type.)
	
	%if "%superq(created_object_uri)" = "" %then %do;

		%if "&object_folder." ^= "" %then %do;
			%metautil_create_directory(&object_folder.)
			%if &SYSCC. > 4 %then %return;

			%let object_parent = &_METAUTIL_LAST_OBJECT_URI.;
			%let object_parent_association = Members;
			%let object_was_changed = %eval(&object_was_changed. + &_METAUTIL_LAST_OBJECT_WAS_CHANGD.);
		%end;
		%else %if &has_parent. %then %do;
			data _null_;
				set &parent_to_create_tab.;
				
				call symputx('object_parent', ASSOCIATION_OBJECT, 'L');
				call symputx('object_parent_association', ASSOCIATION_TYPE, 'L');
			run;
			%if &SYSCC. > 4 %then %return;
			
			%util_print_log(<&this_macroname.-&this_call_sequence.> Object has parent%str(,) creating it)
			
			%let call_sequence = %eval(&call_sequence. + 1);
			%metautil_create_object(&object_parent.)
			%if &SYSCC. > 4 %then %return;
			
			%util_print_log(<&this_macroname.-&this_call_sequence.> Parent created)
			
			%let object_parent = &_METAUTIL_LAST_OBJECT_URI.;
			%let object_was_changed = %eval(&object_was_changed. + &_METAUTIL_LAST_OBJECT_WAS_CHANGD.);
		%end;
		
		%local error_message;
		data _null_;
			length object_uri $256 object_was_changed 8;
			retain object_uri "" object_was_changed 0;
			
			rc = metadata_getnobj("omsobj:&object_type.?@Name='&object_name.'", 1, object_uri);
			%_metautil_stop_if_error(metadata_getnobj, &object_type., throw_exception_if_obj_not_found=0)
			
			if rc = 0 or rc = -4 then do;
				put "<&this_macroname.-&this_call_sequence.> Object does not exist, creating it";
				
				if "&object_parent." = "" then
					rc = metadata_newobj("&object_type.", object_uri, "&object_name.", "Foundation");
				else
					rc = metadata_newobj("&object_type.", object_uri, "&object_name.", "Foundation", "&object_parent.", "&object_parent_association.");
				%_metautil_stop_if_error(metadata_newobj, &object_type.)
				
				object_was_changed = object_was_changed + 1;
			end;
			else do;
				put "<&this_macroname.-&this_call_sequence.> Object exists, will not be recreated";
			end;
			put "<&this_macroname.-&this_call_sequence.> Object URI: " object_uri;
			
			call symputx("created_object_uri", object_uri, 'L');
			call symputx("object_was_changed", object_was_changed + &object_was_changed., 'L');
		run;
		%if %superq(error_message) ^= %then %do;
			%errhandle_throw_exception(METADATA_ERROR, <&this_macroname.-&this_call_sequence.> %superq(error_message))
		%end;
		%if &SYSCC. > 4 %then %return;

	%end;
	%else %do;
		%put <&this_macroname.-&this_call_sequence.> Object exists, will not be recreated;
		%put <&this_macroname.-&this_call_sequence.> Object URI: &created_object_uri.;
	%end;
	
	%metautil_set_object_structure(&created_object_uri., &association_to_create_tab., &attributes_to_assign_tab.)
	%if &SYSCC. > 4 %then %return;	
	%let object_was_changed = %eval(&object_was_changed. + &_METAUTIL_LAST_OBJECT_WAS_CHANGD.);
	
	%util_print_log(<&this_macroname.-&this_call_sequence.> Object &object_name. created successfully)

	proc datasets lib=work noprint;
		delete &attributes_to_assign_tab. &association_to_create_tab. &parent_to_create_tab. &object_main_info_tab.;
	run; quit;
	
	%global _METAUTIL_LAST_OBJECT_URI _METAUTIL_LAST_OBJECT_WAS_CHANGD;
	%let _METAUTIL_LAST_OBJECT_URI = &created_object_uri.;
	%let _METAUTIL_LAST_OBJECT_WAS_CHANGD = &object_was_changed.;
	
%mend metautil_create_object;