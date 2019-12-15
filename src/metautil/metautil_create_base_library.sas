%macro metautil_create_base_library(library_name, library_libref, library_metadata_path, library_physical_path, is_preassigned=0, library_appservers=SASApp);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%local i;
	
	%util_print_log(<&this_macroname.> Creating BASE library &library_name.)
	
	%metautil_create_object({_name : &library_name., 
							 _type: SASLibrary,
							 _folder: "&library_metadata_path.",
							 UsageVersion: "1000000", 
							 PublicType: Library,
							 Engine: BASE,
							 IsPreassigned: &is_preassigned.,
							 Libref: &library_libref.,
							 IsDBMSLibname: 0,
							 UsingPackages(OnetoOne): [{_type: Directory, _name: Dir&library_libref., DirectoryName: "&library_physical_path."}],
							 DeployedComponents: [%do i = 1 %to %sysfunc(countw(&library_appservers., #));
													%if &i. gt 1 %then %do;
													,
													%end;
													
													{_type: ServerContext, _name: "%scan(&library_appservers., &i., #)"}
												  %end;]
							})
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.> Library created successfully)

%mend metautil_create_base_library;