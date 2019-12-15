/** 
* Prints a message in the SAS log. The timestamp in
* the <mm/dd/yyyy hh:mm:ss> format is inserted before
* the message
*
* @param message message to be printed
*/

%macro util_print_log(message);
	%local log_row;
	%let log_row = %util_print_timestamp -;
	
	
	%let log_row = &log_row. &message.;
	
	%put &log_row.;
%mend util_print_log;
