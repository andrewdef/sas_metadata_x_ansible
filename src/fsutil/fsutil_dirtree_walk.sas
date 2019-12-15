/** 
* Used to walk a filesystem tree. The callback macro provided is invoked at each leaf node of the tree.
* This macro must have the following signature:
*    %<callback_macro_name>(id=,type=, memname=, level=,parent=);
* where:
*    id is a unique id for the leaf
*    type is F if leaf is a file, D if it's a directory
*	 memname is the name of the leaf (file name or directory name)
*	 level is the tree depth of the leaf
*	 parent is the id of the parent directory
*	 context is the path of the parent directory
*	 arg is the same optional argument supplied to the fsutil_dirtree_walk macro
* The callback macro must return 1 if it executed successfully, 0 if there was an error.
* 
* If the callback returns 0 or an error is detected by checking SYSCC, the macro stops traversing the tree.
* The optional arguments dirname_regexp and filename_regexp are regular expressions that can be used to select 
* to which file or directories the callback is applied, more specifically:
* 	- if a filename_regexp is supplied, the callback is called only on those file that match filename_regexp
*	- if a dirname_regexp is supplied, the macro does not traverse directories whose name does not match dirname_regexp,
*	  meaning that all files and subdirs contained therein are ignored
*
* @param root directory to walk
* @param dirname_regexp regexp to select the names of subdirs to traverse (default: none)
* @param filename_regexp regexp to select the names of files to apply the callback (default: none)
* @param callback name of the macro to be invoken on each leaf
* @param maxdepth maximum recursion depth (default: 1)
* @param arg optional argument to be supplied to the callback macro (default: none)
*/

%macro fsutil_dirtree_walk(root, dirname_regexp=, filename_regexp=, callback=walk_callback, maxdepth=1,arg=);
	%local dir_regexp_id filename_regexp_id id;
	%let id=0;
	
	%if "%superq(dirname_regexp)" ^= "" %then
		%let dir_regexp_id = %sysfunc(prxparse(%superq(dirname_regexp)));
	%else
		%let dir_regexp_id = -1;
	
	%if "%superq(filename_regexp)" ^= "" %then
		%let filename_regexp_id = %sysfunc(prxparse(%superq(filename_regexp)));
	%else
		%let filename_regexp_id = -1;
		
	%fsutil_dirtree_walk_p(%superq(root), %superq(root), 1, &id, &dir_regexp_id., &filename_regexp_id., maxdepth=&maxdepth, callback=&callback,arg=&arg);
%mend;
   
%macro walk_callback(id=,type=, memname=, level=,parent=, context=,arg=);
	%put inside callback : id=&id, type=&type, memname=&memname, level=&level, context=&context, arg=&arg;
%mend;

%macro fsutil_dirtree_walk_p(source, root, level, parentId, dir_regexp_id, filename_regexp_id, maxdepth=, callback=, arg=);

	%local parentId isDirectory did did2 dnum i mid level rc memname root fref fref_t callback_result path_sep;

   	%if &SYSSCP eq WIN or &SYSSCP eq DNTHOST %then %do;
        %let path_sep = %str(\);
    %end;
    %else %do;
        %let path_sep = %str(/);
    %end;

	/* Open the directory named in the root variable */
	%let rc = %sysfunc(filename(fref, &root.));   
	%let did = %sysfunc(dopen(&fref));

	%if &did = 0 %then
		%goto theend;

	/* Iterate over all the directory entries */
	%let dnum = %sysfunc(dnum(&did));
	%do i = 1 %to &dnum;
	  
		%let memname = %qsysfunc(dread(&did, &i));
		%let isDirectory = %fsutil_is_directory(&root.&path_sep.&memname.);
											 
		%if &isDirectory %then %do;
			%let id = %eval(&id+1);
			
			%if &dir_regexp_id. ^= -1 %then %do;
				%let relative_path = %fsutil_get_relative_path(%superq(root)&path_sep.%superq(memname), %superq(source));
				%if not %sysfunc(prxmatch(&dir_regexp_id., %superq(relative_path))) %then
					%goto continue;
			%end;
		
			/* If we have not reached the limits of recursion specified, 
			invoke the macro on this subdirectory */

			%if &maxdepth = &level %then %do;
				%goto continue;
			%end;
			%else %do;
				%fsutil_dirtree_walk_p(&source., &root.&path_sep.&memname., %eval(&level+1), &id, &dir_regexp_id., &filename_regexp_id., maxdepth=&maxdepth, callback=&callback,arg=&arg);
			%end;
			
			%if &callback ne %then %do;
				%let callback_result = %&callback(id=&id, type=D, memname=&memname., level=&level, parent=&parentId, context=&root., arg=&arg);
			%end;
			%else %do;
				%put parent=&parentId, member=&memname, level=&level, type=D;
			%end;
			%if &SYSCC. > 4 or &callback_result. = 0 %then %goto theend;
		%end;
		%else %do;
			%if &filename_regexp_id. ^= -1 %then %do;
				%if not %sysfunc(prxmatch(&filename_regexp_id., %superq(memname))) %then
					%goto continue;
			%end;
		
			%if &callback ne %then %do;
				%let callback_result = %&callback(id=., type=F, memname=&memname., level=&level, parent=&parentId, context=&root.,arg=&arg);
			%end;
			%else %do;
				%put parent=&parentId, member=&memname, level=&level, type=F;
			%end;
			%if &SYSCC. > 4 or &callback_result. = 0 %then %goto theend;
		%end;
		
		%continue:
	%end;

	/* Close the directory */
	%theend:
	%if &did %then
		%let rc = %sysfunc(dclose(&did));
		
	/* Release the file reference */

	%let rc = %sysfunc(filename(fref));     
%mend fsutil_dirtree_walk_p;
