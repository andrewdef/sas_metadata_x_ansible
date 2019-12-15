%macro util_get_nobs(ds);
	%local dsid rc;

	%let dsid=%sysfunc(open(&ds, I));
	%if &dsid EQ 0 %then %do;
		0
	%end;
	%else %do;
		%sysfunc(attrn(&dsid, NLOBSF))
		%let rc=%sysfunc(close(&dsid));
	%end;
%mend util_get_nobs;