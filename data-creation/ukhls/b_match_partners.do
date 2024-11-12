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
* NOTE: you should run the macros in the setup file for this to work. 

********************************************************************************
* Going to try to first update spouse id for BHPS so it's pidp NOT pid
********************************************************************************
use "$UKHLS\xwaveid_bh.dta", clear

keep pidp pid
rename pid sppid_bh
rename pidp partner_pidp_bh

save "$temp_ukhls\spid_lookup.dta", replace

********************************************************************************
* Prep partner history file for later
********************************************************************************
use "$UKHLS_mh/phistory_wide.dta", clear

foreach var in status* partner* starty* startm* endy* endm* divorcey* divorcem* mrgend* cohend* ongoing* ttl_spells ttl_married ttl_civil_partnership ttl_cohabit ever_married ever_civil_partnership ever_cohabit lastintdate lastinty lastintm hhorig{
	rename `var' mh_`var' // renaming for ease of finding later, especially when matching partner info
}

save "$temp_ukhls\partner_history_tomatch.dta", replace

********************************************************************************
* Import data (created in step a) and do some data cleaning / recoding before creating a file to match partners
********************************************************************************

use "$created_data_ukhls/UKHLS_long_all.dta", clear
drop if pidp==. // think these are HHs that didn't match?

// Right now 1-13 are ukhls and 14-31 are bhps, so the wave order doesn't make a lot of sense. These aren't perfect but will work for now.
// okay i added interview characteristics, so use that?
browse pidp pid wavename intdatey intdaty_dv istrtdaty // istrtdaty seems the most comprehensive. the DV one is only UKHLS
// okay, but sometimes consecutive surveys are NOT consecutive years? 

gen year=.
replace year=2009 if wavename==1
replace year=2010 if wavename==2
replace year=2011 if wavename==3
replace year=2012 if wavename==4
replace year=2013 if wavename==5
replace year=2014 if wavename==6
replace year=2015 if wavename==7
replace year=2016 if wavename==8
replace year=2017 if wavename==9
replace year=2018 if wavename==10
replace year=2019 if wavename==11
replace year=2020 if wavename==12
replace year=2021 if wavename==13
replace year=1991 if wavename==14
replace year=1992 if wavename==15
replace year=1993 if wavename==16
replace year=1994 if wavename==17
replace year=1995 if wavename==18
replace year=1996 if wavename==19
replace year=1997 if wavename==20
replace year=1998 if wavename==21
replace year=1999 if wavename==22
replace year=2000 if wavename==23
replace year=2001 if wavename==24
replace year=2002 if wavename==25
replace year=2003 if wavename==26
replace year=2004 if wavename==27
replace year=2005 if wavename==28
replace year=2006 if wavename==29
replace year=2007 if wavename==30
replace year=2008 if wavename==31

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

// going to see if I can fill in missing sex variables
browse pidp year sex hgsex
replace sex=hgsex if sex==. & hgsex!=.
replace sex=sex_dv if sex==. & sex_dv!=.

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

// also need to figure out how to get college degree equivalent (see Musick et al 2020 - use the ISCED guidelines to identify bachelor's degree equivalents as the completion of tertiary education programs, excluding higher vocational programs

fre hiqual_dv // think need to use the component variable of this
tab hiqual_dv survey, m // both
replace hiqual_dv=. if inlist(hiqual_dv,-8,-9)
tab qfhigh_dv survey, m // this is only ukhls
// other educations: qfachi (bhps only) qfedhi (bhps only - details) qfhigh (not v good) qfhigh_dv (ukhls details) hiqual_dv hiqualb_dv (bhps only) isced11_dv (only UKHS, but lots of missing, which is sad bc I think it's what I nee/d?) isced (bhps, might be helpful?)

tab qfhigh_dv hiqual_dv
tab isced11_dv hiqual_dv // see what bachelors in isced is considered in hiqual // okay so bachelor's / master's in degree. some of bachelor's also in "other higher degree"
tab isced hiqual_dv // so here 5a and 6 are in degree. 5b is what is in other degree (vocational) - do I want that? I feel like Musick didn't include vocational.

gen college_degree=0
replace college_degree=1 if  hiqual_dv==1
replace college_degree=. if hiqual_dv==.

/*
Undergraduate degrees are either level 4, 5 or 6 qualifications, with postgraduate degrees sitting at level 7 or 8. In Scotland, awards are at level 9 or 10 for an undergraduate degree, and level 11 and 12 for master's and doctorates.
A bachelor's degree involves studying one, or sometimes two, subjects in detail. It's the most common undergraduate degree in the UK and is a level 6 qualification (level 9 or 10 in Scotland). 
*/

tab racel survey, m
tab racel_dv survey, m // ukhls - but one the survey says to use I think
tab race survey, m // not helpful
tab racel_bh survey, m // this doesn't feel helpful either
tab ethn_dv survey, m // okay, need to figure out a bhps race variable...
// might need to combine these two: race (BH01-12) racel_bh (BH13-18) or get racel_dv_all from xwavedat

browse survey year racel_dv race racel_bh
gen race_use = .
replace race_use = 1 if inrange(racel_dv,1,4) & survey==1
replace race_use = 1 if race==1 & survey==2 & inrange(year,1991,2002)
replace race_use = 1 if inrange(racel_bh,1,5) & survey==2 & inrange(year,2003,2008)
replace race_use = 2 if inrange(racel_dv,14,16) & survey==1
replace race_use = 2 if inrange(race,2,4) & survey==2 & inrange(year,1991,2002)
replace race_use = 2 if inrange(racel_bh,14,16) & survey==2 & inrange(year,2003,2008)
replace race_use = 3 if inrange(racel_dv,9,13) & survey==1
replace race_use = 3 if inrange(race,5,8) & survey==2 & inrange(year,1991,2002)
replace race_use = 3 if inrange(racel_bh,10,13) & survey==2 & inrange(year,2003,2008)
replace race_use = 4 if inrange(racel_dv,5,8) & survey==1
replace race_use = 4 if inrange(racel_bh,6,9) & survey==2 & inrange(year,2003,2008)
replace race_use = 5 if inrange(racel_dv,17,97) & survey==1
replace race_use = 5 if race==9 & survey==2 & inrange(year,1991,2002)
replace race_use = 5 if racel_bh==18 & survey==2 & inrange(year,2003,2008)
replace race_use = -8 if race==-8 & survey==2 & inrange(year,1991,2002)
replace race_use = -8 if racel_bh==-8 & survey==2 & inrange(year,2003,2008)

label define race_use 1 "White" 2 "Black" 3 "Asian" 4 "Mixed" 5 "Other" -8 "Get"
label values race_use race_use

// country
recode gor_dv (1/9=1)(10=2)(11=3)(12=4), gen(country_all)
replace country_all=. if inlist(country_all,-9,13)
label define country 1 "England" 2 "Wales" 3 "Scotland" 4 "N. Ireland"
label values country_all country

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
inspect ppid if partnered==1 // this is only ukhls
inspect sppid if partnered==1 // okay this is also only ukhls and is just spouses
inspect sppid_bh if partnered==1 // okay this is bhps but includes spouses and partners

merge m:1 sppid_bh using "$temp_ukhls\spid_lookup.dta"
drop if _merge==2
browse survey pidp pid sppid_bh partner_pidp_bh _merge
inspect sppid_bh if partnered==1
inspect partner_pidp_bh if partnered==1
drop _merge

browse pidp wavename survey marital_status_defacto partnered ppid sppid sppid_bh

gen long partner_id = .
replace partner_id = ppid if survey==1
// replace partner_id = sppid_bh if survey==2
replace partner_id = partner_pidp_bh if survey==2 // okay will try to use pidp instead? I don't know if this is smart?
replace partner_id = . if partner_id <=0 // inapplicable / spouse not in HH

inspect partner_id
inspect partner_id if partnered==1

browse pidp wavename survey marital_status_defacto partnered partner_id ppid partner_pidp_bh sppid_bh if partnered==1

********************************************************************************
** DoL variables
********************************************************************************
/*
attempting to QA howlng here - coverage feels low in next file, want to see if that is actually true. do before all recodes.
tab howlng if wavename==6, m
tab howlng if wavename==6 & howlng>=0, m
browse survey istrtdaty istrtdatm  howlng if wavename==6
*/

foreach var in howlng husits hubuys hufrys huiron humops huboss jbstat aidhh aidxhh{
	recode `var' (-10/-1=.)
}

// some better employment variables
fre jbstat
gen employed=0
replace employed=1 if inlist(jbstat,1,2)

recode jbhrs (-8=0)(-9=.)(-7/-1=.)

fre jbot
recode jbot (-8=0)(-9=.)(-7/-1=.)

egen total_hours=rowtotal(jbhrs jbot)

sum howlng, detail
sum jbhrs, detail
sum jbhrs if employed==1, detail
tab husits, m
fre husits

recode fimnlabgrs_dv (-9=.)(-7=.)
recode fimnlabnet_dv (-9=.)(-1=.)
recode paynu_dv (-9=.)(-7=.)(-8=0)

// unpaid labor variables
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
tab wavename husits if nchild_dv!=0 & partnered==1, m // still a lot of missing..oh, well, i guess they could have child AND not be partnered. okay still a lot of missing, might be proxy surveys
tab hubuys if partnered==1, m
tab hufrys if partnered==1, m
tab huiron if partnered==1, m
tab humops if partnered==1, m
tab huboss if partnered==1, m

browse pidp hidp wavename age_all partnered marital_status_defacto husits howlng hubuys hufrys huiron humops jbhrs

********************************************************************************
* Okay, let's add on marital history as well, so I can use this to get duration / relationship order?
* Doing here (used to be later, just for reference person) so I can get gendered versions for later
********************************************************************************

merge m:1 pidp using "$temp_ukhls\partner_history_tomatch.dta", keepusing(mh_*)
tab marital_status_defacto _merge, row // so def some missing that shouldn't be... but not a lot
drop if _merge==2
drop _merge

browse pidp sex marital_status_defacto partner_id mh_partner1 mh_status1 mh_partner2 mh_status2 mh_partner3 mh_status3 mh_partner4 mh_status4

label define status_new 1 "Marriage" 2 "Cohab"
foreach var in mh_status1 mh_status2 mh_status3 mh_status4 mh_status5 mh_status6 mh_status7 mh_status8 mh_status9 mh_status10 mh_status11 mh_status12 mh_status13 mh_status14{
	gen x_`var' = `var'
	replace `var' = 1 if inlist(`var',2,3)
	replace `var' = 2 if `var'==10
	label values `var' .
	label values `var' status_new
}

gen rel_no=. // add this to get lookup for current relationship start and end dates
forvalues r=1/14{
	replace rel_no = `r' if mh_status`r' == marital_status_defacto & mh_partner`r' == partner_id & partner_id!=.
}

tab rel_no if inlist(marital_status_defacto,1,2), m // so about 4% missing. come back to this - can I see if any started during the survey to at least get duration?

// I am going to create individual level versions of these variables for now and then check in next file against partners to make sure they match.
gen current_rel_start_year=.
gen current_rel_start_month=.
gen current_rel_end_year=.
gen current_rel_end_month=.
gen current_rel_ongoing=.
// gen current_rel_how_end=.
gen current_rel_marr_end=.
gen current_rel_coh_end=.

forvalues r=1/14{
	replace current_rel_start_year = mh_starty`r' if rel_no==`r'
	replace current_rel_start_month = mh_startm`r' if rel_no==`r'
	replace current_rel_end_year = mh_endy`r' if rel_no==`r'
	replace current_rel_end_month = mh_endm`r' if rel_no==`r'
	replace current_rel_ongoing = mh_ongoing`r' if rel_no==`r'
	// replace current_rel_how_end = mrgend`r' if rel_no==`r' & status`r'==1 // if marriage - okay this actually won't work because the codes are different between marriage and cohab
	// replace current_rel_how_end = cohend`r' if rel_no==`r' & status`r'==2 // if cohab
	replace current_rel_marr_end = mh_mrgend`r' if rel_no==`r'
	replace current_rel_coh_end = mh_cohend`r' if rel_no==`r'
}

replace current_rel_start_year=. if current_rel_start_year==-9
replace current_rel_start_month=. if current_rel_start_month==-9
replace current_rel_end_year=. if current_rel_end_year==-9
replace current_rel_end_month=. if current_rel_end_month==-9

label values current_rel_ongoing ongoing
label values current_rel_marr_end mrgend
label values current_rel_coh_end cohend

browse pidp marital_status_defacto partner_id rel_no current_rel_start_year current_rel_start_month current_rel_end_year current_rel_end_month current_rel_ongoing current_rel_marr_end current_rel_coh_end mh_partner1 mh_status1 mh_starty1 mh_startm1 mh_endy1 mh_endm1 mh_divorcey1 mh_divorcem1 mh_mrgend1 mh_cohend1 mh_ongoing1 mh_partner2 mh_status2 mh_starty2 mh_startm2 mh_endy2 mh_endm2 mh_divorcey2 mh_divorcem2 mh_mrgend2 mh_cohend2 mh_ongoing2

// for those with missing, maybe if only 1 spell, use that info? as long as the status matches and the interview date is within the confines of the spell?
browse pidp istrtdaty istrtdatm marital_status_defacto partner_id rel_no mh_ttl_spells mh_partner1 mh_status1 mh_starty1 mh_startm1 mh_endy1 mh_endm1 mh_divorcey1 mh_divorcem1 mh_mrgend1 mh_cohend1 mh_ongoing1 mh_partner2 mh_status2 mh_starty2 mh_startm2 mh_endy2 mh_endm2 mh_divorcey2 mh_divorcem2 mh_mrgend2 mh_cohend2 mh_ongoing2

replace current_rel_start_year = mh_starty1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==mh_status1 & istrtdaty>=mh_starty1 & istrtdaty<=mh_endy1
replace current_rel_start_month = mh_startm1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==mh_status1 & istrtdaty>=mh_starty1 & istrtdaty<=mh_endy1
replace current_rel_end_year = mh_endy1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==mh_status1 & istrtdaty>=mh_starty1 & istrtdaty<=mh_endy1
replace current_rel_end_month = mh_endm1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==mh_status1 & istrtdaty>=mh_starty1 & istrtdaty<=mh_endy1
replace current_rel_ongoing = mh_ongoing1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==mh_status1 & istrtdaty>=mh_starty1 & istrtdaty<=mh_endy1
gen rel_no_orig=rel_no
replace rel_no=1 if rel_no==. & partner_id!=. & inlist(marital_status_defacto,1,2) & marital_status_defacto==mh_status1 & istrtdaty>=mh_starty1 & istrtdaty<=mh_endy1 // okay this actually didn't add that many more that is fine.

save "$created_data_ukhls/UKHLS_long_all_recoded.dta", replace

unique pidp // 109651, 772472 total py
unique pidp partner_id // 126305	
unique pidp, by(sex) // 52397 m, 57362 w
unique pidp, by(partnered) // 55858 0, 68410 1

********************************************************************************
**# Now create temporary copy of the data to use to match partner characteristics
********************************************************************************
// just keep necessary variables
local partnervars "pno sampst sex jbstat qfhigh racel racel_dv nmar aidhh aidxhh aidhrs jbhas jboff jbbgy jbhrs jbot jbotpd jbttwt ccare dinner howlng fimngrs_dv fimnlabgrs_dv fimnlabnet_dv paygl paynl paygu_dv payg_dv paynu_dv payn_dv ethn_dv nchild_dv ndepchl_dv rach16_dv qfhigh_dv hiqual_dv lcohnpi coh1bm coh1by coh1mr coh1em coh1ey lmar1m lmar1y cohab cohabn lmcbm1 lmcby41 currpart1 lmspm1 lmspy41 lmcbm2 lmcby42 currpart2 lmspm2 lmspy42 lmcbm3 lmcby43 currpart3 lmspm3 lmspy43 lmcbm4 lmcby44 currpart4 lmspm4 lmspy44 hubuys hufrys humops huiron husits huboss lmcbm5 lmcby45 currpart5 lmspm5 lmspy45 lmcbm6 lmcby46 currpart6 lmspm6 lmspy46 lmcbm7 lmcby47 currpart7 lmspm7 lmspy47 isced11_dv region hiqualb_dv huxpch hunurs race qfedhi qfachi isced nmar_bh racel_bh age_all dob_year marital_status_legal marital_status_defacto partnered employed total_hours country_all college_degree race_use psu strata istrtdaty indinub_xw indinus_xw indinus_lw indinub_lw mh_* rel_no current_rel_start_year current_rel_start_month current_rel_end_year current_rel_end_month current_rel_ongoing current_rel_marr_end current_rel_coh_end"

keep pidp pid survey wavename year `partnervars'

// rename them to indicate they are for spouse
foreach var in `partnervars'{
	rename `var' `var'_sp
}

// rename pidp to match the name I gave to partner pidp in main file to match
generate long apidp = pidp // so this will also work to match ego alt later
rename pidp partner_id // okay tried to update all to be pidp above - let's see if this will work

// browse if pidp==537205
browse if pid==537205

// think I have to use pid for BHPS, so try that
/* trying to match on pidp
gen long partner_id =.
replace partner_id = pidp if survey==1
replace partner_id = pid if survey==2
replace partner_id = pidp if partner_id==.
*/

// still not working, so use pid for everyone with a pid and pidp for everyone else
/*
gen long partner_id =.
replace partner_id = pid if pid!=.
replace partner_id = pidp if partner_id==.
*/

// drop pidp pid survey
drop pid survey

save "$temp_ukhls/UKHLS_partners.dta", replace

// now open file and merge on partner characteristics
use "$created_data_ukhls/UKHLS_long_all_recoded.dta", clear

merge m:1 partner_id wavename using "$temp_ukhls/UKHLS_partners.dta" // okay it feels like switching to pidp left me with the same number of matches...
drop if _merge==2

tab survey _merge, m
tab survey partnered, m // so, there are more people partnered than matched...
inspect partner_id if _merge==1 & partnered==1 // so there are a bunch with partner ids, so WHY aren't they matching? okay, confirmed it is just partner non-response for a specific wave
inspect partner_id if _merge==1 & partnered==1 & survey==1 //
inspect partner_id if _merge==1 & partnered==1 & survey==2 //

browse survey wavename pidp pid partner_id hubuys _merge

gen partner_match=0
replace partner_match=1 if _merge==3
drop _merge

rename istrtdaty int_year
rename istrtdaty_sp int_year_sp

/*
some exploration to QA partners - but this is just due to non-response, I have confirmed

browse survey wavename pidp pid partner_id partner_match if partner_id==537205 | partner_id == 14382296 // so this person still lists the below as their partner in later waves, but then that person no longer does?
browse pidp pid wavename partner_id partner_match if pidp==537205 // so this person lists the below as their partner waves 18-29, they have no presence in later waves?
browse pidp wavename partner_id partner_match if pid==52459748 // but this person lists someone else as their partner...14382296...okay this is their PID. so sometimes it is against their pid, but sometimes against pidp? ecept in this case, mostly matched?

browse survey wavename pidp pid partner_id partner_match if partner_id==956765 // so waves 4-13 are master only
browse pidp pid wavename partner_id partner_match if pidp==956765 // let's look at what waves the person says they are in. so they are missing for waves 4-13.

browse survey wavename pidp pid partner_id partner_match if partner_id==78217008 // waves 20-21 are master only	
browse pidp pid wavename partner_id partner_match if pid==78217008  // this is a pid not a pidp. so yeah, this person doesn't have records for 20-21?
*/

save "$created_data_ukhls/UKHLS_matched.dta", replace

browse survey wavename pidp pid partner_id hubuys hubuys_sp partner_match if partnered==1

// let's make sure the matching worked
browse pidp wavename hidp marital_status_defacto partner_id partner_match
browse pidp pid wavename partner_id partner_match husits husits_sp hubuys hubuys_sp age_all age_all_sp jbhrs jbhrs_sp sex sex_sp if hidp==483786010
