%macro metautil_set_internal_user_pwd(user_name, password_to_set, metahost, metaport, metauser, metapassword);
	%local path_sep javapath this_macroname classpath_for_groovy i REQUIRED_JARS classpath_sep jar_path jar_name;

	%let REQUIRED_JARS = sas.oma.joma.jar sas.oma.joma.rmt.jar sas.oma.omi.jar sas.svc.connection.jar sas.core.jar sas.entities.jar sas.security.sspi.jar log4j.jar;

	%let this_macroname = &SYSMACRONAME.;

	%let javapath = %sysget(METAUTIL_JAVAPATH);
	%if %superq(javapath) = %then %do;
		%errhandle_throw_exception(METAUTIL_JAVAPATH_NOT_SET_EXCEPTION, <&this_macroname.> Environment variable METAUTIL_JAVAPATH has not been set);
		%errhandle_throw_exception(METAUTIL_JAVAPATH_NOT_SET_EXCEPTION, <&this_macroname.> It must point to a folder containing the groovy script );
		%return;
	%end;

	%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
		%let path_sep = %str(\);
		%let classpath_sep = %str(;);
	%end;
	%else %do;
		%let path_sep = %str(/);
		%let classpath_sep = %str(:);
	%end;
	
	%macro find_jar_in_sasjarrepository(jar_name, return_var, root_path_for_jars=);
	
		%if %superq(root_path_for_jars) = %then %do;
			%let regexp_id = %sysfunc(prxparse(/-Djava\.class\.path=([^\s]+)/));
			%if %sysfunc(prxmatch(&regexp_id., %sysfunc(getoption(JREOPTIONS)))) %then %do;
				%let root_path_for_jars = %sysfunc(prxposn(&regexp_id., 1, %sysfunc(getoption(JREOPTIONS))));
			%end;
			
			%if %superq(root_path_for_jars) = %then %do;
				%errhandle_throw_exception(JAR_ROOT_PATH_NOT_FOUND_EXCEPTION, <&this_macroname.> Cannot find SAS Versioned Jar Repository path in the JREOPTIONS);
				%return;
			%end;

			%let root_path_for_jars = %fsutil_get_dir(&root_path_for_jars.);
			
			%util_print_log(<&this_macroname.> Using &root_path_for_jars. as path for the SAS Versioned Jar Repository)
		%end;
		
		%if not %sysfunc(exist(all_jar_folders)) %then %do;
			%macro is_directory(memname_var, out_var);
				rc_check = filename("dircheck", &memname_var.);
				did_check = dopen("dircheck");

				if did_check = 0 then
					&out_var. = 0;
				else
					&out_var = 1;
					
				did_check = dclose(did_check);
				rc_check = filename("dircheck");
			%mend is_directory;
			
			%macro check_error(condition);
				if &condition. then do;
					error_message = sysmsg();
					put "ERROR: <&this_macroname.> " error_message;
					call symputx('processing_errors', '1');
					
					stop;
				end;
			%mend check_error;
			
			%let processing_errors = 0;
			data all_jar_folders;
				length member_fullpath current_dir $ 4096 current_dir_index max_dir_to_process_index 8 memname error_message $ 256;
				
				length jar_name $ 256 jar_path $ 4096;
				keep jar_name jar_path priority;

				if _N_ = 1 then do;					
					declare hash dirs_to_process();
					dirs_to_process.defineKey("current_dir_index");
					dirs_to_process.defineData("current_dir");
					dirs_to_process.defineDone();
				end;
				
				current_dir = symget('root_path_for_jars');
				current_dir_index = 0;
				
				max_dir_to_process_index = 0;
				
				do while ( current_dir ^= "" );
					rc = filename("currdir", current_dir);
					%check_error(rc ne 0)
					
					did = dopen("currdir");
					%check_error(did eq 0)
					
					do i = 1 to dnum(did);
						memname = dread(did, i);				
						member_fullpath = catx('/', current_dir, memname);
						
						%is_directory(member_fullpath, member_is_directory)
						
						if member_is_directory then do;
							if memname ^= 'META-INF' then do;
								max_dir_to_process_index = max_dir_to_process_index + 1;
								dirs_to_process.add(key: max_dir_to_process_index, data: member_fullpath);
							end;
						end;
						else do;
							if scan(memname, -1, '.') = 'jar' then do;
								jar_name = memname;
								jar_path = member_fullpath;
								priority = current_dir_index;
								
								output;
							end;
						end;
					end;
					
					did = dclose(did);
					rc = filename("currdir");
					
					current_dir_index = current_dir_index + 1;			
					rc = dirs_to_process.find();
					if rc ^= 0 then
						current_dir = "";
				end;
			run;
			%if &processing_errors. or &SYSCC. > 5 %then %do;
				%let SYSCC = 5;
				%return;
			%end;
			
			proc sql noprint;
				create table all_jar_folders as
				select *
				from all_jar_folders
				group by JAR_NAME
				having PRIORITY = max(PRIORITY);
			quit;
			%if &SQLRC. > 4 %then
				%return;
		%end;
		
		data _null_;
			set all_jar_folders;
			
			where JAR_NAME = "&jar_name.";
			
			call symputx("&return_var.", JAR_PATH);
		run;
		%if &SYSCC. > 5 %then
			%return;

	%mend find_jar_in_sasjarrepository;

	%do i = 1 %to %sysfunc(countw(%superq(REQUIRED_JARS), %str( )));
		%let jar_name = %scan(%superq(REQUIRED_JARS), &i., %str( ));
		%let jar_path = &javapath.&path_sep.lib&path_sep.&jar_name.;
		
		%if not %sysfunc(fileexist(&jar_path.)) %then %do;
			%let jar_path =;
			%find_jar_in_sasjarrepository(&jar_name., jar_path)
		%end;
		
		%if %superq(jar_path) = %then %do;
			%errhandle_throw_exception(JAR_NOT_FOUND_EXCEPTION, <&this_macroname.> Cannot find jar &jar_name. in either &javapath.&path_sep.lib or SAS Versioned Jar Repository);
			%return;
		%end;
		%else %if not %sysfunc(fileexist(&jar_path.)) %then %do;
			%errhandle_throw_exception(JAR_NOT_FOUND_EXCEPTION, <&this_macroname.> The path found for jar &jar_name. is incorrect%str(,) the file &jar_path. does not exist);
			%return;
		%end;
		
		%let classpath_for_groovy = &classpath_for_groovy.&jar_path.&classpath_sep.;
	%end;

	%if not %sysfunc(fileexist(&javapath.&path_sep.internal_user_pwd_setter.groovy)) %then %do;
		%errhandle_throw_exception(METAUTIL_JAVAPATH_NOT_SET_EXCEPTION, <&this_macroname.> Check that internal_user_pwd_setter.groovy exists in path &javapath.);
		%return;
	%end;

	proc groovy classpath="&classpath_for_groovy.";
		execute parseonly "&javapath.&path_sep.internal_user_pwd_setter.groovy";
	quit;	
	%if &SYSCC. > 4 %then %do;
		%errhandle_throw_exception(MDBREADER_GROOVY_EXCEPTION, <&this_macroname.> An error was found while compiling class InternalUserPwdSetter);
		%return;
	%end;
	
	%util_print_log( <&this_macroname.> Begin setting password for internal user &user_name.);
	
	%let has_raised_exception = 0;
	data _null_;
		declare javaobj pwdSetter("InternalUserPwdSetter", "&metahost.", "&metaport.", "&metauser.", "&metapassword.");
		length has_raised_exception 8;
		
		pwdSetter.exceptionDescribe(1);
		pwdSetter.callVoidMethod("setPassword", "&user_name.", "&password_to_set.");
		rc = pwdSetter.exceptionCheck(has_raised_exception);
		
		call symputx('has_raised_exception', has_raised_exception);
	run;	
	%if &SYSCC. > 4 or &has_raised_exception. %then %do;
		%errhandle_throw_exception(SET_PASSWORD_EXCEPTION, <&this_macroname.> An error was found while setting the password for the user);
		%return;
	%end;
	%else %do;
		/* This is to suppress warnings from the Java classes */
		%let SYSCC = 0;
	%end;
	
	%util_print_log( <&this_macroname.> Password set successfully);

%mend metautil_set_internal_user_pwd;