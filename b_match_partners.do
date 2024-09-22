********************************************************************************
********************************************************************************
* Project: Relative Density Approach - UK
* Code owner: Kimberly McErlean
* Started: September 2024
* File name: b_match_partners.do
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This file uses partner ID to match partner data (where relevant) for our key
* variables of interest.
* NOTE: you should run the macros in file a for this to work. 
* (will work on a separate macro specific file to make this easier)

********************************************************************************
* Import data (created in step a) and do some data cleaning / recoding before creating a file to match partners
********************************************************************************

use "$outputpath/UKHLS_long_all.dta", clear
drop if pidp==. // think these are HHs that didn't match?

// key DoL variables: husits howlng hubuys hufrys huiron humops jbhrs huboss (but in less waves of the old survey)
// key other variables: scend_dv jbstat mastat mastat_dv nchild_dv marstat age age_dv doby doby_dv qfhigh_dv hiqual_dv racel_dv ethn_dv sex sex_dv
// key ID variables: pidp hidp pno
// key linking variables: ppid ppno sppid sppno

** Demographic and related variables
gen survey=.
replace survey=1 if inrange(wavename,1,13)
replace survey=2 if inrange(wavename,14,31)
label define survey 1 "UKHLS" 2 "BHPS"
label values survey survey

tab wavename survey, m

tab sex, m
recode sex (-9/-1=.)

tab age if survey==2, m
tab age_dv if survey==1, m

tab birthy, m
tab doby if survey==2, m
tab doby_dv if survey==1, m
browse pidp survey birthy doby age doby_dv age_dv

gen age_all=.
replace age_all = age if survey==2
replace age_all = age_dv if survey==1
replace age_all = . if age_all==-9
tab age_all, m

gen dob_year=.
replace dob_year = doby if survey==2
replace dob_year = doby_dv if survey==1
replace dob_year = . if inrange(dob_year,-9,-1)
tab dob_year, m

tab hiqual_dv survey, m // both
replace hiqual_dv=. if inlist(hiqual_dv,-8,-9)
tab qfhigh_dv survey, m // this is only ukhls
// education coding from Musick et al: In the BHPS and SOEP, we use the 1997 International Standard Classification of Education (ISCED) guidelines to identify bachelor's degree equivalents as the completion of tertiary education programs, excluding higher vocational programs (UNESCO Institute for Statistics [1997] 2006). 
// other educations: qfachi (bhps only) qfedhi (bhps only - details) qfhigh (not v good) qfhigh_dv (ukhls details) hiqual_dv hiqualb_dv (bhps only)

tab racel survey, m
tab racel_dv survey, m // ukhls - but one the survey says to use I think
tab race survey, m // not helpful
tab racel_bh survey, m // this doesn't feel helpful either
tab ethn_dv survey, m // okay, need to figure out a bhps race variable...
// might need to combine these two: race (BH01-12) racel_bh (BH13-18) or get racel_dv_all from xwavedat

// so many marital statuses STILL
tab mlstat survey, m // present legal marital status - has a lot of inapplicable, so doesn't seem right - think only for new people?
tab marstat survey, m  // legal marital status -- only for ukhls, doesn't seem to include cohabiting
tab marstat_dv survey, m // harmonized de facto - includes cohabiting, but only ukhls
tab mastat_dv survey, m // de facto - confused, because also only ukhls, so think above is better / cleaner?
tab currmstat survey, m // current legal marital status - many missings, think this wasn't added until later
tab mlstat_bh survey, m // present legal marital status - so this is bhps legal
tab mastat survey, m // marital status - okay this has cohabiting for bhps

fre mlstat_bh // 1 married, 2 sep, 3 divorced, 4 widowed, 5 never married
fre marstat // 1 never married, 2 married, 3 civil partnership, 4 separated, 5 divorced, 6 widowed, 7 sep civil, 8 divorced civil, 9 widow civil
gen marital_status_legal=. // use mlstat_bh for bhps; marstat for ukhls, but need to recode because not currently on same scale
* populate for bhps
replace marital_status_legal = 1 if survey==2 & mlstat_bh==1
replace marital_status_legal = 2 if survey==2 & mlstat_bh==2
replace marital_status_legal = 3 if survey==2 & mlstat_bh==3
replace marital_status_legal = 4 if survey==2 & mlstat_bh==4
replace marital_status_legal = 5 if survey==2 & mlstat_bh==5
* populate for ukhls
replace marital_status_legal = 1 if survey==1 & inlist(marstat,2,3) // married, including civil partner
replace marital_status_legal = 2 if survey==1 & inlist(marstat,4,7) // sep, including civil
replace marital_status_legal = 3 if survey==1 & inlist(marstat,5,8) // divorced, including civil
replace marital_status_legal = 4 if survey==1 & inlist(marstat,6,9) // widowed, including civil
replace marital_status_legal = 5 if survey==1 & marstat==1 // never married including civil
tab marital_status_legal, m // most of these missing are proxy interviews from ukhls
tab age_all marital_status_legal, m
tab mlstat_bh marital_status_legal, m
tab marstat marital_status_legal, m

label define marital_status_legal 1 "Married" 2 "Separated" 3 "Divorced" 4 "Widowed" 5 "Never Married"
label values marital_status_legal marital_status_legal

fre mastat // 1 married, 2 cohab, 3 widowed, 4 divorced, 5 separated, 6 never married
fre marstat_dv // 1 married, 2 cohab, 3 widowed, 4 divorced, 5 separated, 6 never married
gen marital_status_defacto=. // use mastat for bhps; marstat_dv for ukhls, but need to recode because not currently on same scale
* populate for bhps
replace marital_status_defacto = 1 if survey==2 & mastat==1
replace marital_status_defacto = 2 if survey==2 & mastat==2
replace marital_status_defacto = 3 if survey==2 & mastat==5
replace marital_status_defacto = 4 if survey==2 & mastat==4
replace marital_status_defacto = 5 if survey==2 & mastat==3
replace marital_status_defacto = 6 if survey==2 & mastat==6
* populate for ukhls
replace marital_status_defacto = 1 if survey==1 & marstat_dv==1
replace marital_status_defacto = 2 if survey==1 & marstat_dv==2
replace marital_status_defacto = 3 if survey==1 & marstat_dv==5
replace marital_status_defacto = 4 if survey==1 & marstat_dv==4
replace marital_status_defacto = 5 if survey==1 & marstat_dv==3
replace marital_status_defacto = 6 if survey==1 & marstat_dv==6

tab marital_status_defacto, m
tab age_all marital_status_defacto, m
tab mastat marital_status_defacto, m
tab marstat_dv marital_status_defacto, m

label define marital_status_defacto 1 "Married" 2 "Cohabiting" 3 "Separated" 4 "Divorced" 5 "Widowed" 6 "Never Married"
label values marital_status_defacto marital_status_defacto

gen partnered=0
replace partnered=1 if inlist(marital_status_defacto,1,2)

inspect ppid
inspect ppid if partnered==1 // worried this is only ukhls GAH
inspect sppid if partnered==1 // okay this is also only ukhls and is just spouses
inspect sppid_bh if partnered==1 // okay this is bhps but includes spouses and partners

browse pidp wavename survey marital_status_defacto partnered ppid sppid sppid_bh

gen long partner_id = .
replace partner_id = ppid if survey==1
replace partner_id = sppid_bh if survey==2
replace partner_id = . if partner_id <=0 // inapplicable / spouse not in HH

inspect partner_id
inspect partner_id if partnered==1

browse pidp wavename survey marital_status_defacto partnered partner_id ppid sppid_bh if partnered==1

// okay eventually want to see if I can get this from main file, but for now, think I need the bhps id for their partners
merge m:1 pidp using "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\cross wave\xwaveid_bh.dta", keepusing(pid)
drop if _merge==2
tab survey _merge
drop _merge

** DoL variables
foreach var in howlng husits hubuys hufrys huiron humops huboss jbstat aidhh aidxhh{
	recode `var' (-10/-1=.)
}

fre jbstat
gen employed=0
replace employed=1 if inlist(jbstat,1,2)

recode jbhrs (-8=0)(-9=.)(-7/-1=.)

sum howlng, detail
sum jbhrs, detail
sum jbhrs if employed==1, detail
tab husits, m
fre husits

tab hubuys, m
tab hubuys if wavename==12 // why did this coding change?
gen hubuys_v0 = hubuys
replace hubuys = 1 if wavename==12 & inlist(hubuys_v0,1,2) // 1 = mostly self
replace hubuys = 2 if wavename==12 & inlist(hubuys_v0,4,5) // 2 = mostly partner
replace hubuys = 3 if wavename==12 & inlist(hubuys_v0,3) // 3 = shared
replace hubuys = 97 if wavename==12 & inlist(hubuys_v0,6,7) // 97 = other
replace hubuys=. if hubuys_v0==8
fre hubuys

tab hufrys, m
tab hufrys if wavename==12 // okay so I think coding changed on all of these
gen hufrys_v0 = hufrys
replace hufrys = 1 if wavename==12 & inlist(hufrys_v0,1,2) // 1 = mostly self
replace hufrys = 2 if wavename==12 & inlist(hufrys_v0,4,5) // 2 = mostly partner
replace hufrys = 3 if wavename==12 & inlist(hufrys_v0,3) // 3 = shared
replace hufrys = 97 if wavename==12 & inlist(hufrys_v0,6,7) // 97 = other
replace hufrys=. if hufrys_v0==8

tab huiron, m
tab huiron if wavename==12 // okay so I think coding changed on all of these
gen huiron_v0 = huiron
replace huiron = 1 if wavename==12 & inlist(huiron_v0,1,2) // 1 = mostly self
replace huiron = 2 if wavename==12 & inlist(huiron_v0,4,5) // 2 = mostly partner
replace huiron = 3 if wavename==12 & inlist(huiron_v0,3) // 3 = shared
replace huiron = 97 if wavename==12 & inlist(huiron_v0,6,7) // 97 = other
replace huiron=. if huiron_v0==8
replace huiron=. if huiron==5

tab humops, m
tab humops if wavename==12 // okay so I think coding changed on all of these
gen humops_v0 = humops
replace humops = 1 if wavename==12 & inlist(humops_v0,1,2) // 1 = mostly self
replace humops = 2 if wavename==12 & inlist(humops_v0,4,5) // 2 = mostly partner
replace humops = 3 if wavename==12 & inlist(humops_v0,3) // 3 = shared
replace humops = 97 if wavename==12 & inlist(humops_v0,6,7) // 97 = other
replace humops=. if humops_v0==8
replace humops=. if humops==5

tab huboss, m
replace huboss=97 if huboss==4 // other was 4 in bhps

tab aidhh survey, m
tab aidxhh survey, m
tab aidhrs survey, m
recode aidhrs (-8=0)(-10/-9=.)(-7/-1=.)

foreach var in nch02_dv nch34_dv nch511_dv nch1215_dv{
	replace `var'=. if `var'==-9
}

egen nchild_015 = rowtotal(nch02_dv nch34_dv nch511_dv nch1215_dv)
browse nchild_dv nchild_015 nch02_dv nch34_dv nch511_dv nch1215_dv

tab husits if partnered==1, m
tab husits if nchild_dv!=0, m
tab wavename husits if nchild_dv!=0, m // still a lot of missing..oh, well, i guess they could have child AND not be partnered DUH
tab wavename husits if nchild_dv!=0 & partnered==1, m // still a lot of missing..oh, well, i guess they could have child AND not be partnered. okay still a lot of missing, idk...might be proxy surveys
tab hubuys if partnered==1, m
tab hufrys if partnered==1, m
tab huiron if partnered==1, m
tab humops if partnered==1, m
tab huboss if partnered==1, m

browse pidp hidp wavename age_all partnered marital_status_defacto husits howlng hubuys hufrys huiron humops jbhrs

save "$outputpath/UKHLS_long_all_recoded.dta", replace

********************************************************************************
**# Now create temporary copy of the data to use to match partner characteristics
********************************************************************************
// just keep necessary variables
local partnervars "pno sampst sex jbstat qfhigh racel racel_dv nmar aidhh aidxhh aidhrs jbhas jboff jbbgy jbhrs jbot jbotpd jbttwt ccare dinner howlng fimngrs_dv fimnlabgrs_dv fimnlabnet_dv paygl paynl paygu_dv payg_dv paynu_dv payn_dv ethn_dv nchild_dv ndepchl_dv rach16_dv qfhigh_dv hiqual_dv lcohnpi coh1bm coh1by coh1mr coh1em coh1ey lmar1m lmar1y cohab cohabn lmcbm1 lmcby41 currpart1 lmspm1 lmspy41 lmcbm2 lmcby42 currpart2 lmspm2 lmspy42 lmcbm3 lmcby43 currpart3 lmspm3 lmspy43 lmcbm4 lmcby44 currpart4 lmspm4 lmspy44 hubuys hufrys humops huiron husits huboss lmcbm5 lmcby45 currpart5 lmspm5 lmspy45 lmcbm6 lmcby46 currpart6 lmspm6 lmspy46 lmcbm7 lmcby47 currpart7 lmspm7 lmspy47 isced11_dv region hiqualb_dv huxpch hunurs race qfedhi qfachi isced nmar_bh racel_bh age_all dob_year marital_status_legal marital_status_defacto partnered employed"

keep pidp pid survey wavename `partnervars'

// rename them to indicate they are for spouse
foreach var in `partnervars'{
	rename `var' `var'_sp
}

// rename pidp to match the name I gave to partner pidp in main file to match
// rename pidp partner_id

browse if pidp==537205
browse if pid==537205

// think I have to use pid for BHPS, so try that
gen long partner_id =.
replace partner_id = pidp if survey==1
replace partner_id = pid if survey==2
replace partner_id = pidp if partner_id==.

// still not working, so use pid for everyone with a pid and pidp for everyone else
/*
gen long partner_id =.
replace partner_id = pid if pid!=.
replace partner_id = pidp if partner_id==.
*/

drop pidp pid survey

save "$temp/UKHLS_partners.dta", replace

// now open file and merge on partner characteristics
use "$outputpath/UKHLS_long_all_recoded.dta", clear

merge m:1 partner_id wavename using "$temp/UKHLS_partners.dta"
drop if _merge==2
tab survey _merge, m
tab survey partnered, m // so, there are more people partnered than matched...
inspect partner_id if _merge==1 & partnered==1 // so there are a bunch with partner ids, so WHY aren't they matching?
inspect partner_id if _merge==1 & partnered==1 & survey==1 //
inspect partner_id if _merge==1 & partnered==1 & survey==2 //

browse survey wavename pidp pid partner_id hubuys _merge

gen partner_match=0
replace partner_match=1 if _merge==3
drop _merge

// some exploration - are these known problems?!
browse survey wavename pidp pid partner_id _merge if partner_id==537205 | partner_id == 14382296 // so this person still lists the below as their partner in later waves, but then that person no longer does?
browse pidp pid wavename partner_id _merge if pidp==537205 // so this person lists the below as their partner waves 18-29, they have no presence in later waves?
browse pidp wavename partner_id _merge if pid==52459748 // but this person lists someone else as their partner...14382296...okay this is their PID. so sometimes it is against their pid, but sometimes against pidp? ecept in this case, mostly matched?

browse survey wavename pidp pid partner_id _merge if partner_id==956765 // so waves 4-13 are master only
browse pidp pid wavename partner_id _merge if pidp==956765 // let's look at what waves the person says they are in. so they are missing for waves 4-13.

browse survey wavename pidp pid partner_id _merge if partner_id==78217008 // waves 20-21 are master only	
browse pidp pid wavename partner_id _merge if pid==78217008  // this is a pid not a pidp. so yeah, this person doesn't have records for 20-21?

save "$outputpath/UKHLS_matched.dta", replace

browse survey wavename pidp pid partner_id hubuys hubuys_sp partner_match if partnered==1

// let's make sure the matching worked
browse pidp year hidp marital_status_defacto marr_trans partner_id partner_match
browse pidp pid year partner_id partner_match husits husits_sp hubuys hubuys_sp age_all age_all_sp jbhrs jbhrs_sp sex sex_sp if hidp==483786010