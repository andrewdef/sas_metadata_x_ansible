%macro metautil_set_object_structure(object_uri, association_to_create_tab, attributes_to_assign_tab);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;
	
	%local object_was_changed;
	%let object_was_changed = 0;
	
	%local this_call_sequence;
	%let this_call_sequence = &call_sequence.;
	
	%if %util_get_nobs(&attributes_to_assign_tab.) > 0 %then %do;
		%util_print_log(<&this_macroname.-&this_call_sequence.> Setting object attributes)
		
		%local error_message;
		data _null_;
			set &attributes_to_assign_tab. end=last;
			
			length object_uri $256 object_was_changed 8 existing_attr_value $ 128;
			retain object_uri "" object_was_changed 0;
			
			object_uri = "&object_uri.";
			
			call missing(existing_attr_value);
			rc = metadata_getattr(object_uri, ATTRIBUTE_NAME, existing_attr_value);

			if rc = -2 or (rc = 0 and existing_attr_value ^= ATTRIBUTE_VALUE) then do;
				rc = metadata_setattr(object_uri, ATTRIBUTE_NAME, ATTRIBUTE_VALUE);
				%_metautil_stop_if_error(metadata_setattr, ATTRIBUTE_NAME)
				
				object_was_changed = object_was_changed + 1;
				rc = 0;
			end;
			%_metautil_stop_if_error(metadata_getattr, ATTRIBUTE_NAME)

			if last then do;
				call symputx("object_was_changed", object_was_changed + &object_was_changed.);
			end;
		run;
		%if %superq(error_message) ^= %then %do;
			%errhandle_throw_exception(METADATA_ERROR, <&this_macroname.-&this_call_sequence.> %superq(error_message))
		%end;
		%if &SYSCC. > 4 %then %return;
		
		%util_print_log(<&this_macroname.-&this_call_sequence.> Attributes set)
	%end;
	%else %do;
		%util_print_log(<&this_macroname.-&this_call_sequence.> No attributes were specified for the object)
	%end;
	
	%local i association_name association_type association_object;
	
	%let call_sequence = %eval(&call_sequence. + 1);

	%do i = 1 %to %util_get_nobs(&association_to_create_tab.);
		data _null_;
			set &association_to_create_tab.(where=(ASSOCIATION_ID = &i.));
			
			call symputx('association_name', ASSOCIATION_NAME, 'L');
			call symputx('association_type', ASSOCIATION_TYPE, 'L');
			call symputx('association_object', ASSOCIATION_OBJECT, 'L');
		run;
		%if &SYSCC. > 4 %then %return;
		
		%metautil_create_association(&object_uri., &association_name., &association_type., %superq(association_object))
		%if &SYSCC. > 4 %then %return;
		
		%let object_was_changed = %eval(&object_was_changed. + &_METAUTIL_LAST_OBJECT_WAS_CHANGD.);
	%end;

	%global _METAUTIL_LAST_OBJECT_WAS_CHANGD;
	%let _METAUTIL_LAST_OBJECT_WAS_CHANGD = &object_was_changed.;
	
%mend metautil_set_object_structure;