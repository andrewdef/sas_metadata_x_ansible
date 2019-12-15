%macro metautil_get_library_info(libref, outds);

	data &outds ;
		attrib lib_id length = $17 label = "Id Libreria";
		attrib lib_name length = $128 label = "Nome Libreria";
		attrib lib_ref length = $8 label = "Libref";
		attrib lib_engine length = $8 label = "Engine Libreria";
		attrib is_dbms_libname length = 8 label = "E' una libreria DBMS?";
		attrib is_pre_assigned length = 8 label = "E' una libreria Pre assegnata?";
		attrib sas_application_servers length = $300;

		attrib property_name length = $32 label = "Nome Attributo";
		attrib property_value length = $100 label = "Valore Attributo";

		attrib lib_uri length = $256 label = "URI SASLibrary";
		attrib deployedComponents_uri length = $256 label = "URI SASLibrary -> DeployedComponents";
		attrib usingPackages_uri length = $256 label = "URI SASLibrary -> UsingPackages";
		attrib properties_uri length = $256 label = "URI SASLibrary -> Properties";
		attrib defaultLogin_uri length = $256 label = "URI SASLibrary -> DefaultLogin";
		attrib libraryConnection_uri length = $256 label = "URI SASLibrary -> LibraryConnection";
		attrib domain_uri length = $256 label = "URI SASLibrary -> LibraryConnection -> Domain";
		attrib logins_uri length = $256 label = "URI SASLibrary -> LibraryConnection -> Domain -> Logins";

		attrib lib_path length = $256;
		attrib lib_schema length = $256;
		attrib slib_ref length = $8;
		attrib userid length = $32;
		attrib password length = $32;
		attrib _is_dbms length = $1;
		attrib _is_pre_assigned length = $1;

		attrib property_string length = $32000;
		attrib this_property length = $500;
		attrib metadata_type length = $32;
		attrib metadata_id length = $32;
		attrib this_application_server length = $32;

		call missing(of _all_);

	%if &libref ne %then %do;
		uri = "omsobj:SASLibrary?@Libref='&libref'";
	%end;
	%else %do;
		uri = "omsobj:SASLibrary?@Id contains '.'";
	%end;

		numSASLibrary = metadata_getnobj(uri, 1, lib_uri);
		do iLib = 1 to numSASLibrary;
			call missing(lib_uri, lib_id, lib_name, lib_ref, lib_engine, _is_dbms, is_pre_assigned, sas_application_servers);
			rc = metadata_getnobj(uri, iLib, lib_uri);
			rc = metadata_getattr(lib_uri, "Id", lib_id);
			rc = metadata_getattr(lib_uri, "Name", lib_name);
			rc = metadata_getattr(lib_uri, "Libref", lib_ref);
			rc = metadata_getattr(lib_uri, "Engine", lib_engine);
			rc = metadata_getattr(lib_uri, "IsDBMSLibname", _is_dbms);
			is_dbms_libname = put(_is_dbms, 8.);

			rc = metadata_getattr(lib_uri, "IsPreassigned", _is_pre_assigned);
			is_pre_assigned = put(_is_pre_assigned, 8.);

			* Read DeployedComponents Association ;
			numDeployedComponents = metadata_getnasn(lib_uri, 'DeployedComponents', 1, deployedComponents_uri);
			do i = 1 to numDeployedComponents;
				call missing(deployedComponents_uri, lib_path);
				rc = metadata_getnasn(lib_uri, 'DeployedComponents', i, deployedComponents_uri);
				rc = metadata_resolve(deployedComponents_uri, metadata_type, metadata_id);
				if compress(metadata_type) = 'ServerContext' then do;
					rc = metadata_getattr(deployedComponents_uri, "Name", this_application_server);
					sas_application_servers = trim(left(sas_application_servers))||'#'||trim(left(this_application_server));
					sas_application_servers = trim(left(sas_application_servers));
				end;
			end;

			if not is_dbms_libname then do;

				* Read UsingPackages Association ;
				numUsingPackages = metadata_getnasn(lib_uri, 'UsingPackages', 1, usingPackages_uri);
				do i = 1 to numUsingPackages;
					call missing(usingPackages_uri, lib_path);
					rc = metadata_getnasn(lib_uri, 'UsingPackages', i, usingPackages_uri);
					rc = metadata_getattr(usingPackages_uri, "DirectoryName", lib_path);

					property_name = "DirectoryName";
					property_value = strip(lib_path);
					output;
				end;

				if lib_engine = 'SPDE' then do;

					* Read Properties Association ;
					numProperties = metadata_getnasn(lib_uri, 'Properties', 1, properties_uri);
					do i = 1 to numProperties;
						call missing(properties_uri, property_name, property_value);
						rc = metadata_getnasn(lib_uri, 'Properties', i, properties_uri);
						rc = metadata_getattr(properties_uri, "PropertyName", property_name);
						rc = metadata_getattr(properties_uri, "DefaultValue", property_value);

						property_name = strip(property_name);
						property_value = strip(property_value);
						output;
					end;
				end;
			end;
			else do;

				* Read UsingPackages Association ;
				numUsingPackages = metadata_getnasn(lib_uri, 'UsingPackages', 1, usingPackages_uri);
				do i = 1 to numUsingPackages;
					call missing(usingPackages_uri, lib_schema);
					rc = metadata_getnasn(lib_uri, 'UsingPackages', i, usingPackages_uri);
					rc = metadata_getattr(usingPackages_uri, "SchemaName", lib_schema);
					rc = metadata_getattr(usingPackages_uri, "Libref", slib_ref);

					property_name = "SchemaName";
					property_value = strip(lib_schema);
					output;

					property_name = "slibref";
					property_value = strip(slib_ref);
					output;
				end;

				* Read DefaultLogin Association ;
				numDefaultLogin = metadata_getnasn(lib_uri, 'DefaultLogin', 1, defaultLogin_uri);
				do i = 1 to numDefaultLogin;
					call missing(defaultLogin_uri, userid, password);
					rc = metadata_getnasn(lib_uri, 'DefaultLogin', i, defaultLogin_uri);
					rc = metadata_getattr(defaultLogin_uri, "Userid", userid);
					rc = metadata_getattr(defaultLogin_uri, "Password", password);

					property_name = "Userid";
					property_value = strip(userid);
					output;
					property_name = "Password";
					property_value = strip(password);
					output;
				end;
				if numDefaultLogin = -3 then do; * No objects match with DefaultLogin URI;

					* Read LibraryConnection Association ;
					numLibraryConnection = metadata_getnasn(lib_uri, 'LibraryConnection', 1, libraryConnection_uri);
					do i = 1 to numLibraryConnection;
						call missing(libraryConnection_uri, domain_uri);
						rc = metadata_getnasn(lib_uri, 'LibraryConnection', i, libraryConnection_uri);

						* Read LibraryConnection -> Domain Association ;
						numDomain = metadata_getnasn(libraryConnection_uri, 'Domain', 1, domain_uri);
						do j = 1 to numDomain;
							call missing(domain_uri, logins_uri);
							rc = metadata_getnasn(libraryConnection_uri, 'Domain', j, domain_uri);

							* Read LibraryConnection -> Domain -> Logins Association ;
							numLogins = metadata_getnasn(domain_uri, 'Logins', 1, logins_uri);
							do k = 1 to numLogins;
								call missing(logins_uri, userid, password);
								rc = metadata_getnasn(domain_uri, 'Logins', k, logins_uri);
								rc = metadata_getattr(logins_uri, "Userid", userid);
								rc = metadata_getattr(logins_uri, "Password", password);

								property_name = "Userid";
								property_value = strip(userid);
								output;
								property_name = "Password";
								property_value = strip(password);
								output;
							end;
						end;
					end;
				end;

				* Read LibraryConnection Association ;
				numLibraryConnection = metadata_getnasn(lib_uri, 'LibraryConnection', 1, libraryConnection_uri);
				do i = 1 to numLibraryConnection;
					rc = metadata_getnasn(lib_uri, 'LibraryConnection', i, libraryConnection_uri);

					* Read LibraryConnection -> Domain Association ;
					numDomain = metadata_getnasn(libraryConnection_uri, 'Domain', 1, domain_uri);
					do j = 1 to numDomain;
						call missing(domain_uri, logins_uri);
						rc = metadata_getnasn(libraryConnection_uri, 'Domain', j, domain_uri);
						rc = metadata_getattr(domain_uri, "PublicType", property_name);
						rc = metadata_getattr(domain_uri, "Name", property_value);

						property_name = coalescec(strip(property_name), 'AuthenticationDomain');
						property_value = strip(property_value);
						output;

						/*
						* Read LibraryConnection -> Domain -> Logins Association ;
						k = 1;
						numLogins = 1;
						do while (k <= numLogins);
							call missing(logins_uri, userid, password);
							rc = metadata_getnasn(domain_uri, 'Logins', k, logins_uri);
							if k = 1 then numLogins = rc;

							if numLogins > 0 then do;
								rc = metadata_getattr(logins_uri, "Userid", userid);
								rc = metadata_getattr(logins_uri, "Password", password);

								property_name = "Userid";
								property_value = strip(userid);
								output;
								property_name = "Password";
								property_value = strip(password);
								output;
							end;

							k+1;
						end;
						*/
					end;

					* Read LibraryConnection -> Properties Association ;
					numProperties = metadata_getnasn(libraryConnection_uri, 'Properties', 1, properties_uri);
					do j = 1 to numProperties;
						rc = metadata_getnasn(libraryConnection_uri, 'Properties', j, properties_uri);
						rc = metadata_getattr(properties_uri, "PropertyName", property_name);
						rc = metadata_getattr(properties_uri, "DefaultValue", property_value);

						property_name = strip(property_name);
						property_value = strip(property_value);
						output;
					end;
				end;

				* Read Properties Association ;
				numProperties = metadata_getnasn(lib_uri, 'Properties', 1, properties_uri);
				do i = 1 to numProperties;
					rc = metadata_getnasn(lib_uri, 'Properties', i, properties_uri);
					rc = metadata_getattr(properties_uri, "PropertyName", property_name);
					rc = metadata_getattr(properties_uri, "DefaultValue", property_string);

					iProp = 1;
					do while(scan(property_string, iProp, " ") ne '');

						this_property = scan(property_string, iProp, " ");
						if index(this_property, '=') > 0 then do;
							property_name = scan(this_property, 1, '=');
							property_value = scan(this_property, 2, '=');
						end;
						else do;
							property_value = property_string;
						end;

						property_name = strip(property_name);
						property_value = strip(property_value);
						output;

						iProp+1;
					end;
				end;
			end;
		end;

		keep lib_id lib_name lib_ref lib_engine is_dbms_libname is_pre_assigned 
			sas_application_servers property_name property_value;
	run;

%mend metautil_get_library_info;