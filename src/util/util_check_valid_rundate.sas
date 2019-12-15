/** 
* Checks the validity of a date value in the format YYYYMMDD. If the date is invalid, an error message is written in the SAS log 
* and the SYSCC automatica variable is set to 5.
*
* @param rundate_macro_var name of a macrovariabile that stores the date value to be checked
*/

%macro util_check_valid_rundate(rundate_macro_var);

	%if not %symexist(&rundate_macro_var.) %then
		%let &rundate_macro_var. =;
		
	%if &&&rundate_macro_var.. = %then %do;
		%errhandle_throw_exception(INVALID_RUNDATE, La data di riferimento non deve essere missing );
		%return;
	%end;

	/* Elimina eventuali 0 all'inizio della data */
	%let converted_date = %sysfunc(inputn(&&&rundate_macro_var.., 8.));
	%if not %sysfunc(prxmatch(%sysfunc(prxparse(/\d{8}/)), &converted_date.)) %then %do;
		%errhandle_throw_exception(INVALID_RUNDATE, La data di riferimento &&&rundate_macro_var.. e%str(%') in un formato non valido );
		%return;
	%end;
	
	%local converted_date __DATE_LOWER_BOUND __DATE_UPPER_BOUND;
	%let converted_date = %sysfunc(inputn(&converted_date., yymmdd8.));
	%let __DATE_LOWER_BOUND = 16071; /* 01JAN2004 */
	%let __DATE_UPPER_BOUND = 51134; /* 31DEC2099 */
	
	%if "&converted_date." = "." %then %do;
		%errhandle_throw_exception(INVALID_RUNDATE, La data di riferimento &&&rundate_macro_var.. e%str(%') in un formato non valido );
		%return;
	%end;
	%else %if %sysevalf(&converted_date. > &__DATE_UPPER_BOUND.) or %sysevalf(&converted_date. < &__DATE_LOWER_BOUND.) %then %do;
		%errhandle_throw_exception(INVALID_RUNDATE, La data di riferimento &&&rundate_macro_var.. deve essere compresa tra %sysfunc(putn(&__DATE_LOWER_BOUND., date9.)) a %sysfunc(putn(&__DATE_UPPER_BOUND., date9.)));
		%return;
	%end;
	
%mend util_check_valid_rundate;
