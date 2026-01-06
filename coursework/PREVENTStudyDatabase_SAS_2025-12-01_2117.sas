/* Edit the following line to reflect the full path to your CSV file */
%let csv_file = 'PREVENTStudyDatabase_DATA_NOHDRS_2025-12-01_2117.csv';

OPTIONS nofmterr;

proc format;
	value visit_ 0='BASELINE';
	value gender_id_ 1='Male' 2='Female' 
		-7='Refused' -8='Don''t know' 
		-9='Missing';
	value race_ 1='American Indian/Alaska Native' 2='Asian' 
		3='Native Hawaiian/Pacific Islander' 4='Black/African-American' 
		5='White/Caucasian' 6='Other' 
		7='Multi-Racial' 9='Missing/Unknown';
	value hisp_ 0='Not Hispanic' 1='Hispanic' 
		9='Missing/Unknown';
	value prevent_baseline_complete_ 0='Incomplete' 1='Unverified' 
		2='Complete';
	value visit_hiv_ 0='Baseline' 1='Visit 1' 
		2='Visit 2';
	value hiv_status_ 1='HIV-' 2='HIV+' 
		-7='Refused' -8='Don''t know' 
		-9='Missing';
	value abc_hiv_ 0='No' 1='Yes' 
		-7='Refused' -8='Don''t know' 
		-9='Missing';
	value hiv_factors_complete_ 0='Incomplete' 1='Unverified' 
		2='Complete';
	value visit_clin_ 0='Baseline' 1='Visit 1' 
		2='Visit 2';
	value hypertensionmed_ 0='No' 1='Yes' 
		-7='Refused' -8='Don''t know' 
		-9='Missing';
	value diabetes_clin_ 0='No' 1='Yes';
	value clinical_indicators_complete_ 0='Incomplete' 1='Unverified' 
		2='Complete';
	value visits_meds_ 0='Baseline' 1='Visit 1' 
		2='Visit 2';
	value cursmoke_ 0='No' 1='Yes' 
		-7='Refused' -8='Don''t know' 
		-9='Missing';
	value statinmed_ 0='No' 1='Yes' 
		-7='Refused' -8='Don''t know' 
		-9='Missing';
	value meds_behavior_complete_ 0='Incomplete' 1='Unverified' 
		2='Complete';

	run;

data work.redcap; %let _EFIERR_ = 0;
infile &csv_file  delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=1 ;

	informat record_id $500. ;
	informat ccsid best32. ;
	informat visit best32. ;
	informat ageativis best32. ;
	informat gender_id best32. ;
	informat race best32. ;
	informat hisp best32. ;
	informat prevent_baseline_complete best32. ;
	informat ccsid_hiv best32. ;
	informat visit_hiv best32. ;
	informat hiv_status best32. ;
	informat cdn4_hiv best32. ;
	informat vload_hiv best32. ;
	informat abc_hiv best32. ;
	informat hiv_factors_complete best32. ;
	informat ccsid_clin best32. ;
	informat visit_clin best32. ;
	informat hypertensionmed best32. ;
	informat systolic best32. ;
	informat chol best32. ;
	informat hdlct best32. ;
	informat hga1c best32. ;
	informat egfr_ckdepi best32. ;
	informat diabetes_clin best32. ;
	informat clinical_indicators_complete best32. ;
	informat ccsid_meds best32. ;
	informat visits_meds best32. ;
	informat cursmoke best32. ;
	informat statinmed best32. ;
	informat meds_behavior_complete best32. ;

	format record_id $500. ;
	format ccsid best12. ;
	format visit best12. ;
	format ageativis best12. ;
	format gender_id best12. ;
	format race best12. ;
	format hisp best12. ;
	format prevent_baseline_complete best12. ;
	format ccsid_hiv best12. ;
	format visit_hiv best12. ;
	format hiv_status best12. ;
	format cdn4_hiv best12. ;
	format vload_hiv best12. ;
	format abc_hiv best12. ;
	format hiv_factors_complete best12. ;
	format ccsid_clin best12. ;
	format visit_clin best12. ;
	format hypertensionmed best12. ;
	format systolic best12. ;
	format chol best12. ;
	format hdlct best12. ;
	format hga1c best12. ;
	format egfr_ckdepi best12. ;
	format diabetes_clin best12. ;
	format clinical_indicators_complete best12. ;
	format ccsid_meds best12. ;
	format visits_meds best12. ;
	format cursmoke best12. ;
	format statinmed best12. ;
	format meds_behavior_complete best12. ;

input
	record_id $
	ccsid
	visit
	ageativis
	gender_id
	race
	hisp
	prevent_baseline_complete
	ccsid_hiv
	visit_hiv
	hiv_status
	cdn4_hiv
	vload_hiv
	abc_hiv
	hiv_factors_complete
	ccsid_clin
	visit_clin
	hypertensionmed
	systolic
	chol
	hdlct
	hga1c
	egfr_ckdepi
	diabetes_clin
	clinical_indicators_complete
	ccsid_meds
	visits_meds
	cursmoke
	statinmed
	meds_behavior_complete
;
if _ERROR_ then call symput('_EFIERR_',"1");
run;

proc contents;run;

data redcap;
	set redcap;
	label record_id='Record ID';
	label ccsid='Unique Subject ID ';
	label visit='0=BASELINE';
	label ageativis='Age at visit (years)';
	label gender_id='sex at birth ';
	label race='Race (NIH 2018 definition)';
	label hisp='Hispanic ethnicity ';
	label prevent_baseline_complete='Complete?';
	label ccsid_hiv='Unique subject ID ';
	label visit_hiv='Visit number (0=Baseline, 1=Visit1, 2=Visit2) ';
	label hiv_status='HIV serostatus';
	label cdn4_hiv='CD4 cell count (cells/uL)';
	label vload_hiv='HIV RNA viral load (copies/mL) ';
	label abc_hiv='Abacavir exposure ';
	label hiv_factors_complete='Complete?';
	label ccsid_clin='Unique Subject ID';
	label visit_clin='Visit number (0=Baseline, 1=Visit1, 2=Visit2) ';
	label hypertensionmed='On antihypertensive medications ';
	label systolic='Systolic blood pressure (mmHg)';
	label chol='Total cholesterol (mg/dL)';
	label hdlct='HDL cholesterol (mg/dL)';
	label hga1c='Hemoglobin A1c (%)';
	label egfr_ckdepi='eGFR (mL/min/1.73m²) ';
	label diabetes_clin='Diabetes indicator ';
	label clinical_indicators_complete='Complete?';
	label ccsid_meds='Unique Subject ID';
	label visits_meds='Visit number (0=Baseline, 1=Visit1, 2=Visit2) ';
	label cursmoke='Current cigarette smoking ';
	label statinmed='On statin medication ';
	label meds_behavior_complete='Complete?';
	format visit visit_.;
	format gender_id gender_id_.;
	format race race_.;
	format hisp hisp_.;
	format prevent_baseline_complete prevent_baseline_complete_.;
	format visit_hiv visit_hiv_.;
	format hiv_status hiv_status_.;
	format abc_hiv abc_hiv_.;
	format hiv_factors_complete hiv_factors_complete_.;
	format visit_clin visit_clin_.;
	format hypertensionmed hypertensionmed_.;
	format diabetes_clin diabetes_clin_.;
	format clinical_indicators_complete clinical_indicators_complete_.;
	format visits_meds visits_meds_.;
	format cursmoke cursmoke_.;
	format statinmed statinmed_.;
	format meds_behavior_complete meds_behavior_complete_.;
run;

proc contents data=redcap;
proc print data=redcap;
run;