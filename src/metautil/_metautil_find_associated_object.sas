%macro _metautil_find_associated_object(object_uri, association_name, associated_object_type, associated_object_name, return_var);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;
	
	%local error_message;
	data _null_;
		length associated_object_uri associated_object_name associated_object_type associated_object_id $ 128;

		n = 1;		
		do while ( 1 );
			call missing(associated_object_uri);
			
			rc = metadata_getnasn("&object_uri.", "&association_name.", n, associated_object_uri);
			if rc = -4 then
				leave;
				
			%_metautil_stop_if_error(metadata_getnasn, &association_name.)
			
			call missing(associated_object_name, associated_object_type, associated_object_id);
			
			rc = metadata_getattr(associated_object_uri, 'Name', associated_object_name);
			%_metautil_stop_if_error(metadata_getattr, 'Name')

			rc = metadata_resolve(associated_object_uri, associated_object_type, associated_object_id);
			%_metautil_stop_if_error(metadata_resolve, associated_object_uri)

			if associated_object_name = "&associated_object_name." and associated_object_type = "&associated_object_type." then do;
				call symputx("&return_var.", associated_object_uri);
				leave;
			end;
				
			n = n + 1;
		end;
	run;
	%if %superq(error_message) ^= %then %do;
		%errhandle_throw_exception(METADATA_ERROR, <&this_macroname.> %superq(error_message))
	%end;
	%if &SYSCC. > 4 %then %return;
	
%mend _metautil_find_associated_object;