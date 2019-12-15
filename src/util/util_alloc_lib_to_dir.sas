%macro util_alloc_lib_to_dir(libref, dir, lib_options=);
   %fsutil_mkdirs(&dir);
   %if &SYSCC. > 4 %then %return;

   libname &libref. "&dir" &lib_options.;
%mend util_alloc_lib_to_dir;
