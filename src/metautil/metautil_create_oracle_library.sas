%macro metautil_create_oracle_library(library_name, library_libref, library_metadata_path, user_group_name, oracle_service, oracle_server_name, oracle_user, oracle_password, 
										connection_name, oracle_schema=, library_appservers=SASApp);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%local i authdomain;
	%let authdomain = &connection_name.-AuthDomain;
	
	%util_print_log(<&this_macroname.> Creating ORACLE library &library_name.)
	
	%metautil_create_object({_name : &library_name., 
							 _type: SASLibrary,
							 _folder: "&library_metadata_path.",
							 UsageVersion: "1000000", 
							 PublicType: Library,
							 Libref: &library_libref.,
							 IsDBMSLibname: 1,
							 Engine: ORACLE,
							 DefaultLogin(OnetoOne): [{_type: Login, 
													   _name: "Login.&authdomain..&oracle_user.",
													   UserID: &oracle_user.,
													   Password: "&oracle_password.",
													   UsageVersion: "1000000",
													   PublicType: Login,
													   Domain(OnetoOne): [{_type: AuthenticationDomain, _name: &authdomain., OutboundOnly: 0, TrustedOnly:0}],
													   AssociatedIdentity(OnetoOne): [{_type: IdentityGroup, _name: &user_group_name.}]
													  }
													 ],
							 LibraryConnection(OnetoOne): [{_type: SASClientConnection, 
														    _name: &connection_name.,
															Port: 0,
															UsageVersion: 0,
															ApplicationProtocol: OracleProtocol,
															AuthenticationType: "user/password",
															CommunicationProtocol: TCP,
															Properties: [{_type: Property, _name: &connection_name..Connection.Oracle.Property.PATH.Name.xmlKey.txt, PropertyName: PATH, DefaultValue: "&oracle_service.", Delimiter: "="}],
															Domain(OnetoOne): [{_type: AuthenticationDomain, _name: &authdomain., OutboundOnly: 0, TrustedOnly:0}],
															Libraries: [{_name : &library_name., _type: SASLibrary}],
															_parent(SourceConnections): [{_type: ServerComponent, 
																						  _name: &oracle_server_name.,
																						  ProductName: Oracle,
																						  PublicType: "Server.Oracle",
																						  Vendor: "Oracle Corporation",
																						  ClassIdentifier: ORACLE,
																						  UsageVersion: "1000000", 
																						  UsingPrototype(OnetoOne): [{_type: Prototype, _name: Server.Oracle.Prototype.Name.xmlKey.txt}]
																						 }
																						]															
														   }
														  ],
							 UsingPackages(OnetoOne): [{_type: DatabaseSchema, _name: &library_name., UsageVersion: 0, SchemaName: &oracle_schema.}],
							 UsingPrototype(OnetoOne): [{_type: Prototype, _name: Library.Oracle.Prototype.Name.xmlKey.txt}],
							 DeployedComponents: [%do i = 1 %to %sysfunc(countw(&library_appservers., #));
													%if &i. gt 1 %then %do;
													,
													%end;
													
													{_type: ServerContext, _name: "%scan(&library_appservers., &i., #)"}
												  %end;]
							})
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.> Library created successfully)

%mend metautil_create_oracle_library;