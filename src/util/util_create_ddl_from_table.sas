%macro util_create_ddl_from_table(input_table, output_file);
	%local input_libname input_ds_name_only dsid nvars this_macroname;
	%let this_macroname = &SYSMACRONAME.;

	%macro fsutil_get_dir(fullpath);
		%local path_sep index ret_value fullpath_length;
		%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
	        %let path_sep = %str(\);
	    %end;
	    %else %do;
	        %let path_sep = %str(/);
	    %end;
		
		%let fullpath_length = %length(%superq(fullpath));
		%if %qsubstr(%superq(fullpath), &fullpath_length., 1) = &path_sep. %then
			%let fullpath_length = %eval(&fullpath_length. - 1);
			
		%let index = %sysfunc(find(%superq(fullpath), &path_sep., -&fullpath_length.));
		%if &index. > 0 %then %do;
			%let ret_value = %qsubstr(%superq(fullpath), 1, &index.);
		%end;
		%else %do;
			%let ret_value =;
		%end;
		
		%superq(ret_value)

	%mend fsutil_get_dir;


	%if not %sysfunc(exist(&input_table.)) %then %do;
		%put ERROR: <&this_macroname.> Input table &input_table. does not exist;
		%let SYSCC = 5;
		%return;
	%end;
	%else %if not %sysfunc(fileexist(%fsutil_get_dir(&output_file.))) %then %do;
		%put ERROR: <&this_macroname.> Output directory %fsutil_get_dir(&output_file.) does not exist;
		%let SYSCC = 5;
		%return;
	%end;
	
	%if %index(&input_table., .) %then %do;
		%let input_libname = %scan(&input_table., 1, .);
		%let input_ds_name_only = %scan(&input_table., 2, .);
	%end;
	%else %do;
		%let input_libname = work;
		%let input_ds_name_only = &input_table.;
	%end;
	
	proc contents data=&input_table. out=cont noprint;
	run;
	%if &SYSCC. > 4 %then %return;
	
	proc sql noprint;
		create table cont_sorted as
		select VARNUM
			  ,NAME
			  ,TYPE
			  ,LENGTH
			  ,case
			   		when FORMAT = "" then ""
					when FORMATL = 0 then cats(FORMAT, '.')
					when FORMATD = 0 then cats(FORMAT, put(FORMATL, 2.), '.')
					else cats(FORMAT, put(FORMATL, 2.), '.', put(FORMATD, 2.))
			   end as FORMAT length=64
			  ,case 
			   		when INFORMAT = "" then ""
					when INFORML = 0 then cats(INFORMAT, '.')
					when INFORMD = 0 then cats(INFORMAT, put(INFORML, 2.), '.')
					else cats(INFORMAT, put(INFORML, 2.), '.', put(INFORMD, 2.))
			   end as INFORMAT length=64
		from cont
		order by VARNUM;
	quit;
	%if &SYSCC. > 4 %then %return;
	
	data _null_;
		set &input_table. end=last;
		file "&output_file.";

		if _N_ = 1 then do;
			put "libname &input_libname. ""%sysfunc(pathname(&input_libname.))"";";
			put;
			put "data &input_table.;";
			put '09'x "length" @;
			%let dsid = %sysfunc(open(cont_sorted));			
			%syscall set(dsid);
			%do %while( %sysfunc(fetch(&dsid.)) = 0);
			put " %trim(&NAME.) %sysfunc(ifc(&TYPE. = 1, , $)) &LENGTH." @ ;
			%end;
			%let dsid = %sysfunc(close(&dsid.));
			put ";";

			put;
			put '09'x "infile datalines dlm='#' dsd;";

			%let dsid = %sysfunc(open(cont_sorted(where=(FORMAT ^= ''))));
			%let nvars = %sysfunc(attrn(&dsid., NLOBSF));
			%if &nvars. > 0 %then %do;
				put '09'x "format" @;
				%syscall set(dsid);
				%do %while( %sysfunc(fetch(&dsid.)) = 0);
				put " %trim(&NAME.) %lowcase(%trim(&FORMAT.))" @ ;
				%end;
				put ";";
			%end;
			%let dsid = %sysfunc(close(&dsid.));

			%let dsid = %sysfunc(open(cont_sorted(where=(INFORMAT ^= ''))));
			%let nvars = %sysfunc(attrn(&dsid., NLOBSF));
			%if &nvars. > 0 %then %do;
				put '09'x "informat" @;
				%syscall set(dsid);
				%do %while( %sysfunc(fetch(&dsid.)) = 0);
				put " %trim(&NAME.) %lowcase(%trim(&INFORMAT.))" @ ;
				%end;
				put ";";
			%end;
			%let dsid = %sysfunc(close(&dsid.));
			
			put;
			put '09'x "input" @;
			%let dsid = %sysfunc(open(cont_sorted));
			%syscall set(dsid);
			%do %while( %sysfunc(fetch(&dsid.)) = 0);
			put " %trim(&NAME.)" @ ;
			%end;
			%let dsid = %sysfunc(close(&dsid.));
			put ";";
			put "cards4;";
		end;		
		
		%let dsid = %sysfunc(open(cont_sorted));
		%let nvars = %sysfunc(attrn(&dsid., NOBS));
		%syscall set(dsid);
		%do %while( %sysfunc(fetch(&dsid.)) = 0);
		put &NAME. :&INFORMAT. +(-1) %if &VARNUM. ^= &nvars. %then %do; '#' @ %end; ;
		%end;
		%let dsid = %sysfunc(close(&dsid.));		
		
		if last then do;
			put ";;;;";
			put "run;";
		end;		
	run;	
	
%mend util_create_ddl_from_table;
