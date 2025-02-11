********************************************************************************
********************************************************************************
* Project: Data Creation: GSOEP
* Owner: Kimberly McErlean
* Started: September 2024
* File: get_data
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This files gets the data from the GSOEP and reorganizes it for analysis

net install soephelp,from("https://git.soep.de/mpetrenz/soephelp/-/raw/master/") replace

********************************************************************************
* First, let's just get a sense of data structure and start to clean up files
* Individual files
********************************************************************************
// individual file
use "$GSOEP/pl.dta", clear
label language EN

unique pid // 104742, 763223
tab syear, m

keep pid syear hid cid intid pld0131_h plb0295 plb0158 plb0592 plb0186_h plb0241_h plb0185_v1 plb0185_v2 pab0008 pab0013 pab0002 pab0004 pab0005 plb0022_h plb0019_v1 plb0019_v2 plb0193 plb0197 plb0196_h plc0013_h plb0471_h plc0015_h plb0474_h plc0154 plc0017_h plb0477_h pld0152 pld0153 pld0154 pld0038 pld0039 pld0040 pld0159 pld0140 pld0141 pld0142 pld0134 pld0135 pld0136 pld0137 pld0138 pld0139 pld0149 pld0150 pld0151 pld0143 pld0144 pld0145 pld0132_h pld0133 plk0001_v1 plk0001_v2 plk0001_v3 plk0001_v4 plk0001_v5 pli0044_h pli0019_h pli0022_h pli0043_h pli0012_h pli0016_h pli0049_h pli0031_h pli0034_v1 pli0034_v2 pli0034_v3 pli0034_v4 pli0051 pli0036 pli0010 pli0040 pli0054 pli0011 pli0046 pli0055 pli0057 pli0047_v1 pli0047_v2 pli0047_v3 pli0024_h pli0028_h pli0038_v1 pli0038_v2 pli0038_v3 pli0038_v4 plb0156_v1 plb0157_v1 plb0157_v2 ple0040 ple0041 ple0008 plg0072 plg0073 plg0074 plg0078_h p_degree_v1 p_degree_v2 p_degree_v3 plg0012_h plg0013_h plg0014_v1 plg0014_v2 plg0014_v3 plg0014_v4 plg0014_v5 plg0014_v6 plg0014_v7 plh0395i01 plh0395i02 plh0395i03 plh0395i04 plh0395i05 plh0395i06 plh0182 plh0007 plh0012_h plh0013_h plh0258_h plh0173 plh0174 plh0179 plh0178 plh0176 plh0175 plh0180

// mvdecode _all, mv(-8/-1) // do I want to retain -2 in some way bc it designates does not apply (so helps figure out who is in sample in a given question?)
// recode * (-8=.s)(-7/-6=.)(-5=.s)(-4/-3=.)(-2=.n)(-1=.) 
mvdecode _all, mv(-8=.s\-7/-6=.\-5=.s\-4/-3=.\-2=.n\-1=.) // .s = not in survey, .n is n/a, regular missing is dk, etc.

rename pld0131_h marst
rename plb0295 jobchg_children
rename plb0158 distance_work_km
rename plb0592 commuting_time_min
rename plb0186_h hours_per_wk
rename plb0241_h desired_hours
rename plb0185_v1 hours_contracted_v1
rename plb0185_v2 hours_contracted_v2
rename pab0008 py_housewife
rename pab0013 py_inschool
rename pab0002 py_employed_pt
rename pab0004 py_unemployed
rename pab0005 py_retired
rename plb0022_h employment
rename plb0019_v1 onleave_v1
rename plb0019_v2 onleave_v2
rename plb0193 work_ot
rename plb0197 hours_ot
rename plb0196_h work_ot_lastmonth
rename plc0013_h gross_income_lastmonth
rename plb0471_h gross_salary_ly
rename plc0015_h salary_received_ly
rename plb0474_h gross_selfincome_ly
rename plc0154 months_parental_allowance
rename plc0017_h net_wages_ly
rename plb0477_h gross_salary2_ly
rename pld0152 chg_hadbirth
rename pld0153 chg_hadbirth_month
rename pld0154 chg_hadbirth_month_py
rename pld0038 chg_newpartner
rename pld0039 chg_newpartner_month
rename pld0040 chg_newpartner_month_py
rename pld0159 nochg_composition
rename pld0140 chg_divorced
rename pld0141 chg_divorced_month
rename pld0142 chg_divorced_month_py
rename pld0134 chg_married
rename pld0135 chg_married_month
rename pld0136 chg_married_month_py
rename pld0137 chg_cohabit
rename pld0138 chg_cohabit_month
rename pld0139 chg_cohabit_month_py
rename pld0149 chg_childleft
rename pld0150 chg_childleft_month
rename pld0151 chg_childleft_month_py
rename pld0143 chg_separated
rename pld0144 chg_separated_month
rename pld0145 chg_seaprated_month_py
rename pld0132_h partnered
rename pld0133 partner_in_hh
rename plk0001_v1 partnerid_v1
rename plk0001_v2 partnerid_v2
rename plk0001_v3 partnerid_v3
rename plk0001_v4 partnerid_v4
rename plk0001_v5 partnerid_v5
rename pli0044_h childcare_weekdays
rename pli0019_h childcare_saturdays
rename pli0022_h childcare_sundays
rename pli0043_h housework_weekdays
rename pli0012_h housework_saturdays
rename pli0016_h housework_sundayss
rename pli0049_h repair_weekdays
rename pli0031_h repair_saturdays
rename pli0034_v1 repair_sundays_v1
rename pli0034_v2 repair_sundays_v2
rename pli0034_v3 repair_sundays_v3
rename pli0034_v4 repair_sundays_v4
rename pli0051 leisure_weekdays
rename pli0036 leisure_saturdays
rename pli0010 leisure_sundays
rename pli0040 errands_weekdays
rename pli0054 errands_saturdays
rename pli0011 errands_sundays
rename pli0046 support_weekdays
rename pli0055 support_saturdays
rename pli0057 support_sundays
rename pli0047_v1 education_weekdays_v1
rename pli0047_v2 education_weekdays_v2
rename pli0047_v3 education_weekdays_v3
rename pli0024_h education_saturdays
rename pli0028_h education_sundays
rename pli0038_v1 working_weekdays_v1
rename pli0038_v2 working_weekdays_v2
rename pli0038_v3 working_weekdays_v3
rename pli0038_v4 working_weekdays_v4
rename plb0156_v1 wfh
rename plb0157_v1 commutes_v1
rename plb0157_v2 commutes_v2
rename ple0040 disability_yn
rename ple0041 disability_det
rename ple0008 self_reported_health
rename plg0072 new_education
rename plg0073 new_education_month_py
rename plg0074 new_education_month
rename plg0078_h new_education_type
rename p_degree_v1 new_education_degree_v1
rename p_degree_v2 new_education_degree_v2
rename p_degree_v3 new_education_degree_v3
rename plg0012_h current_education
rename plg0013_h current_education_type_gened
rename plg0014_v1 current_education_type_univ_v1
rename plg0014_v2 current_education_type_univ_v2
rename plg0014_v3 current_education_type_univ_v3
rename plg0014_v4 current_education_type_univ_v4
rename plg0014_v5 current_education_type_univ_v5
rename plg0014_v6 current_education_type_univ_v6
rename plg0014_v7 current_education_type_univ_v7
rename plh0395i01 attitudes_legislator
rename plh0395i02 attitudes_biosex
rename plh0395i03 attitudes_intersex
rename plh0395i04 attitudes_sexassign
rename plh0395i05 attitudes_gendertype
rename plh0395i06 attitudes_samesex
rename plh0182 life_satisfaction
rename plh0007 politics_interest
rename plh0012_h politics_affiliation
rename plh0013_h politics_intensity
rename plh0258_h religious_affiliation
rename plh0173 satisfaction_work
rename plh0174 satisfaction_housework
rename plh0179 satisfaction_childcare
rename plh0178 satisfaction_leisure
rename plh0176 satisfaction_income
rename plh0175 satisfaction_hhincome
rename plh0180 satisfaction_family

save "$temp/pl_cleaned.dta", replace

// individual generated variables
use "$GSOEP/pgen.dta", clear
label language EN

unique pid // 106778, 771210
tab syear, m
sort pid syear

browse pid syear hid cid pgfamstd pgpartz pgpartnr pgemplst pglfs pgtatzeit pglabgro pglabnet
keep pid syear hid cid pgfamstd pgpartz pgpartnr pgpbbil02 pgpsbil pgdegree pglabgro pglabnet pgemplst pglfs pgtatzeit pgvebzeit pguebstd pgisced11 pgisced97 pgpsbil pgpbbil02

rename pgfamstd marital_status_pg
rename pgpartz partnered_pg
rename pgpartnr partner_id_pg
rename pgpbbil02 college_type_pg
rename pgpsbil last_degree_pg
rename pgdegree tertiary_type_pg
rename pglabgro gross_labor_inc_pg
rename pglabnet net_labor_inc_pg
rename pgemplst emplst_pg
rename pglfs laborforce_pg
rename pgtatzeit work_hours_pg
rename pgvebzeit work_hours_agreed_pg
rename pguebstd overtime_pg
rename pgisced11 isced11_pg
rename pgisced97 isced97_pg

save "$temp/pgen_cleaned.dta", replace

// individual tracking file
use "$GSOEP/ppathl.dta", clear
label language EN

unique pid // 158946, 1285062
tab syear, m

/*Netto-codes 10-19 (and 29) define the respondents population of PGEN,
the codes 20-28 indicate children,
30-39 unit-non-responses in partially realized households,
and the codes 90-99 describe permanent (or temporary) dropouts.
Further differentiations point to the survey instruments (questionnaires). 
The Codes 10-39 describe the population in realized (and partially realized households).*/

recode netto (10/19=1)(20/29=2)(30/39=3)(40/99=0)(-3=0), gen(status)
label define status 0 "dropout" 1 "sample" 2 "youth" 3 "no int"
label values status status

sort pid syear
keep pid syear hid cid sex parid partner gebjahr eintritt erstbefr austritt letztbef psample status netto sampreg

rename sex sex_pl
rename parid partner_id_pl
rename partner partnered_pl
rename gebjahr birthyr_pl
rename eintritt firstyr_contact_pl
rename erstbefr firstyr_survey_pl
rename austritt lastyr_contact_pl
rename letztbef lastyr_survey_pl
rename psample psample_pl
rename status status_pl
rename netto status_detailed_pl
rename sampreg where_germany_pl

browse

save "$temp/ppathl_cleaned.dta", replace

// for use later to add partner sample status
keep pid syear sex_pl status_pl
rename pid parid // to match to partner id
rename status_pl status_sp
rename sex sex_sp

save "$temp/ppathl_partnerstatus.dta", replace

********************************************************************************
**# use ppathl to create base couple-level file to use as my master file 
* to merge rest of characteristics onto
********************************************************************************

use "$GSOEP/ppathl.dta", clear
label language EN

unique pid parid // 186572
tab syear, m

// sample status
sort pid syear parid 
browse pid syear parid partner netto 

/*Netto-codes 10-19 (and 29) define the respondents population of PGEN,
the codes 20-28 indicate children,
30-39 unit-non-responses in partially realized households,
and the codes 90-99 describe permanent (or temporary) dropouts.
Further differentiations point to the survey instruments (questionnaires). 
The Codes 10-39 describe the population in realized (and partially realized households).*/

recode netto (10/19=1)(20/29=2)(30/39=3)(40/99=0)(-3=0), gen(status)
label define status 0 "dropout" 1 "sample" 2 "youth" 3 "no int"
label values status status

unique pid, by(status) // sample: 106393 - this essentially almost exactly match pgen. do I want to add the 29 (refugees that are not 18?) prob not

// partner vars
replace parid=. if parid==-2
gen partnered=0
replace partnered=1 if inrange(partner,1,4)
replace partnered=. if partner==-2
inspect parid if partnered==1
inspect parid if partnered==0

gen reltype=.
replace reltype=1 if partnered==1 & inlist(partner,1,3)
replace reltype=2 if partnered==1 & inlist(partner,2,4)
label define reltype 1 "married" 2 "cohab"
label values reltype reltype

browse pid syear parid partnered reltype partner status netto 

// relationship transitions
*enter
gen rel_start=0
replace rel_start=1 if partnered==1 & partnered[_n-1]==0 & pid==pid[_n-1] & syear==syear[_n-1]+1

*exit
gen rel_end=0
replace rel_end=1 if partnered==0 & partnered[_n-1]==1 & pid==pid[_n-1] & syear==syear[_n-1]+1

gen rel_end_pre=0
replace rel_end_pre=1 if partnered==1 & partnered[_n+1]==0 & pid==pid[_n+1] & syear==syear[_n+1]-1

*cohab to marr
gen marr_trans=0
replace marr_trans=1 if (reltype==1 & reltype[_n-1]==2) & pid==pid[_n-1] & syear==syear[_n-1]+1 & parid==parid[_n-1]

browse pid syear parid partnered reltype rel_start rel_end* marr_trans

// now restrict to partnered & insample - but first need to get partner in sample info
keep if partnered==1
keep if parid!=.

merge 1:1 parid syear using "$temp/ppathl_partnerstatus.dta"
drop if _merge==2
drop _merge

// browse pid syear parid status status_sp
tab status status_sp, m

keep if status==1 | status_sp==1 // keep if at least one of them is in sample for now. can decide later if should only keep those where *both* in sample.
drop if inlist(sex,-3,-1)
drop if inlist(sex_sp,-3,-1)

// now just clean up variables
keep pid syear hid cid sex sex_sp parid partner gebjahr todjahr eintritt erstbefr austritt letztbef psample status status_sp netto sampreg germborn partnered reltype rel_start rel_end rel_end_pre marr_trans prgroup pbleib phrf phrf0 phrf1

rename parid partner_id
rename gebjahr birthyr
rename todjahr deathyr
rename eintritt firstyr_contact
rename erstbefr firstyr_survey
rename austritt lastyr_contact
rename letztbef lastyr_survey
rename netto status_detailed
rename sampreg where_germany

save "$temp/couples_ppathl.dta", replace

********************************************************************************
* Relationship history files
********************************************************************************
// various relationship history files - figure out if partnership history includes marital history or if these are mutually exclusive? okay def includes marital, and even non-cohab relationships

// couple month \\
use "$GSOEP/biocouplm.dta", clear
label language EN

unique pid // 106432, 183433
unique pid, by(spelltyp) // 63562 married in HH, 19277 coupled in HH
tab spelltyp, m
browse

sum coupid, detail
gen has_coupid=. // should be -2 aka not partnered
replace has_coupid=0 if coupid==-1
replace has_coupid=1 if coupid>0 & coupid!=.

gen partner_in_hh=0
replace partner_in_hh =1 if inlist(spelltyp,1,3,7)
tab partner_in_hh has_coupid, m

tab spelltyp has_coupid, m
tab event has_coupid if partner_in_hh==1, m // none of these really systematically related to who has this info
tab remark has_coupid if partner_in_hh==1, m // none of these really systematically related to who has this info 
tab beginy has_coupid if partner_in_hh==1, m row
tab endy has_coupid if partner_in_hh==1, m row
tab censor has_coupid if partner_in_hh==1, m row

gen left_censored=0
replace left_censored=1 if inlist(censor,1,2,7,8,9,10,11,12,13)

gen right_censored=0
replace right_censored=1 if inrange(censor,3,13)

gen censored_all=1
replace censored_all=0 if censor==0
replace censored_all=. if censor==-2
tab censor censored_all, m

gen intact=0
replace intact=1 if inlist(censor,5,9,13) // last spell? okay, yes, see p 14 of the codebook, very last line; I think this is true (still in SOEP and relationship is open)

gen intact_alt=0
replace intact_alt=1 if pdeath==0 & divorce==0 // think one problem is divorce is OFFICIAl divorce, not separation AND not cohab relationship end. so might those be not apply also? if not a marital relationship?

save "$temp/biocouplm_cleaned.dta", replace

// couple year \\
use "$GSOEP/biocouply.dta", clear // this is my preferred file, but the problem is, it is not comprehensive because not until wave 28
label language EN

unique pid // 48333, 259945
unique pid, by(spelltyp) // 27411 married in HH, 29605 coupled in HH - okay why are there so many more coupled here, but way less married than above?? i dont understand...

gen partner_in_hh=0
replace partner_in_hh =1 if inlist(spelltyp,1,3,7)

// marriage month \\
use "$GSOEP/biomarsm.dta", clear
label language EN

unique pid // 104934, 123937
unique pid, by(spelltyp) // 64354 married in HH,  coupled in HH - duh doesn't track coupled

// marriage year \\
use "$GSOEP/biomarsy.dta", clear // okay, so this file essentially categorizes person's whole life into spells based on their legal maritus status - each row is a new status and is bookended by age / year of that spell - so each "spell" is NOT a new partner; it's a new marital status - aka stay in when divorced, for example

label language EN

unique pid // 105005, 218795
unique pid, by(spelltyp) // 71272 married in HH,  coupled in HH - duh doesn't track coupled

// look at regular biography also?? to see what THAT has for relationship history? because all of these files are different levels with diff levels of accuracy?
use "$GSOEP/biol.dta", clear

unique pid // 94004, 130429
tab syear  // so it is pid year, but a lot of pids don't have multiple year records. Is this just when the history was updated? the codebook is not v. helpful...
sort pid syear
browse pid syear

********************************************************************************
* Other files
********************************************************************************

// household file
use "$GSOEP/hl.dta", clear
label language EN

********************************************************************************
**# * Attempt to at merge all key individual characteristics
********************************************************************************
// first just merge basic individual characteristics
use "$temp/pl_cleaned.dta", clear

merge 1:1 pid hid cid syear using "$temp/pgen_cleaned.dta"
drop if _merge==2
drop _merge

merge 1:1 pid hid cid syear using "$temp/ppathl_cleaned.dta"
drop if _merge==2
drop _merge

// didnt do this above for all, should I just move this here for ease?
mvdecode _all, mv(-8=.s\-7/-6=.\-5=.s\-4/-3=.\-2=.n\-1=.) // .s = not in survey, .n is n/a, regular missing is dk, etc.

gen age = syear-birthyr_pl

// updating labels for some variables that are only in german
label define marst 1 "Married" 2 "Register same-sex" 3 "Single, never married"  4 "Divorced" 5 "Widowed"
label values marst marst

gen marst_defacto=.
replace marst_defacto=1 if inlist(marst,1,2) // married
replace marst_defacto=2 if inrange(marst,2,5) & inrange(partnered_pl,1,4) // partnered
replace marst_defacto=3 if marst==3 & inlist(partnered_pl,0,5)
replace marst_defacto=4 if marst==4 & inlist(partnered_pl,0,5)
replace marst_defacto=5 if marst==5 & inlist(partnered_pl,0,5)
replace marst_defacto=1 if inlist(partnered_pl,1,3) & marst_defacto==.
replace marst_defacto=2 if inlist(partnered_pl,2,4) & marst_defacto==.
replace marst_defacto=3 if inlist(partnered_pl,0,5) & marst_defacto==.

label define marst_defacto 1 "Married" 2 "Partnered" 3 "Never Partnered"  4 "Divorced" 5 "Widowed"
label values marst_defacto marst_defacto

gen partnered_total=0
replace partnered_total=1 if inlist(marst_defacto,1,2)
tab partnered_pl partnered_total, m // some people labeled as married, but don't have partner - maybe partner doesn't live in HH?

// make sure partner ids that came from the two different places (e.g. pg v. pl) match once I compile?
sort pid syear
browse pid hid syear age marst_defacto partnered_pg partner_id_pg partnered_pl partner_id_pl partnerid_v1 partnerid_v2 partnerid_v3 partnerid_v4 partnerid_v5
gen partner_id_check=.
replace partner_id_check=0 if partner_id_pg!=partner_id_pl & partner_id_pg!=.n & partner_id_pg!=.n
replace partner_id_check=1 if partner_id_pg==partner_id_pl & partner_id_pg!=.n & partner_id_pg!=.n

tab marst partnered, m
tab partnered_pg partnered_pl, m // okay, so these match
tab partnered_pl partnered, m // these match less good...is this the annual / month thingg?
tab partnered_pg partnered, m // these match less good...

// then need to do some variable cleanup / recoding / inspecting for core variables before merging with partner info

save "$temp/individ_data.dta", replace
