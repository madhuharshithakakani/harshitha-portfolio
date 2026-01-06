
/******************************************************
  BST 625 — Project 3 (SAS portion)
  Student: <YOUR NAME HERE>        Date: <DATE>
  Course: BST 625
  Instructor: Yue Pan

  HOW TO USE:
   1) Edit only the macro parameters in SECTION 0 to match your CTN30 files.
   2) Run the whole file. Each problem is clearly sectioned.
   3) Copy this entire SAS program into your Word submission, as required.
******************************************************/

/*======================================================
=                  SECTION 0: SETTINGS                 =
======================================================*/
options nodate nonumber formdlim=' ' ls=120 ps=60 nocenter;
ods listing close;

/* ---- Edit these paths (or keep relative) ---- */
%let root=~/bst625_proj3;        /* e.g., C:\Users\you\BST625\Proj3 */
%let ctn30=&root./ctn30_data;    /* folder with CTN30 data files */

/* Create libraries */
libname proj3 "&root.";
libname ctn30 "&ctn30.";

/* ---- CTN30 variable names (change ONLY if different in your data) ---- */
%let ID=patdeid;          /* participant id */
%let VISIT=visit;         /* visit index with baseline coded as 0 */
%let DOB=dob;             /* date of birth (SAS date) */
%let VISITDT=visitdt;     /* visit date (SAS date) */

/* Long substance-use table column names */
%let SUBCAT=subcat;       /* text label/category for substance */
%let DAYS30=days30;       /* days used in past 30 d */
%let ANY30=any30;         /* indicator 1/0 past 30 d */

/* Cohort & randomization table names (in ctn30 lib) */
%let VISITS_DS=visits;             /* per-visit rows, includes &VISIT and optionally age */
%let DEMOG_DS=demog;               /* demographics with DOB */
%let RAND_DS=randomization;         /* randomization table */
%let COHORT0_DS=cohort0;           /* baseline cohort (one row per id at baseline) */
%let SUBUSE_DS=subuse;             /* long-format substance use */

/* Outcome/derived variable names used in Table 1 */
%let GENDER=gender;                /* values like 'M','F' */
%let ALC30=alc30;                  /* alcohol to intox in past 30 days 1/0 */
%let ALC_LIFE=alc_life;            /* alcohol to intox in lifetime 1/0 */
%let DAYS_SUBUSE30=days_subuse30;  /* numeric */

/*======================================================
=   ****************** Problem 1 ******************     =
=   Top car model per make by best overall MPG          =
======================================================*/
title1 "Problem 1: Best Overall MPG model within each Make";

proc sql;
  create table work.cars_mean as
  select Make, Model,
         round(mean((MPG_City + MPG_Highway)/2), 0)   as mean_mpg_int,
         round(mean((MPG_City + MPG_Highway)/2), 0.1) as mean_mpg_1d
  from sashelp.cars
  group by Make, Model;
quit;

proc sort data=work.cars_mean;
  by Make descending mean_mpg_int descending mean_mpg_1d Model;
run;

data proj3.p1_top_model_by_make(keep=Make Model mean_mpg_int);
  set work.cars_mean;
  by Make descending mean_mpg_int descending mean_mpg_1d;
  if first.Make then output;
run;

proc print data=proj3.p1_top_model_by_make noobs label;
  label mean_mpg_int = "Overall MPG (rounded integer)";
  title2 "Top model by Make with best overall MPG";
run;

/*======================================================
=   ****************** Problem 2 ******************     =
=   Weight data: fix 9999 -> missing; WIDE -> LONG      =
======================================================*/
/* Expect proj3.weight_loss exists with vars: pid gender walk_steps weight0 weight1 weight2 */
title1 "Problem 2: Clean and Reshape Weight Data";

data work.weight_clean;
  set proj3.weight_loss;
  array wts[3] weight0-weight2;
  do i=1 to dim(wts);
    if wts[i]=9999 then wts[i]=.;
  end;
  drop i;
run;

data proj3.weight_long(keep=pid gender walk_steps weight_time all_weight);
  set work.weight_clean;
  length weight_time $8;
  array wts[3] weight0 weight1 weight2;
  do i=1 to 3;
    weight_time = cats('weight', i-1);
    all_weight  = wts[i];
    output;
  end;
  drop i weight0 weight1 weight2;
run;

proc print data=proj3.weight_long(obs=12) noobs; run;

/*======================================================
=   *********** Problem 3: CTN30 — AGE **************** =
======================================================*/
/* Pull baseline visits (visit=0) and compute AGE if needed */
data work.visits0;
  set ctn30.&VISITS_DS;
  where &VISIT=0;
run;

%macro age_make;
  %local dsid varnum rc;
  %let dsid=%sysfunc(open(work.visits0));
  %let varnum=%sysfunc(varnum(&dsid, age));
  %let rc=%sysfunc(close(&dsid));

  %if &varnum>0 %then %do;
    data proj3.AGE(keep=&ID &VISIT age);
      set work.visits0(keep=&ID &VISIT age);
    run;
  %end;
  %else %do;
    proc sql;
      create table work.vz as
      select v.&ID, v.&VISIT, v.&VISITDT, d.&DOB
      from work.visits0 v
      left join ctn30.&DEMOG_DS d
        on v.&ID=d.&ID;
    quit;
    data proj3.AGE(keep=&ID &VISIT age);
      set work.vz;
      if nmiss(&DOB, &VISITDT)=0 then age=floor((&VISITDT - &DOB)/365.25);
      else age=.;
    run;
  %end;
%mend;
%age_make;

proc print data=proj3.AGE(obs=10); title2 "AGE dataset (baseline)"; run;

/*======================================================
=   ******** Problem 4: Randomization table **********  =
======================================================*/
proc format;
  value armfmt
    1="SMM"
    2="SMM+ODC"
    other="Unknown";
  value randfmt 0="Not Randomized" 1="Randomized";
run;

data proj3.RND(keep=&ID arm randomized);
  set ctn30.&RAND_DS;
  length arm $8;
  /* Normalize arm */
  if not missing(arm_raw) then arm = put(arm_raw, armfmt.);
  else if upcase(strip(arm)) in ("SMM","SMM+ODC") then arm=upcase(strip(arm));
  else arm="Unknown";

  /* Normalize randomized */
  if upcase(strip(randomized)) in ("Y","YES","1") then randomized=1;
  else if randomized=1 then randomized=1;
  else randomized=0;
  format randomized randfmt.;
run;

/*======================================================
=   ***** Problem 5: Drug-use variables (30 days) ***** =
======================================================*/
data work.subuse_filt;
  set ctn30.&SUBUSE_DS;
  length _sub $80;
  _sub=upcase(strip(&SUBCAT));
  if index(_sub,'ALCOHOL')>0 then delete;
  if index(_sub,'NICOTINE')>0 then delete;
  if index(_sub,'MORE THAN')>0 or index(_sub,'MULTIPLE')>0 or index(_sub,'>1')>0 then delete;
  keep &ID &DAYS30 &ANY30;
run;

proc sql;
  create table proj3.DRG as
  select &ID,
         max(&ANY30) as ANY_DRG30,
         round(mean(&DAYS30), 0.1) as AVG_DRG30
  from work.subuse_filt
  group by &ID;
quit;

proc print data=proj3.DRG(obs=10); title "Derived DRG"; run;

/*======================================================
=   ******** Problem 6: Merge + randomized only ******* =
======================================================*/
proc sql;
  create table proj3.MERGED as
  select  a.*,
          b.age,
          r.arm,
          r.randomized,
          d.ANY_DRG30,
          d.AVG_DRG30
  from ctn30.&COHORT0_DS a
  left join proj3.AGE b
    on a.&ID=b.&ID and b.&VISIT=0
  left join proj3.RND r
    on a.&ID=r.&ID
  left join proj3.DRG d
    on a.&ID=d.&ID;
quit;

data proj3.BASELINE_RANDONLY;
  set proj3.MERGED;
  if randomized=1;
run;

/*======================================================
=   ******** Problem 7: Table 1 (baseline) ************ =
======================================================*/
title "Problem 7: Table 1 components";

/* Ns by arm */
proc freq data=proj3.BASELINE_RANDONLY noprint;
  tables arm / out=work.denoms;
run;

/* Male counts */
proc freq data=proj3.BASELINE_RANDONLY noprint;
  tables arm*&GENDER / out=work.gender_cts;
run;

/* Age median (Q1,Q3) */
proc means data=proj3.BASELINE_RANDONLY median q1 q3 nway;
  class arm;
  var age;
  output out=work.age_stats median=median_age q1=q1_age q3=q3_age;
run;

/* Days of substance use mean (sd) */
proc means data=proj3.BASELINE_RANDONLY mean std nway;
  class arm;
  var &DAYS_SUBUSE30;
  output out=work.subuse_stats mean=mean_days std=sd_days;
run;

/* Alcohol & Any Drug Use %s */
proc freq data=proj3.BASELINE_RANDONLY noprint;
  tables arm*&ALC30 / out=work.alc30_cts;
  tables arm*&ALC_LIFE / out=work.alclife_cts;
  tables arm*ANY_DRG30 / out=work.anydrug_cts;
run;

/* Quick prints to copy values */
proc print data=work.denoms noobs;       title2 "Denominators by Arm (N)"; run;
proc print data=work.gender_cts noobs;   title2 "Gender counts by Arm"; run;
proc print data=work.age_stats noobs;    title2 "Age Median (Q1,Q3) by Arm"; run;
proc print data=work.subuse_stats noobs; title2 "Days of Substance Use mean(sd)"; run;
proc print data=work.alc30_cts noobs;    title2 "Alcohol to intox (30d) counts"; run;
proc print data=work.alclife_cts noobs;  title2 "Alcohol to intox (lifetime) counts"; run;
proc print data=work.anydrug_cts noobs;  title2 "Any Drug Use counts"; run;

/* Missing-value counts helper */
proc means data=proj3.BASELINE_RANDONLY n nmiss;
  var age &DAYS_SUBUSE30 &ALC30 &ALC_LIFE ANY_DRG30;
  title2 "Missingness summary for Table 1 variables";
run;

/*======================================================
=   ******** Problem 8: Figures + Interpretation ****** =
======================================================*/
ods graphics on;

proc sgplot data=proj3.BASELINE_RANDONLY;
  title "Alcohol Intox (Past 30 Days) by Arm and Gender";
  vbar arm / group=&ALC30 groupdisplay=stack datalabel;
  by &GENDER;
  xaxis label="Counseling Condition";
  yaxis label="Count";
  keylegend / title="Alcohol Intox 30d (1=Yes)";
run;

proc sgpanel data=proj3.BASELINE_RANDONLY;
  panelby arm / columns=2;
  title "Age by Lifetime Alcohol Intox, stratified by Arm";
  vbox age / category=&ALC_LIFE;
  colaxis label="Lifetime Alcohol Intox (0/1)";
  rowaxis label="Age (years)";
run;

ods graphics off;

/*======================================================
=   ************** Bonus 4: Indicators **************** =
======================================================*/
%let PID=patient_id;
%let DX=diagnosis_code;

proc sort data=ctn30.patient_visits out=work.visits_nodup nodupkey;
  by &PID &DX;
run;

proc sql;
  create table proj3.patient_conditions as
  select &PID,
         max(case when upcase(&DX)='HCV' then 1 else 0 end) as HCV,
         max(case when upcase(&DX)='HBV' then 1 else 0 end) as HBV,
         max(case when upcase(&DX)='ALC' then 1 else 0 end) as ALC,
         max(case when upcase(&DX)='GEN' then 1 else 0 end) as GEN,
         max(case when upcase(&DX)='IMM' then 1 else 0 end) as IMM,
         max(case when upcase(&DX)='BIL' then 1 else 0 end) as BIL,
         max(case when upcase(&DX)='MET' then 1 else 0 end) as MET
  from work.visits_nodup
  group by &PID;
quit;

proc print data=proj3.patient_conditions(obs=20);
  title "Bonus: One patient per line with condition indicators";
run;

title; footnote;
ods listing;
