%macro metautil_create_netezza_library(library_name, library_libref, library_metadata_path, server_name, user_group_name, netezza_host, netezza_user, netezza_password, 
										netezza_db, netezza_schema, connection_name, netezza_port=5480, is_preassigned=0, library_appservers=SASApp);
	%local this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%local i authdomain;
	%let authdomain = &connection_name.-AuthDomain;
	
	%util_print_log(<&this_macroname.> Creating NETEZZA library &library_name.)
	
	%metautil_create_object({_name : &library_name., 
							 _type: SASLibrary,
							 _folder: "&library_metadata_path.",
							 UsageVersion: "1000000", 
							 PublicType: Library,
							 Libref: &library_libref.,
							 IsDBMSLibname: 1,
							 Engine: NETEZZA,
							 IsPreassigned: &is_preassigned.,
							 LibraryConnection(OnetoOne): [{_type: SASClientConnection, 
														    _name: &connection_name.,
															Port: 0,
															UsageVersion: 0,
															ApplicationProtocol: NetezzaPROTOCOL,
															AuthenticationType: "user/password",
															CommunicationProtocol: TCP,
															UsingPrototype(OnetoOne): [{_type: Prototype, _name: Connection.Netezza.Prototype.Name.xmlKey.txt}],
															Properties: [{_type: Property, _name: &connection_name..Netezza.SERVER, SQLType: 12, PropertyName: SERVER, DefaultValue: "&netezza_host.", Delimiter: "="},
																		 {_type: Property, _name: &connection_name..Netezza.NPORT, SQLType: 12, PropertyName: PORT, DefaultValue: "&netezza_port.", Delimiter: "="}
																		],
															Domain(OnetoOne): [{_type: AuthenticationDomain, _name: &authdomain., OutboundOnly: 0, TrustedOnly:0}],
															Libraries: [{_name : &library_name., _type: SASLibrary}],
															_parent(SourceConnections): [{_type: ServerComponent, 
																						  _name: &server_name.,
																						  ProductName: Netezza,
																						  PublicType: "Server.Netezza",
																						  Vendor: "IBM Corporation",
																						  ClassIdentifier: Netezza,
																						  UsageVersion: "1000000", 
																						  UsingPrototype(OnetoOne): [{_type: Prototype, _name: Server.Netezza.Prototype.Name.xmlKey.txt}]
																						 }
																						]															
														   }
														  ],
							 Properties: [{_type: Property, _name: &library_name..Netezza.DB, SQLType: 12, PropertyName: DATABASE, DefaultValue: "&netezza_db.", Delimiter: "="},
										  {_type: Property, _name: &library_name..Library.UTILCONN_TRANSIENT, SQLType: 12, PropertyName: UTILCONN_TRANSIENT, DefaultValue: "YES", Delimiter: "="}
										 ],
							 UsingPackages(OnetoOne): [{_type: DatabaseSchema, _name: &library_name., UsageVersion: 0, SchemaName: &netezza_schema.}],
							 UsingPrototype(OnetoOne): [{_type: Prototype, _name: Library.Netezza.Prototype.Name.xmlKey.txt}],
							 DefaultLogin(OnetoOne): [{_type: Login, 
													   _name: "Login.&authdomain..&netezza_user.",
													   UserID: &netezza_user.,
													   Password: "&netezza_password.",
													   UsageVersion: "1000000",
													   PublicType: Login,
													   Domain(OnetoOne): [{_type: AuthenticationDomain, _name: &authdomain., OutboundOnly: 0, TrustedOnly:0}],
													   AssociatedIdentity(OnetoOne): [{_type: IdentityGroup, _name: &user_group_name.}]
													  }
													 ],
							 DeployedComponents: [%do i = 1 %to %sysfunc(countw(&library_appservers., #));
													%if &i. gt 1 %then %do;
													,
													%end;
													
													{_type: ServerContext, _name: "%scan(&library_appservers., &i., #)"}
												  %end;]
							})
	%if &SYSCC. > 4 %then %return;
	
	%util_print_log(<&this_macroname.> Library created successfully)

%mend metautil_create_netezza_library;