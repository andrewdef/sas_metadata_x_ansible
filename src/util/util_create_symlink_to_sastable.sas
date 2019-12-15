%macro util_create_symlink_to_sastable(source_table, destination_table);
	%local this_macroname source_lib source_tablename dest_lib dest_tablename;
	%let this_macroname = &SYSMACRONAME.;
	
	%if %index(&source_table., .) %then %do;
		%let source_lib = %scan(&source_table., 1, .);
		%let source_tablename = %scan(&source_table., 2, .);
	%end;
	%else %do;
		%let source_lib = work;
		%let source_tablename = &source_table.;
	%end;
	
	%if %index(&destination_table., .) %then %do;
		%let dest_lib = %scan(&destination_table., 1, .);
		%let dest_tablename = %scan(&destination_table., 2, .);
	%end;
	%else %do;
		%let dest_lib = work;
		%let dest_tablename = &destination_table.;
	%end;
	
	%sysutil_create_symbolic_link(%fsutil_path_combine(%sysfunc(pathname(&source_lib.)), %lowcase(&source_tablename..sas7bdat)), 
									%fsutil_path_combine(%sysfunc(pathname(&dest_lib.)), %lowcase(&dest_tablename..sas7bdat)))
	%if &SYSCC. > 4 %then %do;
		%errhandle_throw_exception(<&this_macroname.> Error while creating link to table &destination_table.);
		%return;
	%end;
	
%mend util_create_symlink_to_sastable;