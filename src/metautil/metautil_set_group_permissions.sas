%macro metautil_set_group_permissions(object_uri, group_name, permissions_to_set, authorization_level);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%let authorization_level = %lowcase(&authorization_level.);
	%if not %sysfunc(prxmatch(%sysfunc(prxparse(/^[gdr]$/)), &authorization_level.)) %then %do;
		%errhandle_throw_exception(ARGUMENT_ERROR, <&this_macroname.> Invalid value for authorization_level%str(,) values allowed: [D G R])
		%return;
	%end;
	
	%local object_was_changed;
	%let object_was_changed = 0;
	
	%util_print_log(<&this_macroname.> Start setting permissions on object for group %superq(group_name))
	
	%mdseccon() 
	
	%local error_message;
	data _null_;
		length object_uri $256 object_was_changed 8;
		
		object_uri = "&object_uri.";
		required_authorization_level = "&authorization_level.";
		object_was_changed = 0;
		
		length auth_string $ 16 permission_name cond $ 32 existing_authorization_level $ 1;
		
		if substr("&permissions_to_set.", 1, 1) = '/' then
			regexp_id = prxparse("&permissions_to_set.");
		else if lowcase("&permissions_to_set.") = '_all_' then
			regexp_id = prxparse('/^.+$/');
		else
			regexp_id = prxparse("/^&permissions_to_set.\b/");
		
		n = 1;
		matched_permissions = 0;
		do while( 1 );
			call missing(auth_string, permission_name, cond);
			rc = metasec_getnauth("", object_uri, n, "IdentityGroup", "%unquote(&group_name.)", auth_string, permission_name, cond);
			%_metautil_stop_if_error(metasec_getnauth, n)
			
			if rc = -5 then
				leave;
			
			if prxmatch(regexp_id, permission_name) then do;
				matched_permissions = matched_permissions + 1;
				auth = input(auth_string, 16.);
				
				if band(auth, &_SECAD_PERM_EXPM.) then do;
					if band(auth, &_SECAD_PERM_EXPD.) then
						existing_authorization_level = 'd';
					else
						existing_authorization_level = 'g';
				end;
				else
					existing_authorization_level = 'r';
					
				if existing_authorization_level ^= required_authorization_level then do;
					rc = metasec_setauth("", object_uri, "IdentityGroup", "&group_name.", required_authorization_level, permission_name, "");
					%_metautil_stop_if_error(metasec_setauth, n)
			
					object_was_changed = object_was_changed + 1;
				end;
			end;
			
			n = n + 1;
		end;

		if matched_permissions = 0 then do;
			error_message = catx(" ", "no permission name matches the supplied value: ", "%superq(permissions_to_set)");
			call symputx('error_message', error_message);
			stop;
		end;

		call symputx("object_was_changed", object_was_changed + &object_was_changed.);
	run;
	%if %superq(error_message) ^= %then %do;
		%errhandle_throw_exception(METADATA_ERROR, <&this_macroname.> %superq(error_message))
	%end;
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.> Permissions set)
	
	%global _METAUTIL_LAST_OBJECT_WAS_CHANGD;
	%let _METAUTIL_LAST_OBJECT_WAS_CHANGD = &object_was_changed.;
	
%mend metautil_set_group_permissions;