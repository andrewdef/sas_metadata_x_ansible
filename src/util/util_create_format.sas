/** 
* Defines a SAS format by reading data from a configuration table. If the configuration dataset has VALID_FROM_DT and VALID_TO_DT
* variables, only the rows that match the condition VALID_FROM_DT < &reference_dt. and &reference_dt. <= VALID_TO_DT are selected.
* Dataset options (where conditions, for example) can be used in the tablenm parameter
*
* @param fmtlib libref to store the format (default: work)
* @param tablenm configuration table
* @param formatnm format name
* @param startvar input variable for format
* @param labelvar output variable for format
* @param fmttype format type (C, N)
* @param defaultval default format value
* @param reference_dt reference date for filtering the configuration table
*/

%macro util_create_format(tablenm, formatnm, startvar, labelvar, fmttype, defaultval, fmtlib=work, reference_dt=);
	%local filter_param_table_by_refdt index_of_bracket;
	%let filter_param_table_by_refdt = %eval(%util_has_column(VALID_FROM_DT, &tablenm.) and %util_has_column(VALID_TO_DT, &tablenm.));
	
	%if &filter_param_table_by_refdt. %then %do;
		%let index_of_bracket = %index(%superq(tablenm), %str(%());

		%if &index_of_bracket. %then %do;
			data __temp_fmt_source /view=__temp_fmt_source;
				set &tablenm.;
			run;
			%let tablenm = __temp_fmt_source;
		%end;
	%end;

	data fmt(keep=FMTNAME START END LABEL TYPE HLO) ;
		set &tablenm.%if &filter_param_table_by_refdt. %then %do;
					 (where=(VALID_FROM_DT < &reference_dt. and &reference_dt. <= VALID_TO_DT))
					 %end; 
			end=lastobs;
		
		FMTNAME          = "&formatnm.";
		START            = &startvar.;
		END              = START;
		LABEL            = &labelvar. ;
		TYPE             = "&fmttype." ;
		output ;

		if lastobs then do ;
			START         = "";
			END           = START;
			HLO           = 'O';
			LABEL         = &defaultval.;
			output ;
		end ;
	run ;

	proc format cntlin=fmt lib=&fmtlib.;
	run;
%mend util_create_format;
