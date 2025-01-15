********************************************************************************
********************************************************************************
* Project: PSID Data Compilation
* Owner: Kimberly McErlean
* Started: September 2024
* File: individual_recodes
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files takes the full PSID dataset in long format
* Then recodes variables for congruence across time and for clarity
* Then matches to focal person (based on relationship)

use "$temp_psid\PSID_full_long.dta", clear // use long data for now, bc easier to manage
egen wave = group(survey_yr) // this will make years consecutive, easier for later

********************************************************************************
**# First create some technical recodes that will make things easier
********************************************************************************

gen in_sample=.
replace in_sample=0 if SEQ_NUMBER_==0 | inrange(SEQ_NUMBER_,60,90)
replace in_sample=1 if inrange(SEQ_NUMBER_,1,59)

gen hh_status_=.
replace hh_status_=0 if SEQ_NUMBER_==0 
replace hh_status_=1 if inrange(SEQ_NUMBER_,1,20) // in sample
replace hh_status_=2 if inrange(SEQ_NUMBER_,51,59) // institutionalized
replace hh_status_=3 if inrange(SEQ_NUMBER_,71,80) // new HH 
replace hh_status_=4 if inrange(SEQ_NUMBER_,81,89) // died
label define hh_status 0 "not in sample" 1 "in sample" 2 "institutionalized" 3 "new hh" 4 "died"
label values hh_status_ hh_status

gen has_psid_gene=0
replace has_psid_gene = 1 if inlist(SAMPLE,1,2)

label define sample 0 "not sample" 1 "original sample" 2 "born-in" 3 "moved in" 4 "joint inclusion" 5 "followable nonsample parent" 6 "nonsample elderly"
label values SAMPLE sample

gen relationship=.
replace relationship=0 if RELATION_==0
replace relationship=1 if inlist(RELATION_,1,10)
replace relationship=2 if inlist(RELATION_,2,20,22,88)
replace relationship=3 if inrange(RELATION_,23,87) | inrange(RELATION_,90,98) | inrange(RELATION_,3,9)
label define relationship 0 "not in sample" 1 "head" 2 "partner" 3 "other"
label values relationship relationship

replace in_sample=0 if survey_yr==1968 & relationship==0 // no seq number in 1968
replace in_sample=1 if survey_yr==1968 & relationship!=0 // no seq number in 1968

gen moved = 0
replace moved = 1 if inlist(MOVED_,1,2) & inlist(SPLITOFF_,1,3) // moved in
replace moved = 2 if inlist(MOVED_,1,2) & inlist(SPLITOFF_,2,4) // splitoff
replace moved = 3 if inlist(MOVED_,5,6) // moved out
replace moved = 4 if MOVED_==1 & SPLITOFF_==0 // born
replace moved = 5 if MOVED_==7

label define moved 0 "no" 1 "Moved in" 2 "Splitoff" 3 "Moved out" 4 "Born" 5 "Died"
label values moved moved
tab moved in_sample, m
tab AGE_INDV_ moved

gen permanent_attrit=0
replace permanent_attrit=1 if PERMANENT_ATTRITION==1 // attrited
replace permanent_attrit=2 if inlist(PERMANENT_ATTRITION,2,3) // marked as died
label define perm 0 "no" 1 "attrited" 2 "died"
label values permanent_attrit perm

tab MOVED_YEAR_ SPLITOFF_YEAR_ if MOVED_YEAR_!=0 & SPLITOFF_YEAR_ !=0, m

gen change_yr=.
replace change_yr = MOVED_YEAR_ if MOVED_YEAR_ >0 & MOVED_YEAR_ <9000
replace change_yr = SPLITOFF_YEAR_ if SPLITOFF_YEAR_ >0 & SPLITOFF_YEAR_ <9000

bysort unique_id: egen entrance_no=rank(change_yr) if inlist(moved,1,4), track
bysort unique_id: egen leave_no=rank(change_yr) if inlist(moved,2,3,5), track
tab entrance_no, m
tab leave_no, m

gen hh1_start=.
replace hh1_start=change_yr if entrance_no==1 
bysort unique_id (hh1_start): replace hh1_start=hh1_start[1]
gen hh2_start=.
replace hh2_start=change_yr if entrance_no==2 
bysort unique_id (hh2_start): replace hh2_start=hh2_start[1]
gen hh3_start=.
replace hh3_start=change_yr if entrance_no==3
bysort unique_id (hh3_start): replace hh3_start=hh3_start[1]
gen hh4_start=.
replace hh4_start=change_yr if entrance_no==4
bysort unique_id (hh4_start): replace hh4_start=hh4_start[1]
gen hh5_start=.
replace hh5_start=change_yr if entrance_no==5
bysort unique_id (hh5_start): replace hh5_start=hh5_start[1]

gen hh1_end=.
replace hh1_end=change_yr if leave_no==1
bysort unique_id (hh1_end): replace hh1_end=hh1_end[1]
gen hh2_end=.
replace hh2_end=change_yr if leave_no==2
bysort unique_id (hh2_end): replace hh2_end=hh2_end[1]
gen hh3_end=.
replace hh3_end=change_yr if leave_no==3
bysort unique_id (hh3_end): replace hh3_end=hh3_end[1]
gen hh4_end=.
replace hh4_end=change_yr if leave_no==4
bysort unique_id (hh4_end): replace hh4_end=hh4_end[1]
gen hh5_end=.
replace hh5_end=change_yr if leave_no==5
bysort unique_id (hh5_end): replace hh5_end=hh5_end[1]

sort unique_id survey_yr
browse unique_id survey_yr moved change_yr entrance_no leave_no hh1_start hh1_end hh2_start hh2_end

********************************************************************************
**# Demographic recodes
********************************************************************************

gen partnered=.
replace partnered=0 if in_sample==1 & MARITAL_PAIRS_==0
replace partnered=1 if in_sample==1 & inrange(MARITAL_PAIRS_,1,3)
