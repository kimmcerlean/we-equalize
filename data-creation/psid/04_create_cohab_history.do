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

** First create some recodes that will make things easier
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

** Partner recodes
gen partnered=.
replace partnered=0 if in_sample==1 & MARITAL_PAIRS_==0
replace partnered=1 if in_sample==1 & inrange(MARITAL_PAIRS_,1,3)

sort unique_id wave
// start rel - observed
gen rel_start=0
replace rel_start=1 if partnered==1 & partnered[_n-1]==0 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

// end rel - observed
gen rel_end=0
replace rel_end=1 if partnered==0 & partnered[_n-1]==1 & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen rel_end_pre=0
replace rel_end_pre=1 if partnered==1 & partnered[_n+1]==0 & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

// merge on marital history - bc in order of prio, it should be marital history for marriages observed, then other variables for not in marital history or cohabitation.
merge m:1 unique_id using "$temp_psid\marital_history_wide.dta"
drop if _merge==2

gen in_marital_history=0
replace in_marital_history=1 if _merge==3
drop _merge

browse unique_id survey_yr has_psid_gene SAMPLE in_sample hh_status_ relationship partnered rel_start rel_end rel_end_pre hh_status_ moved MOVED_YEAR_ SPLITOFF_YEAR_  YR_NONRESPONSE_FIRST permanent_attrit mh_yr_married1 mh_yr_end1 mh_yr_married2 mh_yr_end2 mh_yr_married3 mh_yr_end3 ANY_ATTRITION COMPOSITION_CHANGE_ MOVED_

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