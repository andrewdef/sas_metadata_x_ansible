/** 
* Prints the latest error message raised by the macro errhandle_throw_remote_exception
*
*/

%macro errhandle_print_exception_msg;

	%put ERROR: Exception was %superq(__exception_message);
	
%mend errhandle_print_exception_msg;