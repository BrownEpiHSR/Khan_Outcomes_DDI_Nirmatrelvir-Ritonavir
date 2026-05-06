*Program name: Crude rate ratio and differences GH
*Purpose: Generates crude rate ratios, differences and bootstrapped confidence intervals for hospitalization and death with varying grace periods
*Last Updated: May 5, 2026;

*Stack the datasets for Paxlovid with and without interacting medications;
data OUTPUT2.stack;
	set output2.pax_interact_outcomes (in=a) output2.pax_nointeract_outcomes (in=b);
	if a=1 then exposure=1 ; else exposure=0;
run;
	
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

proc sql;
	create table demog as 
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

*Calculate rates;
%macro rateratios (outcome, offset);
	proc genmod data=stack;
	class exposure course_id/param=glm;
	model &outcome = exposure/dist=poisson link=log offset=&offset;
	estimate "RR exposure=1 vs 0 &outcome" exposure 1/exp ;
	repeated subject=course_id/type=ind;
	lsmeans exposure/exp cl;
	run;
%mend;

%macro rateratios (outcome, offset);
	proc genmod data=stack;
	class exposure (ref="0") course_id/param=ref;
	model &outcome = exposure/dist=poisson link=log offset=&offset;
	estimate "RR exposure=1 vs 0 &outcome" exposure 1/exp ;
	repeated subject=course_id/type=ind;
	lsmeans exposure/exp cl;
	run;
%mend;

%rateratios (death_3, offset_3);
%rateratios (death_7, offset_7);
%rateratios (death_14, offset_14);
%rateratios (hospital_f_14, offset_14);


*Calculate rate differences differences;
%macro mainrate (outcome, offset);
ods output genmod.lsmeans=&outcome._main_est;

proc genmod data=output2.stack;
	class exposure (ref="0")  course_id/param=glm;
	model &outcome=exposure/dist=poisson link=log offset=&offset;
	estimate "RD: &outcome" exposure 1/exp ;
	repeated subject=course_id/type=ind;
	lsmeans exposure/exp cl;
run;

proc transpose data=&outcome._main_est out=&outcome._t;
	var expestimate;
	id exposure;
run;

data output2.&outcome._main_est;
	length outcome $20;
	set &outcome._t;
	rate_diff=_1-_0;
	outcome="&outcome";
run;
%mend;

%mainrate (death_3, offset_3);
%mainrate (death_14, offset_14);
%mainrate (death_7, offset_7);
%mainrate (death_14, offset_14);
%mainrate (hospital_f_14, offset_14);

*Create bootstrap samples;
proc surveyselect data=output2.stack out=output2.bootsample
	seed=4336240 method=urs samprate=1 outhits rep=1000;
run;
	
%macro boot_est (outcome, offset);
%do bsample=1 %to 1000;

ods output Genmod.LSMeans=&outcome._boot_sample;
proc genmod data=output2.bootsample;
	where replicate=&bsample;
	class course_id exposure (ref="0");
	model &outcome=exposure/dist=poisson link=log offset=&offset;
	estimate "RD: &outcome" exposure 1/exp ;
	repeated subject=course_id/type=ind;
	lsmeans exposure/exp cl;
run;

proc transpose data=&outcome._boot_sample out=&outcome._t_&bsample;
	var expestimate;
	id exposure;
run;

data output2.&outcome._bstrap_&bsamplE;
	length outcome $20;
	set &outcome._t_&bsample;
	rate_diff=_1-_0;
	outcome="&outcome";
run;

proc datasets library=work kill nolist;
quit;
%end;

%mend;

%boot_est (death_3, offset_3);
%boot_est (death_7, offset_7);
%boot_est (death_14, offset_14);
%boot_est (hospital_f_14, offset_14);

*DEATH_3_outcome;
proc sql noprint;
	select cats ("output2.", memname)
	into :death_3
	separated by " "
	from dictionary.tables
	where libname="OUTPUT2" and memname contains "DEATH_3_BSTRAP_"
;
quit;

%put &death_3;

data death_3_stacked;
	set &death_3;
	rate_ratio=_1/_0;
	rate_diff=_1-_0;
run;

proc univariate  data=death_3_stacked noprint;
	var rate_ratio;
output out=out.death_3_final_b pctlpts=2.5 97.5 pctlpre=CI;
run;

proc univariate  data=death_3_stacked noprint;
	var rate_ratio;
output out=out.death_3_diff_b pctlpts=2.5 97.5 pctlpre=CI;
run;


*DEATH_7 outcome;
proc sql noprint;
	select cats ("output2.", memname)
	into :death_7
	separated by " "
	from dictionary.tables
	where libname="OUTPUT2" and memname contains "DEATH_7_BSTRAP_"
;
quit;

%put &death_7;

data death_7_stacked;
	set &death_7;
	rate_ratio=_1/_0;
	rate_diff=_1-_0;
run;

proc univariate  data=death_7_stacked noprint;
	var rate_ratio;
output out=out.death_7_final_b pctlpts=2.5 97.5 pctlpre=CI;
run;

proc univariate  data=death_7_stacked noprint;
	var rate_ratio;
output out=out.death_7_diff_b pctlpts=2.5 97.5 pctlpre=CI;
run;

*DEATH_14 outcome;
proc sql noprint;
	select cats ("output2.", memname)
	into :death_14
	separated by " "
	from dictionary.tables
	where libname="OUTPUT2" and memname contains "DEATH_14_BSTRAP_"
;
quit;

%put &death_14;

data death_14_stacked;
	set &death_14;
	rate_ratio=_1/_0;
	rate_diff=_1-_0;
run;

proc univariate  data=death_14_stacked noprint;
	var rate_ratio;
output out=out.death_14_final_b pctlpts=2.5 97.5 pctlpre=CI;
run;

proc univariate  data=death_14_stacked noprint;
	var rate_ratio;
output out=out.death_14_diff_b pctlpts=2.5 97.5 pctlpre=CI;
run;

*Hospital_14 outcome;
proc sql noprint;
	select cats ("output2.", memname)
	into :hosp_14
	separated by " "
	from dictionary.tables
	where libname="OUTPUT2" and memname contains "HOSPITAL_F_14_BSTRAP_"
;
quit;

%put &hosp_14;

data hosp_14_stacked;
	set &hosp_14;
	rate_ratio=_1/_0;
	rate_diff=_1-_0;
run;

proc univariate  data=hosp_14_stacked noprint;
	var rate_ratio;
output out=out.hosp_14_final_b pctlpts=2.5 97.5 pctlpre=CI;
run;

proc univariate  data=hosp_14_stacked noprint;
	var rate_diff;
output out=out.hosp_14_diff_b pctlpts=2.5 97.5 pctlpre=CI;
run;

