%macro metautil_create_directory(dir_to_create_full_path);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;
	
	%macro create_folder();
		new_folder_uri='';

		if ( parent_folder_object_id = '' ) then do;
			association_name = 'SoftwareTrees';
			parent_folder_uri = "omsobj:SoftwareComponent?SoftwareComponent[@Name='BIP Service']";
		end;
		else do;
			association_name = 'SubTrees';
			parent_folder_uri = cats("omsobj:Tree\", parent_folder_object_id);
		end;

		rc = metadata_newobj("Tree", new_folder_uri, folder_name, '', parent_folder_uri, association_name);
		if rc lt 0 then do;
			error_message = catx(" ", "<&this_macroname.> error while creating metadata object:", sysmsg());
			call symputx('error_message', error_message);
			stop;
		end;

		rc = metadata_setattr(new_folder_uri, 'TreeType', 'BIP Folder');
		if rc lt 0 then do;
			error_message = catx(" ", "<&this_macroname.> error while setting attribute:", sysmsg());
			call symputx('error_message', error_message);
			stop;
		end;

		rc = metadata_setattr(new_folder_uri, 'PublicType', 'Folder');
		if rc lt 0 then do;
			error_message = catx(" ", "<&this_macroname.> error while setting attribute:", sysmsg());
			call symputx('error_message', error_message);
			stop;
		end;

		rc = metadata_setattr(new_folder_uri, 'UsageVersion', '1000000');
		if rc lt 0 then do;
			error_message = catx(" ", "<&this_macroname.> error while setting attribute:", sysmsg());
			call symputx('error_message', error_message);
			stop;
		end;
	%mend create_folder;
	
	%util_print_log(<&this_macroname.> Start creating folder &dir_to_create_full_path.)

	%let error_message =;
	data _null_;

		length object_id parent_folder_object_id $17 
			   object_type folder_name parent_folder association_name $200 
			   query_uri parent_folder_uri new_folder_uri $1000
			   full_path_was_changed 8 error_message $ 256;
		;

		dir_to_create_full_path = strip("&dir_to_create_full_path.");

		i = 1;
		full_path_was_changed = 0;
		do until (0);
			parent_folder = scan(dir_to_create_full_path, i, '/');

			if ( parent_folder eq '' ) then 
				leave;

			query_uri = cats("omsobj:Tree?*[@Name='", parent_folder, "']");

			if ( parent_folder_object_id ne '' ) then do;
				query_uri = cats(query_uri, "[ParentTree/Tree[@Id='", parent_folder_object_id, "']]");
			end;
			else do;
				query_uri = cats(query_uri, "[SoftwareComponents/SoftwareComponent[@Name='BIP Service']]");
			end;

			object_type = '';
			object_id = '';
			rc = metadata_resolve(query_uri, object_type, object_id);
			if ( rc < 0 ) then do;
				error_message = catx(" ", "<&this_macroname.> error while resolving metadata object:", sysmsg());
				call symputx('error_message', error_message);
				stop;
			end;
			else if ( rc > 1 ) then do;
				error_message = catx(" ", "<&this_macroname.> multiple matching metadata objects found for tree folder:", parent_folder);
				call symputx('error_message', error_message);
				stop;
			end;
			else if ( rc = 0 ) then do;
				folder_name = parent_folder;
				%create_folder
				rc = metadata_getattr(new_folder_uri, "Id", object_id);
				full_path_was_changed = full_path_was_changed + 1;
			end;
			
			parent_folder_object_id = object_id;
			i + 1;
		end;

		nobj = metadata_getnobj(cats("omsobj:Tree?*[@Id='", object_id, "']"), 1, new_folder_uri);
		
		call symputx("_METAUTIL_LAST_OBJECT_URI", new_folder_uri, "G");
		call symputx("_METAUTIL_LAST_OBJECT_WAS_CHANGD", full_path_was_changed, "G");
	run;
	%if %superq(error_message) ^= %then %do;
		%errhandle_throw_exception(METADATA_ERROR, %superq(error_message))
		%return;
	%end;
		
	%util_print_log(<&this_macroname.> Folder created successfully)

%mend metautil_create_directory;