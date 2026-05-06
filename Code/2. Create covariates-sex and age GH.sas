*Program name: Create covariates
*Primary programmer: Marzan Khan
*Date updated: 22nd April
*Purpose: Create dataset containing covariates to sex and race;

*Stack the datasets for paxlovid with and without interacting medications;
data OUTPUT2.stack;
	set output2.pax_interact_outcomes (in=a) output2.pax_nointeract_outcomes (in=b);
	if a=1 then exposure=1 ; else exposure=0;
run;
	
*Check the distribution of the exposure variable;
proc freq data=output2.stack;
	tables exposure;
run;

proc format;
	value reason_three
		1="Death"
		2="Hospitalization"
		3="Medicare end"
		4="Follow-up end-3 days grace period";

		value reason_seven
		1="Death"
		2="Hospitalization"
		3="Medicare end"
		4="Follow-up end-7 days grace period";

	value reason_fourteen
		1="Death"
		2="Hospitalization"
		3="Medicare end"
		4="Follow-up end-14 days grace period";
quit;

*Collect sex and race variables;
proc sql;
	create table output2.demog as 
	select *
	from OUTPUT2.stack as a
	left join data.table1_2 as b
	on a.master_patient_id=b.master_patient_id;
quit;

proc format ;
	value $sexf 1="Male" 2="Female" " "="Missing";

	value $racef 0="Unknown"
				 1="Non-Hispanic White"
				 2="Black (or African-American)"
				 3="Other"
				 4="Asian/Pacific Islander"
				 5="Hispanic"
				 6="American Indian/ Alsaka Native"
				 " "="Missing";
run;

proc means data=demog median q1 q3 maxdec=0 min;
	var age_altered ;
run;

proc means data=demog median q1 q3 maxdec=0 min;
	var age ;
run;

*Use age and SEX_IDENT_CD vars in IPW models













