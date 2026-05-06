*Program name: Calculate prior nursing home time
*Primary programmer: Marzan Khan
*Date updated: 22nd April
*Purpose: Create dataset containing covariate prior nursing home time;

*Subset the stays and episode file to master_patient_id in my cohort;
proc sql;
	create table output2.stays as
	select *
	from ltcdc.stay_update_1
	where master_patient_id in (select master_patient_id from output2.demog);
quit;


proc sql;
	create table output2.episode as
	select *
	from ltcdc.episode
	where master_patient_id in (select master_patient_id from output2.demog);
quit;


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

*Find earliest and latest last day of course;
proc freq data=output2.demog;
	tables last_course_day;
run;


*Create start date of course;
data demog2;
	set output2.demog;
	first_course_day=last_course_day-days_risk_3+3;
	lookback_end=first_course_day-1;
	format first_course_day date9.;
run;

*Merge each record to all stays;
proc sql;
	create table merged as
	select *
	from demog2 as a
	left join output2.nonoverlap_stays_cont as b
	on a.master_patient_id=b.master_patient_id;
quit;

*Flag all stays where the start date is less than  or equal to the lookback end;
data merged2;
	set merged;
	if start_date_d<=lookback_end then time=1;
	else time=0;
run;

proc freq data=merged2;
	tables time;
run;

proc print data=merged2 (obs=20);
	var master_patient_id lookback_start start_date_d first_course_day end_date_d time;
	where time=1;
run;

*Create nursing home start and end dates;
data merged3;
	set merged2;
	
	if time=1 then do;
	nh_end=min(end_date_d, lookback_end);
	nh_start=start_date_d;
	end;
	
	if time=0 then nh_time=0;
	else nh_time=nh_end-nh_start+1;

	if nh_time=. then nh_time=0;

	format nh_start nh_end date9.;

run;

proc print data=merged3 (obs=20);
	var master_patient_id lookback_start start_date_d first_course_day end_date_d nh_start nh_end nh_time time;
	where nh_time=0;
run;

proc freq data=merged3;
	tables nh_time;
run;

proc sql;
	create table merged4 as
	select distinct course_id,exposure, master_patient_id,  sum(nh_time) as nh_time_total
	from merged3
	group by course_id, exposure;
quit;


*Now merge to output2.demog;
proc sql;
	create table output2.demog2 as
	select a.*, b.nh_time_total
	from output2.demog as a
	left join merged4 as b
	on a.course_id=b.course_id and a.exposure=b.exposure;
quit;

proc sgplot data=output2.demog2;
	histogram nh_time_total;
run;

proc freq data=output2.demog2;
	tables nh_time_total;
run;

*Median Q1,Q3 nursing home time-Overall;
proc means data=output2.demog2 maxdec=1 mean std median qrange q1 q3;
	var nh_time_total ;
run;

*Median Q1,Q3 nursing home time-By exposure;
proc means data=output2.demog2 maxdec=1 mean std median qrange q1 q3;
	var nh_time_total ;
	class exposure;
run;

proc format ;
	value longstay
		101-high =1
		low-100=2;
quit;

*Determine long vs. short stay;
proc freq data=output2.demog2;
	tables nh_time_total;
	format nh_time_total longstay.;
run;

proc sort data=output2.demog2;
	by exposure;
run;

proc freq data=output2.demog2;
	tables nh_time_total;
	format nh_time_total longstay.;
	by exposure;
run;


