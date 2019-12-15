%macro _metautil_parse_object_string / PARMBUFF;
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%local association_to_create_tab parent_to_create_tab attributes_to_assign_tab validation_errors regexp_id quoted_paramstring has_parent
		   object_name object_type object_folder object_main_info_tab;
	
	%let quoted_paramstring = %superq(SYSPBUFF);
	
	%let regexp_id = %sysfunc(prxparse(/\(\s*([\da-z_]+?)\s*%str(,)\s*([\da-z_]+?)\s*%str(,)\s*([\da-z_]+?)\s*%str(,)\s*([\da-z_]+?)\s*%str(,)\s*(.+)\)/));
	%if %sysfunc(prxmatch(&regexp_id., &quoted_paramstring.)) %then %do;
		%let association_to_create_tab = %sysfunc(prxposn(&regexp_id., 1, &quoted_paramstring.));
		%let attributes_to_assign_tab = %sysfunc(prxposn(&regexp_id., 2, &quoted_paramstring.));
		%let parent_to_create_tab = %sysfunc(prxposn(&regexp_id., 3, &quoted_paramstring.));
		%let object_main_info_tab = %sysfunc(prxposn(&regexp_id., 4, &quoted_paramstring.));
	%end;
	%else %do;
		%errhandle_throw_exception(INVALID_ARGUMENT, <&this_macroname.> Macro arguments are not in the format (association_to_create_tab%str(,)attributes_to_assign_tab%str(,)parent_to_create_tab%str(,)object_main_info_tab%str(,)object_string))
		%return;
	%end;
	
	%let validation_errors = 0;
	data &association_to_create_tab.(keep=ASSOCIATION_ID ASSOCIATION_NAME ASSOCIATION_TYPE ASSOCIATION_OBJECT)
		 &parent_to_create_tab.(keep=ASSOCIATION_NAME ASSOCIATION_TYPE ASSOCIATION_OBJECT)
		 &attributes_to_assign_tab.(keep=ATTRIBUTE_NAME ATTRIBUTE_VALUE)
		 &object_main_info_tab.(keep=ATTRIBUTE_NAME ATTRIBUTE_VALUE);
		
		length json $ 32767;
		json = strip(symget("SYSPBUFF"));
		
		index_of_open_bracket = index(json, '{');
		index_of_closed_bracket = find(json, '}', 't', -50000);
		if index_of_open_bracket = 0 or index_of_closed_bracket = 0 or index_of_closed_bracket < index_of_open_bracket then do;
			put "ERROR: <&this_macroname.-&this_call_sequence.> Input json must be enclosed in {}";
			call symputx('validation_errors', '1');
			stop;
		end;
		
		json = substr(json, index_of_open_bracket + 1, index_of_closed_bracket - index_of_open_bracket - 1); 

		length object_name object_type $ 128 object_folder $ 1024;
		length ATTRIBUTE_NAME $ 128 ATTRIBUTE_VALUE $ 128;
		length ASSOCIATION_ID 8 ASSOCIATION_NAME $ 128 ASSOCIATION_TYPE $ 32 ASSOCIATION_OBJECT $ 4096;
		length left_side $ 128;
		
		is_in_array = 0;
		is_in_object = 0;
		is_in_quotes = 0;

		ASSOCIATION_ID = 0;
		
		call missing(object_name, object_type, object_folder);

		last_starting_position = 1;
		
		length c $ 1;
		do i = 1 to length(json);
			c = substr(json, i, 1);
			
			if c = '"' then
				is_in_quotes = (not is_in_quotes);
			if is_in_quotes then
				goto continue;
			
			if c = '{' then do;
				is_in_object = is_in_object + 1;

				if is_in_object = 1 then
					last_starting_position = i;
			end;
			else if c = '[' then 
				is_in_array = is_in_array + 1;
			else if c = ':' then do;
				if not is_in_array and not is_in_object then do;
					left_side = strip(dequote(substr(json, last_starting_position, i - last_starting_position)));
					last_starting_position = i + 1;
				end;
			end;
			else if c = ']' then do;
				is_in_array = is_in_array - 1;

				if not is_in_array then
					left_side = "";
			end;
			else if c = '}' then do;
				is_in_object = is_in_object - 1;
				
				if not is_in_object then do;
					ASSOCIATION_ID = ASSOCIATION_ID + 1;
					ASSOCIATION_NAME = scan(strip(dequote(left_side)), 1, '(' );
					ASSOCIATION_TYPE = tranwrd(scan(strip(dequote(left_side)), 2, '(' ), ')', '');
					ASSOCIATION_OBJECT = strip(dequote(substr(json, last_starting_position, i - last_starting_position + 1)));
					
					if lowcase(ASSOCIATION_NAME) = "_parent" then
						output &parent_to_create_tab.;
					else
						output &association_to_create_tab.;
				end;	
			end;
			else if c = ',' or i = length(json) then do;
				if not is_in_array and not is_in_object then do;
					if i = length(json) then
						ending_position = i + 1 - last_starting_position;
					else
						ending_position = i - last_starting_position;

					if left_side ^= "" then do;
						ATTRIBUTE_NAME = strip(dequote(left_side));
						ATTRIBUTE_VALUE = dequote(strip(substr(json, last_starting_position, ending_position)));
						
						if lowcase(ATTRIBUTE_NAME) in ('_name', '_type', '_folder') then
							output &object_main_info_tab.;
						else
							output &attributes_to_assign_tab.;
						
						left_side = "";
					end;					
					
					last_starting_position = i + 1;
				end;
			end;
			
			continue:
		end;
		
		if is_in_object ^= 0 then do;
			put "ERROR: <&this_macroname.-&this_call_sequence.> Mismatched curly brackets in json";
			call symputx('validation_errors', '1');
			stop;
		end;
		if is_in_array ^= 0 then do;
			put "ERROR: <&this_macroname.-&this_call_sequence.> Mismatched square brackets in json";
			call symputx('validation_errors', '1');
			stop;
		end;
	run;
	%if &SYSCC. > 4 or &validation_errors. %then %do;
		%let SYSCC = 5;
		%return;
	%end;
	
	%let has_parent = %util_get_nobs(&parent_to_create_tab.);
	
	data _null_;
		set &object_main_info_tab.;
		
		if ATTRIBUTE_NAME = '_name' then
			call symputx("object_name", ATTRIBUTE_VALUE);
		else if ATTRIBUTE_NAME = '_type' then
			call symputx("object_type", ATTRIBUTE_VALUE);
		else if ATTRIBUTE_NAME = '_folder' then
			call symputx("object_folder", ATTRIBUTE_VALUE);
	run;
	%if &SYSCC. > 4 %then %return;
	
	%if "&object_name." = "" %then %do;
		%errhandle_throw_exception(NO_OBJECTNAME_SPECIFIED, <&this_macroname.-&this_call_sequence.> Attribute _name must be specified in the input json)
		%return;
	%end;
	%else %if "&object_type." = "" %then %do;
		%errhandle_throw_exception(NO_OBJECTTYPE_SPECIFIED, <&this_macroname.-&this_call_sequence.> Attribute _type must be specified in the input json)
		%return;
	%end;
	%else %if "&object_folder." ^= "" and &has_parent. %then %do;
		%errhandle_throw_exception(INVALID_PARENT, <&this_macroname.-&this_call_sequence.> An object cannot have both a _folder and a _parent at the same time)
		%return;
	%end;	
	%else %if &has_parent. > 1 %then %do;
		%errhandle_throw_exception(INVALID_PARENT, <&this_macroname.-&this_call_sequence.> An object cannot have multiple parents)
		%return;
	%end;	
	
%mend _metautil_parse_object_string;