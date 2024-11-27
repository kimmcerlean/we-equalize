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