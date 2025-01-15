********************************************************************************
********************************************************************************
* Project: Relationship Growth Curves
* Owner: Kimberly McErlean
* Started: September 2024
* File: create sample
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files restricts the full PSID data to the analytical sample
* (cohabiting / married couples)

/*how to identify cohabitors (from FAQ)
Prior to 2017, when a new (opposite sex) romantic partner of Head ('Reference Person' starting in the 2017 wave) moved into the FU (family unit), but had been living there less than 1 year at the time of the interview, that person was labeled a Boyfriend or Girlfriend (code 88). However, if the cohabitor had been living in the FU one year or more, the couple was designated (male)Head and "Wife" (code 22 from 1983 on). If a Girlfriend or Boyfriend was still in the FU in the next wave, and the couple were not married, they became (male) Head and "Wife". If the person who moves in is married to the Head, they are of course, male Head and Wife (code 20), regardless of time living in the FU.

Boyfriends and Girlfriends are treated like other family members who are not Reference Person (`Head' prior to 2017), Spouse or Partner. Considerably less information is obtained about them. In the waves since the late 1970s, information typically gathered for a Spouse has been gathered as well about a Partner ("Wife" before 2017).

Prior to 1983, the Relationship to Head ('Reference Person' starting in the 2017 wave) codes did not distinguish between legal Wives and long-term female cohabitors. However, first year cohabitors can be detected prior to 1983 with a little bit of work. For example, their Relationship to Head would be 8 (nonrelative), their gender would be the opposite of Head's, and in subsequent years they may become Wives or Heads, while the Head would stay as Head or become a Wife. Anyone fitting this pattern can be decisively identified as a cohabitor. PSID did not distinctively label same sex cohabitors prior to 2017.
*/

********************************************************************************
* import data and clean up sample
********************************************************************************
use "$temp_psid\PSID_full_long.dta", clear

sort unique_id survey_yr

replace SEQ_NUMBER_=0 if SEQ_NUMBER==.
bysort id (SEQ_NUMBER_): egen in_sample=max(SEQ_NUMBER_)
drop if in_sample==0 // people with NO DATA in any year

browse unique_id main_per_id survey_yr SEQ_NUMBER_

gen year = survey_yr if SEQ_NUMBER_!=0

bysort unique_id (year): egen first_survey_yr = min(year)
bysort unique_id (year): egen last_survey_yr = max(year)

sort unique_id survey_yr
browse unique_id main_per_id survey_yr SEQ_NUMBER_ SAMPLE first_survey_yr last_survey_yr YR_NONRESPONSE_RECENT YR_NONRESPONSE_FIRST PERMANENT_ATTRITION ANY_ATTRITION

keep if SEQ_NUMBER_!=0 | SAMPLE==1 // dropping non-sample years
drop if SEQ_NUMBER_==0 & survey_yr!=1968

tab first_survey_yr if SAMPLE==1
browse unique_id main_per_id survey_yr SEQ_NUMBER_ SAMPLE first_survey_yr last_survey_yr if SAMPLE==1 & first_survey_yr!=1968
replace first_survey_yr = 1968 if SAMPLE==1 & first_survey_yr==1969
drop if survey_yr==1968 & first_survey_yr!=1968

// want consecutive waves to make some things easier later
egen wave = group(survey_yr)

********************************************************************************
* Identify couples including ref person
********************************************************************************
browse survey_yr RELATION_ RELATION_TO_HEAD_
// RELATION_: pre 1983 - 1=head; 2=wife(but think this includes cohabitors)
// RELATION: starting in 1983 - 10=head; 20=legal wife; 22=cohabitor
// RELATION_TO_HEAD is family level, I am not sure - is this maybe like is the head the same?
// marital status ref - added in 1977, treats cohabitors as married? no I think opposite - legally married onlys (see v5502)
// marital status head - has always been asked, treats cohabitors as married I think? (see v5650)

label define marr_defacto 1 "Partnered" 2 "Single" 3 "Widowed" 4 "Divorced" 5 "Separated"
label values MARST_DEFACTO_HEAD_ marr_defacto

label define marr_legal 1 "Married" 2 "Single" 3 "Widowed" 4 "Divorced" 5 "Separated"
label values MARST_LEGAL_HEAD_ marr_legal

label define couple_status 1 "Married" 2 "Partnered" 3 "Uncooperative" 4 "FY Partnered" 5 "Unpartnered"
label values COUPLE_STATUS_HEAD_ couple_status

gen person=0
replace person=1 if RELATION_==1 & survey_yr<1983
replace person=1 if RELATION_==10 & survey_yr>=1983
replace person=2 if RELATION_==2 & survey_yr<1983
replace person=2 if inlist(RELATION_,20,22) & survey_yr>=1983

tab MARITAL_PAIRS_ person, m
gen cohab_est=0
replace cohab_est=1 if MARST_DEFACTO_HEAD_==1 & inlist(MARST_LEGAL_HEAD_,2,3,4,5) // will only apply after 1977
tab RELATION_ cohab_est if survey_yr>=1977
tab MARST_DEFACTO_HEAD_ cohab_est
tab MARST_LEGAL_HEAD_ cohab_est

gen marital_status_updated=.
replace marital_status_updated=1 if MARST_DEFACTO_HEAD_==1 & cohab_est==0
replace marital_status_updated=2 if MARST_DEFACTO_HEAD_==1 & cohab_est==1
replace marital_status_updated=3 if MARST_DEFACTO_HEAD_==2
replace marital_status_updated=4 if MARST_DEFACTO_HEAD_==3
replace marital_status_updated=5 if MARST_DEFACTO_HEAD_==4
replace marital_status_updated=6 if MARST_DEFACTO_HEAD_==5

label define marital_status_updated 1 "Married (or pre77)" 2 "Partnered" 3 "Single" 4 "Widowed" 5 "Divorced" 6 "Separated"
label values marital_status_updated marital_status_updated

tab survey_yr marital_status_updated, row

browse unique_id survey_yr person RELATION_ COUPLE_STATUS_HEAD_ MARITAL_PAIRS_  marital_status_updated if inlist(person,1,2) // so after 1977 (aka 1977-1983) can perhaps identify cohabitors if husband is not legally married? and validate in 1983 when actually tracked?

// Identify relationship transitions
sort unique_id survey_yr
browse unique_id survey_yr wave

*enter
gen rel_start=0
replace rel_start=1 if (inlist(marital_status_updated,1,2) & inlist(marital_status_updated[_n-1],3,4,5,6)) & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

*exit
gen rel_end=0
replace rel_end=1 if (inlist(marital_status_updated,3,4,5,6) & inlist(marital_status_updated[_n-1],1,2)) & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

gen rel_end_pre=0
replace rel_end_pre=1 if (inlist(marital_status_updated,1,2) & inlist(marital_status_updated[_n+1],3,4,5,6)) & unique_id==unique_id[_n+1] & wave==wave[_n+1]-1

*cohab to marr
gen marr_trans=0
replace marr_trans=1 if (marital_status_updated==1 & marital_status_updated[_n-1]==2) & unique_id==unique_id[_n-1] & wave==wave[_n-1]+1

browse unique_id survey_yr person RELATION_ AGE_INDV_ marital_status_updated MARITAL_PAIRS_ COUPLE_STATUS_HEAD_ rel_start rel_end rel_end_pre marr_trans

// drop non-partnered = BUT i think this is household level, so need to also drop the specific individuals not partnered?
keep if inlist(marital_status_updated,1,2) | rel_start==1 | marr_trans==1 | rel_end==1
drop if person==0
// added that pre_rel_end (so I know it was last year married) - so can delete those with marital status that isn't married or partnered
drop if inlist(marital_status_updated,3,4,5,6)

// so might need to restrict to either 1983 or 1977, because better cohab data?
// drop if survey_yr <1977 // first time you could identify cohab

tab survey_yr marital_status_updated
tab survey_yr rel_start
tab survey_yr rel_end_pre
tab survey_yr marr_trans

// okay how to get duration?! next problem GAH

save "$created_data_psid\PSID_partners.dta", replace
