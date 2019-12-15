/** 
* Puts SAS in an errore state by printing the error message specified as input parameter to the log
* and assigning the value 5 (4 is Warning, > 4 is an error) to the automatic macrovariable SYSCC.
* The error message and error type are assigned to global macro variables (exception_message and exception_type
* respectively) to be used by subsequent code to handle the exception. Macros calling this are meant to %return_var
* immediately after the call, to let their calling macro/program decide how to handle the exception by checking
* SYSCC and exception_type
*
* @param type exception type (eg. FILE_NOT_FOUND)
* @param message exception message
*/

%macro errhandle_throw_exception(type, message);
	%symdel exception_message /NOWARN;
	%global exception_message;
	
	%symdel exception_type /NOWARN;
	%global exception_type;
	
	%let exception_message = %superq(message);
	%let exception_type = %superq(type);
	%if %superq(message) ^= %then
		%put ERROR: %superq(message);
	%let SYSCC = 5;	
%mend errhandle_throw_exception;