/** 
* Puts SAS in an errore state by calling the errhandle_throw_exception macro and
* send the exception message and exception type back to the calling session by
* assigning them to the varibles __exception_message and __exception_type respectively,
* by using %sysrput. This macro is meant to be used in a remote session.
*
* @param type exception type (eg. FILE_NOT_FOUND)
* @param message exception message
*/

%macro errhandle_throw_remote_exception(type, message);
	%errhandle_throw_exception(%superq(type), %superq(message));
	
	%sysrput __exception_message = %superq(message);
	%sysrput __exception_type = %superq(type);
	%sysrput SYSCC = 5;
%mend errhandle_throw_remote_exception;