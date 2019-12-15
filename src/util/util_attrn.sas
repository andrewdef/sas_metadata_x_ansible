/** 
* Returns the value of a numeric attribute of the dataset specified
* as input. For a list of valid attribute names, refer to the SAS
* documentation for function attrn
*
* @param ds input dataset
* @param attrib name of the attribute
* @returns value of the attribute
*/
	
%macro util_attrn(ds, attrib);

	%local dsid rc;

	%let dsid=%sysfunc(open(&ds,is));
	%if &dsid EQ 0 %then %do;
		0
	%end;
	%else %do;
		%sysfunc(attrn(&dsid,&attrib))
		%let rc=%sysfunc(close(&dsid));
	%end; 

%mend util_attrn;