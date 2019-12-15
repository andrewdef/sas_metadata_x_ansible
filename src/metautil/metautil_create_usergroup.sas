%macro metautil_create_usergroup(group_name, parent_groups=);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%local i;
	
	%util_print_log(<&this_macroname.> Creating usergroup &group_name.)
	
	%metautil_create_object({_name : &group_name., 
							 _type: IdentityGroup, 
							 UsageVersion: "1000000", 
							 PublicType: UserGroup
							 %if %superq(parent_groups) ^= %then %do;
							 ,IdentityGroups: [%do i = 1 %to %sysfunc(countw(&parent_groups., #));
												%if &i. gt 1 %then %do;
												,
												%end;
												
												{_type: IdentityGroup, _name: "%scan(&parent_groups., &i., #)"}
											  %end;
											 ]
							 %end;
							})
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.> Group created successfully)

%mend metautil_create_usergroup;