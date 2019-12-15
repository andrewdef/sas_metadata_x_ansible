/** 
* Returns the current datetime in the format <mm/dd/yyyy hh:mm:ss>
*
* @returns current datetime in the format <mm/dd/yyyy hh:mm:ss>
*/

%macro util_print_timestamp;
	<%sysfunc(date(), mmddyy10.) %sysfunc(time(), time10.2)>
%mend util_print_timestamp;