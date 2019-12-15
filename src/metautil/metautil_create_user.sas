%macro metautil_create_user(user_name, display_name=, login=, member_of=);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%local i authdomain;
	
	%util_print_log(<&this_macroname.> Creating user &user_name.)
	
	%if %superq(display_name) = %then
		%let display_name = &user_name.;
		
	%let authdomain = DefaultAuth;
	
	%metautil_create_object({_name : &user_name., 
							 _type: Person, 
							 UsageVersion: "1000000", 
							 PublicType: User,
							 DisplayName: "&display_name."
							 %if %superq(login) ^= %then %do;
							 ,Logins: [{_type: Login, 
									   _name: "Login.&authdomain..&user_name.",
									   UserID: &login.,
									   UsageVersion: "1000000",
									   PublicType: Login,
									   Domain(OnetoOne): [{_type: AuthenticationDomain, _name: &authdomain., OutboundOnly: 0, TrustedOnly:0}],
									   AssociatedIdentity(OnetoOne): [{_type: Person, _name: &user_name.}]
									  }]
							 %end;
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
	
	%util_print_log(<&this_macroname.> User created successfully)

%mend metautil_create_user;