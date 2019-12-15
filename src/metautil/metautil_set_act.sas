%macro metautil_set_act(object_uri, act_to_set);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;
	
	%local object_was_changed;
	%let object_was_changed = 0;
	
	%util_print_log(<&this_macroname.> Start setting ACTs on object)
	
	%mdseccon() 
	
	%local error_message;
	data _null_;
		length object_uri $256 object_was_changed 8;
		
		object_uri = "&object_uri.";
		object_was_changed = 0;
		
		length act_uri act_name act_desc act_use $256;
		
		if substr("&act_to_set.", 1, 1) = '/' then
			regexp_id = prxparse("&act_to_set.");
		else
			regexp_id = prxparse("/^&act_to_set.\b/");
			
		declare hash uri_of_act_to_set();
		uri_of_act_to_set.defineKey("act_uri");
		uri_of_act_to_set.defineData("act_uri");
		uri_of_act_to_set.defineDone();
		
		declare hiter h("uri_of_act_to_set");
		
		/* Find uris of required ACT */
		n = 1;
		do while ( 1 );
			rc = metadata_getnobj("omsobj:AccessControlTemplate?@Id contains '.'", n, act_uri);
			%_metautil_stop_if_error(metadata_getnobj, AccessControlTemplate, throw_exception_if_obj_not_found=0)
			
			if rc in (0, -4) then
				leave;

			rc = metadata_getattr(act_uri, "Name", act_name);
			%_metautil_stop_if_error(metadata_getattr, "Name")
			
			if prxmatch(regexp_id, act_name) then
				uri_of_act_to_set.add();
				
			n = n + 1;
		end;
		
		if uri_of_act_to_set.num_items = 0 and lowcase("&act_to_set") ^= '_none_' then do;
			error_message = catx(" ", "no ACT name matches the supplied value: ", "%superq(act_to_set)");
			call symputx('error_message', error_message);
			stop;
		end;
		
		/* Remove ACTs that are applied on the object but not requested; remove already applied ACTs from the required ACTs list */
		n = 1;
		do while( 1 );
			call missing(act_uri, act_name, act_desc, act_use);
			rc = metasec_getnact("", object_uri, n, act_uri, act_name, act_desc);
			%_metautil_stop_if_error(metasec_getnact, n)

			if rc = -5 then
				leave;
			
			act_uri = cats('OMSOBJ:AccessControlTemplate\', trim(act_uri));
			if uri_of_act_to_set.find(key: act_uri) ^= 0 then do;
				rc = metasec_remact("", object_uri, act_uri, 0);
				%_metautil_stop_if_error(metasec_remact, act_uri)
				
				object_was_changed = object_was_changed + 1;
			end;
			else do;
				uri_of_act_to_set.remove(key: act_uri);
			end;			
			
			n = n + 1;
		end;

		/* Apply ACTs that were requested and not already applied */
		do while( 1 );
			call missing(act_uri);
			rc = h.next();
			
			if rc ^= 0 then
				leave;
				
			rc = metasec_applyact("", object_uri, act_uri, 0);
			%_metautil_stop_if_error(metasec_applyact, act_uri)

			object_was_changed = object_was_changed + 1;			
		end;

		call symputx("object_was_changed", object_was_changed + &object_was_changed.);
	run;
	%if %superq(error_message) ^= %then %do;
		%errhandle_throw_exception(METADATA_ERROR, <&this_macroname.> %superq(error_message))
	%end;
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.> ACTs set)
	
	%global _METAUTIL_LAST_OBJECT_WAS_CHANGD;
	%let _METAUTIL_LAST_OBJECT_WAS_CHANGD = &object_was_changed.;
	
%mend metautil_set_act;