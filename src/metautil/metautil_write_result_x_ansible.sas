%macro metautil_write_result_x_ansible(object_uri, object_was_changed, output_file);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;
	
	%util_print_log(<&this_macroname.> Start writing output for Ansible to file &output_file.)
	
	%local error_message;
	data _null_;
		length object_uri $256 attr_name $ 32 attr_value $ 128;
		
		file "&output_file.";
		
		put "&object_was_changed.";
		
		object_uri = "&object_uri.";
		
		put "{";

		n = 1;
		do while( 1 );
			call missing(attr_name, attr_value);
			rc = metadata_getnatr(object_uri, n, attr_name, attr_value);
			%_metautil_stop_if_error(metadata_getnatr, n)

			if rc = -4 then
				leave;
			
			attr_name = quote(trim(attr_name));
			attr_value = quote(trim(attr_value));

			if n > 1 then
				put "," @;

			put attr_name ":" attr_value;

			n = n + 1;
		end;
		
		put "}";
	run;
	%if %superq(error_message) ^= %then %do;
		%errhandle_throw_exception(METADATA_ERROR, <&this_macroname.> %superq(error_message))
	%end;
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.> Writing done)
	
%mend metautil_write_result_x_ansible;