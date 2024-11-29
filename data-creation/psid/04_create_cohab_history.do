********************************************************************************
********************************************************************************
* Project: PSID Data Compilation
* Owner: Kimberly McErlean
* Started: September 2024
* File: create_cohab_history
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files uses the family relationship and move in/ out info to attempt to compile
* a cohabitation history

********************************************************************************
********************************************************************************
**# Using HH composition variables
********************************************************************************
********************************************************************************
use "$temp_psid\PSID_full_long.dta", clear // use long data for now, bc easier to manage
egen wave = group(survey_yr) // this will make years consecutive, easier for later

********************************************************************************
** First create some technical recodes that will make things easier
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
** Relationship recodes
********************************************************************************

gen partnered=.
replace partnered=0 if in_sample==1 & MARITAL_PAIRS_==0
replace partnered=1 if in_sample==1 & inrange(MARITAL_PAIRS_,1,3)

// type of rel
tab MARST_DEFACTO_HEAD_ COUPLE_STATUS_HEAD_, m
tab MARST_LEGAL_HEAD_ MARST_DEFACTO_HEAD_ , m
tab relationship partnered,m  
tab relationship MARITAL_PAIRS,m  
// tabstat RELATION_, by(survey_yr) // coding switched in 1983

gen cohab_est_head=0
replace cohab_est_head = 1 if inrange(MARST_LEGAL_HEAD_,2,5) & MARST_DEFACTO_HEAD_==1 // cohab
replace cohab_est_head = 2 if MARST_LEGAL_HEAD_==1 &  MARST_DEFACTO_HEAD_==1 // married
tab COUPLE_STATUS_HEAD_ cohab_est_head , m

tab MARST_DEFACTO_HEAD_ if relationship==2 // okay, but not always correlated...is this bc sometimes they retain the info if like, they died and the one is still in the HH? for a year?
tab COUPLE_STATUS_HEAD_ if relationship==2 // okay, but not always correlated...
tab MARITAL_PAIRS if relationship==2

// head
gen rel_type = .
replace rel_type = 0 if relationship==1 & inrange(MARST_DEFACTO_HEAD_,2,5) // unpartnered
replace rel_type = 1 if inrange(survey_yr,1977,2021) & relationship==1 & cohab_est_head==2  // married (def)
replace rel_type = 2 if inrange(survey_yr,1977,2021) & relationship==1 & cohab_est_head==1 // cohab (def)
replace rel_type = 3 if inrange(survey_yr,1968,1976) & relationship==1 & MARST_DEFACTO_HEAD_==1  // any rel (pre 1977, we don't know)
// partner - okay, actually, if partner of head, then head status actually applies to them as well?
// replace rel_type = 0 if relationship==2 & inrange(MARST_DEFACTO_HEAD_,2,5) // unpartnered - does this make sense? if have a label of partner...
replace rel_type = 1 if inrange(survey_yr,1977,2021) & relationship==2 & cohab_est_head==2  // married (def)
replace rel_type = 1 if inrange(survey_yr, 1983,2021) & relationship==2 & RELATION_==20  // married (def) - based on relationship type
replace rel_type = 2 if inrange(survey_yr,1977,2021) & relationship==2 & cohab_est_head==1 // cohab (def)
replace rel_type = 2 if inrange(survey_yr,1983,2021) & relationship==2 & RELATION_==22 // cohab (def)
replace rel_type = 3 if inrange(survey_yr,1968,1976) & relationship==2 // any rel (pre 1977, we don't know)
// all others (based on being in a marital pair). but, don't know what is the type
replace rel_type = 0 if relationship==3 & MARITAL_PAIRS==0
replace rel_type = 3 if relationship==3 &inrange(MARITAL_PAIRS,1,4)

label define rel_type 0 "unpartnered" 1 "married" 2 "cohab" 3 "all rels (pre-1977)"
label values rel_type rel_type

tab rel_type in_sample, m
tab rel_type partnered, m 
tab rel_type partnered if in_sample==1, m 
tab MARST_DEFACTO_HEAD relationship if partnered==1 & rel_type==0

replace partnered=0 if rel_type==0 & partnered==. // sometimes people move out bc of a breakup and become non-response; I am not currently capturing them

// relationship transitions - OBSERVED
sort unique_id wave
// start rel - observed
gen rel_start=0
replace rel_start=1 if partnered==0 & partnered[_n+1]==1 & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

gen marriage_start=0 // from unpartnered, NOT cohabiting
replace marriage_start=1 if rel_type==0 & rel_type[_n+1]==1 & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

gen cohab_start=0
replace cohab_start=1 if rel_type==0 & rel_type[_n+1]==2 & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

// end rel - observed
/*
gen rel_end=0
replace rel_end=1 if partnered==0 & partnered[_n-1]==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen marriage_end=0
replace marriage_end=1 if rel_type==0 & rel_type[_n-1]==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen cohab_end=0
replace cohab_end=1 if rel_type==0 & rel_type[_n-1]==2 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1
*/

gen rel_end=0
replace rel_end=1 if partnered==1 & partnered[_n+1]==0 & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

gen marriage_end=0
replace marriage_end=1 if rel_type==1 & rel_type[_n+1]==0 & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

gen cohab_end=0
replace cohab_end=1 if rel_type==2 & rel_type[_n+1]==0 & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

browse unique_id survey_yr SAMPLE in_sample hh_status_ relationship partnered rel_type rel_start marriage_start cohab_start rel_end marriage_end cohab_end YR_NONRESPONSE_FIRST

// merge on marital history - bc in order of prio, it should be marital history for marriages observed, then other variables for not in marital history or cohabitation.
merge m:1 unique_id using "$temp_psid\marital_history_wide.dta"
drop if _merge==2

gen in_marital_history=0
replace in_marital_history=1 if _merge==3
drop _merge

browse unique_id survey_yr has_psid_gene SAMPLE in_sample hh_status_ relationship partnered rel_type rel_start rel_end rel_end hh_status_ moved MOVED_YEAR_ SPLITOFF_YEAR_  YR_NONRESPONSE_FIRST permanent_attrit mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 ANY_ATTRITION COMPOSITION_CHANGE_ MOVED_

** now add estimated relationship dates - based on OBSERVATIONS
// need to create indicator of relationship that started when person entered, so that can be considered rel1 GAH
browse unique_id survey_yr in_sample hh_status rel_type

bysort unique_id: egen first_survey_yr= min(survey_yr) if in_sample==1
bysort unique_id (first_survey_yr): replace first_survey_yr=first_survey_yr[1]
tab first_survey_yr, m
bysort unique_id: egen last_survey_yr= max(survey_yr) if in_sample==1
bysort unique_id (last_survey_yr): replace last_survey_yr=last_survey_yr[1]
tab last_survey_yr, m

sort unique_id survey_yr
browse unique_id survey_yr in_sample hh_status rel_type first_survey_yr last_survey_yr YR_NONRESPONSE_RECENT YR_NONRESPONSE_FIRST 

// all relationships 
gen relationship_start = survey_yr if rel_start==1
replace relationship_start = survey_yr if survey_yr == first_survey_yr & partnered==1

bysort unique_id: egen relno=rank(relationship_start)
tab relno, m
browse unique_id survey_yr partnered rel_type rel_start relationship_start relno FIRST_MARRIAGE_YR_START

gen rel1_start=.
replace rel1_start=relationship_start if relno==1 
bysort unique_id (rel1_start): replace rel1_start=rel1_start[1]
gen rel2_start=.
replace rel2_start=relationship_start if relno==2 
bysort unique_id (rel2_start): replace rel2_start=rel2_start[1]
gen rel3_start=.
replace rel3_start=relationship_start if relno==3
bysort unique_id (rel3_start): replace rel3_start=rel3_start[1]
gen rel4_start=.
replace rel4_start=relationship_start if relno==4
bysort unique_id (rel4_start): replace rel4_start=rel4_start[1]
gen rel5_start=.
replace rel5_start=relationship_start if relno==5
bysort unique_id (rel5_start): replace rel5_start=rel5_start[1]

sort unique_id survey_yr
browse unique_id survey_yr partnered rel_type rel_start relationship_start relno rel1_start FIRST_MARRIAGE_YR_START rel2_start

gen relationship_end = survey_yr if rel_end==1
bysort unique_id: egen exitno=rank(relationship_end)
browse unique_id survey_yr partnered rel_type rel_start relationship_start rel_end relationship_end relno exitno

gen rel1_end=.
replace rel1_end=relationship_end if exitno==1
bysort unique_id (rel1_end): replace rel1_end=rel1_end[1]
gen rel2_end=.
replace rel2_end=relationship_end if exitno==2
bysort unique_id (rel2_end): replace rel2_end=rel2_end[1]
gen rel3_end=.
replace rel3_end=relationship_end if exitno==3
bysort unique_id (rel3_end): replace rel3_end=rel3_end[1]
gen rel4_end=.
replace rel4_end=relationship_end if exitno==4
bysort unique_id (rel4_end): replace rel4_end=rel4_end[1]
gen rel5_end=.
replace rel5_end=relationship_end if exitno==5
bysort unique_id (rel5_end): replace rel5_end=rel5_end[1]

sort unique_id survey_yr
browse unique_id survey_yr rel_type rel_start relationship_start rel_end relationship_end relno exitno rel1_start rel1_end rel2_start rel2_end mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2

// marriages
gen marriage_start_yr = survey_yr if marriage_start==1
replace marriage_start_yr = survey_yr if survey_yr == first_survey_yr & rel_type==1

bysort unique_id: egen marrno=rank(marriage_start_yr)
tab marrno, m
browse unique_id survey_yr partnered rel_type marriage_start marriage_start_yr marrno FIRST_MARRIAGE_YR_START

gen marr1_start=.
replace marr1_start=marriage_start_yr if marrno==1 
bysort unique_id (marr1_start): replace marr1_start=marr1_start[1]
gen marr2_start=.
replace marr2_start=marriage_start_yr if marrno==2 
bysort unique_id (marr2_start): replace marr2_start=marr2_start[1]
gen marr3_start=.
replace marr3_start=marriage_start_yr if marrno==3
bysort unique_id (marr3_start): replace marr3_start=marr3_start[1]
gen marr4_start=.
replace marr4_start=marriage_start_yr if marrno==4
bysort unique_id (marr4_start): replace marr4_start=marr4_start[1]
gen marr5_start=.
replace marr5_start=marriage_start_yr if marrno==5
bysort unique_id (marr5_start): replace marr5_start=marr5_start[1]

sort unique_id survey_yr
browse unique_id survey_yr partnered rel_type marriage_start marriage_start_yr marrno marr1_start FIRST_MARRIAGE_YR_START marr2_start

gen marriage_end_yr = survey_yr if marriage_end==1
bysort unique_id: egen marr_exitno=rank(marriage_end_yr)
browse unique_id survey_yr partnered rel_type marriage_start marriage_start_yr marriage_end marriage_end_yr marrno marr_exitno

gen marr1_end=.
replace marr1_end=marriage_end_yr if marr_exitno==1
bysort unique_id (marr1_end): replace marr1_end=marr1_end[1]
gen marr2_end=.
replace marr2_end=marriage_end_yr if marr_exitno==2
bysort unique_id (marr2_end): replace marr2_end=marr2_end[1]
gen marr3_end=.
replace marr3_end=marriage_end_yr if marr_exitno==3
bysort unique_id (marr3_end): replace marr3_end=marr3_end[1]
gen marr4_end=.
replace marr4_end=marriage_end_yr if marr_exitno==4
bysort unique_id (marr4_end): replace marr4_end=marr4_end[1]
gen marr5_end=.
replace marr5_end=marriage_end_yr if marr_exitno==5
bysort unique_id (marr5_end): replace marr5_end=marr5_end[1]

sort unique_id survey_yr
browse unique_id survey_yr rel_type marriage_start marriage_start_yr marriage_end marriage_end_yr marrno marr_exitno marr1_start marr1_end marr2_start marr2_end mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2

// cohab
gen cohab_start_yr = survey_yr if cohab_start==1
replace cohab_start_yr = survey_yr if survey_yr == first_survey_yr & rel_type==2

bysort unique_id: egen cohno=rank(cohab_start_yr)
tab cohno, m
browse unique_id survey_yr partnered rel_type cohab_start cohab_start_yr cohno

gen coh1_start=.
replace coh1_start=cohab_start_yr if cohno==1 
bysort unique_id (coh1_start): replace coh1_start=coh1_start[1]
gen coh2_start=.
replace coh2_start=cohab_start_yr if cohno==2 
bysort unique_id (coh2_start): replace coh2_start=coh2_start[1]
gen coh3_start=.
replace coh3_start=cohab_start_yr if cohno==3
bysort unique_id (coh3_start): replace coh3_start=coh3_start[1]

sort unique_id survey_yr
browse unique_id survey_yr partnered rel_type cohab_start cohab_start_yr cohno coh1_start coh2_start

gen cohab_end_yr = survey_yr if cohab_end==1
bysort unique_id: egen coh_exitno=rank(cohab_end_yr)
browse unique_id survey_yr partnered rel_type cohab_start cohab_start_yr cohab_end cohab_end_yr cohno coh_exitno

gen coh1_end=.
replace coh1_end=cohab_end_yr if coh_exitno==1
bysort unique_id (coh1_end): replace coh1_end=coh1_end[1]
gen coh2_end=.
replace coh2_end=cohab_end_yr if coh_exitno==2
bysort unique_id (coh2_end): replace coh2_end=coh2_end[1]
gen coh3_end=.
replace coh3_end=cohab_end_yr if coh_exitno==3
bysort unique_id (coh3_end): replace coh3_end=coh3_end[1]

sort unique_id survey_yr
browse unique_id survey_yr rel_type cohab_start cohab_start_yr cohab_end cohab_end_yr cohno coh_exitno coh1_start coh1_end coh2_start coh2_end mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2

********************************************************************************
* Now, need to try to get more accurate relationship dates
********************************************************************************

browse unique_id survey_yr has_psid_gene in_sample first_survey_yr last_survey_yr partnered rel_type rel1_start rel1_end rel2_start rel2_end moved change_yr hh1_start hh1_end hh2_start hh2_end YR_NONRESPONSE_FIRST YR_NONRESPONSE_RECENT permanent_attrit mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 ANY_ATTRITION COMPOSITION_CHANGE_ MOVED_

preserve 

collapse 	(mean) rel1_start rel2_start rel3_start rel4_start rel5_start rel1_end rel2_end rel3_end rel4_end rel5_end /// created rel variables
					marr1_start marr2_start marr3_start marr4_start marr5_start marr1_end marr2_end marr3_end marr4_end marr5_end ///
					coh1_start coh2_start coh3_start coh1_end coh2_end coh3_end ///
					hh1_start hh2_start hh3_start hh4_start hh5_start hh1_end hh2_end hh3_end hh4_end hh5_end /// based on move in / move out
					mh_yr_married1 mh_yr_married2 mh_yr_married3 mh_yr_married4 mh_yr_married5 mh_yr_married6 mh_yr_married7 mh_yr_married8 mh_yr_married9 mh_yr_married12 mh_yr_married13 /// marital history variables
					mh_yr_end1 mh_yr_end2 mh_yr_end3 mh_yr_end4 mh_yr_end5 mh_yr_end6 mh_yr_end7 mh_yr_end8 mh_yr_end9 mh_yr_end12 mh_yr_end13  ///
					mh_status1 mh_status2 mh_status3 mh_status4 mh_status5 mh_status6 mh_status7 mh_status8 mh_status9 mh_status12 mh_status13 ///
					first_survey_yr last_survey_yr YR_NONRESPONSE_FIRST YR_NONRESPONSE_RECENT ///
			(max) partnered in_marital_history /// get a sense of ever partnered
, by(unique_id has_psid_gene SAMPLE)

gen partner_id = unique_id // for later matching
**# Create file
save "$created_data_psid\psid_composition_history.dta", replace

restore

use "$created_data_psid\psid_composition_history.dta", clear
tab rel1_start partnered, m // do most ever partnered people at least have rel1 start date?
tab hh1_start has_psid_gene, m
tab SAMPLE has_psid_gene, m

browse unique_id has_psid_gene SAMPLE partnered in_marital_history first_survey_yr last_survey_yr YR_NONRESPONSE_FIRST YR_NONRESPONSE_RECENT hh1_start hh1_end hh2_start hh2_end rel1_start rel1_end rel2_start rel2_end mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2

********************************************************************************
********************************************************************************
**# Using family matrix
********************************************************************************
********************************************************************************

********************************************************************************
* Just cohabitation
********************************************************************************

use "$PSID\family_matrix_68_21.dta", clear // relationship matrix downloaded from PSID site

unique MX5 MX6 // should match the 82000 in other file? -- okay so it does. I am dumb because I restricted to only partners. omg this explains evertything

rename MX5 ego_1968_id 
rename MX6 ego_per_num
recode MX7 (1=1)(2=2)(3/8=3)(9=2)(10=1)(11/19=3)(20/22=2)(23/87=3)(88=2)(89/120=3), gen(ego_rel) // ego relationship to ref. because also only really useful if one is reference person bc otherwise i don't get a ton of info about them
recode MX12 (1=1)(2=2)(3/8=3)(9=2)(10=1)(11/19=3)(20/22=2)(23/87=3)(88=2)(89/120=3), gen(alter_rel) // alter relationship to ref

label define rels 1 "Ref" 2 "Spouse/Partner" 3 "Other"
label values ego_rel alter_rel rels

gen partner_1968_id = MX10 if MX8==22
gen partner_per_num = MX11 if MX8==22
gen unique_id = (ego_1968_id*1000) + ego_per_num // how they tell you to identify in main file
// egen ego_unique = concat(ego_1968_id ego_per_num), punct(_)
// egen partner_unique = concat(partner_1968_id partner_per_num), punct(_)
gen partner_unique_id = (partner_1968_id*1000) + partner_per_num

// try making specific variable to match E30002 that is 1968 id? but what if not in 1968??

keep if MX8==22

browse MX2 ego_1968_id ego_per_num unique_id partner_1968_id partner_per_num partner_unique_id MX8 // does unique_id track over years? or just 1 record per year? might this be wrong?

keep MX2 ego_1968_id ego_per_num unique_id partner_1968_id partner_per_num partner_unique_id MX8

// seeing if not working because needs to be LONG 
reshape wide partner_1968_id partner_per_num partner_unique_id MX8, i(ego_1968_id ego_per_num unique_id) j(MX2)

// for ego - will match on unique_id? need to figure out how to match partner, keep separate?
rename ego_1968_id main_per_id
rename ego_per_num INTERVIEW_NUM_

gen spouse_per_num_all = INTERVIEW_NUM_
gen spouse_id_all = main_per_id
gen INTERVIEW_NUM_1968 = INTERVIEW_NUM_

// okay so not JUST the ids, but also YEAR?!  unique MX2 main_per_id INTERVIEW_NUM_
// rename MX2 survey_yr

unique main_per_id INTERVIEW_NUM_1968

save "$data_tmp\PSID_partner_history.dta", replace // really this is just cohabitation NOT marriages.

********************************************************************************
* All relationships
********************************************************************************

use "$PSID\family_matrix_68_19.dta", clear // relationship matrix downloaded from PSID site

unique MX5 MX6 // should match the 82000 in other file? -- okay so it does. I am dumb because I restricted to only partners. omg this explains evertything

rename MX5 ego_1968_id 
rename MX6 ego_per_num
gen unique_id = (ego_1968_id*1000) + ego_per_num // how they tell you to identify in main file
// egen ego_unique = concat(ego_1968_id ego_per_num), punct(_)
// egen partner_unique = concat(partner_1968_id partner_per_num), punct(_)

recode MX7 (1=1)(2=2)(3/8=3)(9=2)(10=1)(11/19=3)(20/22=2)(23/87=3)(88=2)(89/120=3), gen(ego_rel) // ego relationship to ref. because also only really useful if one is reference person bc otherwise i don't get a ton of info about them
recode MX12 (1=1)(2=2)(3/8=3)(9=2)(10=1)(11/19=3)(20/22=2)(23/87=3)(88=2)(89/120=3), gen(alter_rel) // alter relationship to ref

label define rels 1 "Ref" 2 "Spouse/Partner" 3 "Other"
label values ego_rel alter_rel rels

// for now, will see if splitting types or keeping together makes sense, need to wrap my head around this file
gen cohab_1968_id = MX10 if MX8==22
gen cohab_per_num = MX11 if MX8==22
gen cohab_unique_id = (cohab_1968_id*1000) + cohab_per_num

gen spouse_1968_id = MX10 if MX8==20
gen spouse_per_num = MX11 if MX8==20
gen spouse_unique_id = (spouse_1968_id*1000) + spouse_per_num

gen partner_1968_id = MX10 if MX8==22 | MX8==20
gen partner_per_num = MX11 if MX8==22 | MX8==20
gen partner_unique_id = (partner_1968_id*1000) + partner_per_num

// try making specific variable to match E30002 that is 1968 id? but what if not in 1968??

keep if MX8==22 | MX8==20

browse MX2 ego_1968_id ego_per_num ego_rel unique_id cohab_1968_id cohab_per_num cohab_unique_id spouse_1968_id spouse_per_num spouse_unique_id partner_1968_id partner_per_num partner_unique_id alter_rel MX8 // does unique_id track over years? or just 1 record per year? might this be wrong?

keep MX2 ego_1968_id ego_per_num unique_id cohab_1968_id cohab_per_num cohab_unique_id spouse_1968_id spouse_per_num spouse_unique_id partner_1968_id partner_per_num partner_unique_id MX8 ego_rel alter_rel

// seeing if not working because needs to be WIDE
*one person has two spouses, one seems to be an error so dropping that row
drop if ego_1968_id == 1821 & ego_per_num == 170 & MX2==1977 & partner_unique_id== 1821004
 
reshape wide ego_rel cohab_1968_id cohab_per_num cohab_unique_id spouse_1968_id spouse_per_num spouse_unique_id partner_1968_id partner_per_num partner_unique_id alter_rel MX8, i(ego_1968_id ego_per_num unique_id) j(MX2)

// for ego - will match on unique_id? need to figure out how to match partner, keep separate? what is happening here? I think it's because in other file, I have matched husband and wife so want to be able to first match on husband, then match on wife, so need two ids. Same id, but one name for use for husband and one for wife. don't think I need this for current purposes, but might need to rename the ego ones to match back to individual file.
rename ego_1968_id main_per_id
rename ego_per_num INTERVIEW_NUM_
gen INTERVIEW_NUM_1968 = INTERVIEW_NUM_

/*
gen spouse_per_num_all = INTERVIEW_NUM_
gen spouse_id_all = main_per_id
gen INTERVIEW_NUM_1968 = INTERVIEW_NUM_
*/

// okay so not JUST the ids, but also YEAR?!  unique MX2 main_per_id INTERVIEW_NUM_
// rename MX2 survey_yr

unique main_per_id INTERVIEW_NUM_1968

save "$data_tmp\PSID_union_history.dta", replace

browse main_per_id INTERVIEW_NUM_ unique_id MX8* partner_1968_id* partner_per_num* partner_unique_id*
// compare to this:  "$data_keep\PSID_union_history_created.dta"

* Now want to reshape back to long so I can merge info on
drop cohab_1968_id* cohab_per_num* cohab_unique_id* spouse_1968_id* spouse_per_num* spouse_unique_id*

reshape long MX8 ego_rel alter_rel partner_1968_id partner_per_num partner_unique_id, i(main_per_id INTERVIEW_NUM_ unique_id) j(year)

// want to get relationship order
unique partner_unique_id, by(unique_id) gen(rel_num)
drop rel_num

egen couple_num = group(unique_id partner_unique_id)

//https://www.statalist.org/forums/forum/general-stata-discussion/general/1437910-trying-to-rank-numbers-without-gaps
sort unique_id year
by unique_id: egen rank = rank(partner_unique_id), track
egen help_var = group(unique_id rank)

bysort unique_id (rank): gen rel_num = sum(rank != rank[_n-1]) if rank != .

// now do same thing specifically for MARRIAGE order
sort unique_id year
by unique_id: egen marr_rank = rank(partner_unique_id) if MX8==20, track
egen marr_help_var = group(unique_id marr_rank)

bysort unique_id (marr_rank): gen marr_num = sum(marr_rank != marr_rank[_n-1]) if marr_rank != .

drop rank help_var marr_rank marr_help_var

save "$data_tmp\PSID_relationship_list_tomatch.dta", replace