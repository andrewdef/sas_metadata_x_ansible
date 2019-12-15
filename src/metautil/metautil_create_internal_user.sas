%macro metautil_create_internal_user(user_name, password, metadata_password, display_name=, member_of=);
	%local this_macroname metadata_host metadata_port metadata_user;
	%let this_macroname = &SYSMACRONAME.;

	%local i authdomain;
	
	/* Remove the @saspw and the end of the username, if present */
	%if %index(&user_name., @saspw) %then
		%let user_name = %substr(&user_name., 1, %eval(%index(&user_name., @saspw) - 1));
	
	%util_print_log(<&this_macroname.> Creating internal user &user_name.)
	
	%if %superq(display_name) = %then
		%let display_name = &user_name.;
		
	%let authdomain = DefaultAuth;
	
	%metautil_create_object({_name : &user_name., 
							 _type: Person, 
							 UsageVersion: "1000000", 
							 PublicType: User,
							 DisplayName: "&display_name."
							 %if %superq(member_of) ^= %then %do;
							 ,IdentityGroups: [%do i = 1 %to %sysfunc(countw(&member_of., #));
												%if &i. gt 1 %then %do;
												,
												%end;
												
												{_type: IdentityGroup, _name: "%scan(&member_of., &i., #)"}
											  %end;
											 ]
							 %end;
							})
	%if &SYSCC. > 4 %then %return;
	
	%let metadata_host = %sysfunc(getoption(METASERVER));
	%let metadata_port = %sysfunc(getoption(METAPORT));
	%let metadata_user = %sysfunc(getoption(METAUSER));
	
	%util_print_log(<&this_macroname.> &=metadata_host. &=metadata_port. &=metadata_user.)
	
	%metautil_set_internal_user_pwd(&user_name., %superq(password), &metadata_host., &metadata_port., &metadata_user., &metadata_password.)
	
	%util_print_log(<&this_macroname.> User created successfully)

%mend metautil_create_internal_user;