%macro util_add_subdirs_to_sasautos_cb(id=,type=, memname=, level=, parent=,context=,arg=);
	%if &type. = D %then %do;
		%let dirs_to_add = &dirs_to_add. "%fsutil_path_combine(&context., &memname.)";
	%end;	
%mend util_add_subdirs_to_sasautos_cb;

%macro util_add_subdirs_to_sasautos(main_dir, mode);
	%let mode = %upcase(&mode.);

	%if &mode. ^= INSERT and &mode. ^= APPEND %then %do;
		%put ERROR: <&SYSMACRONAME.> Invalid value for MODE parameter, accepted values are INSERT|APPEND;
		%let SYSCC = 5;
		%return;
	%end;

	%local dirs_to_add;
	%let dirs_to_add = "&main_dir.";
	
	%fsutil_dirtree_walk(%superq(main_dir), maxdepth=-1, callback=util_add_subdirs_to_sasautos_cb);

	options &mode.=(sasautos=(&dirs_to_add.));
	
%mend util_add_subdirs_to_sasautos;