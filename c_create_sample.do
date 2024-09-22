********************************************************************************
********************************************************************************
* Project: Relative Density Approach - UK
* Code owner: Kimberly McErlean
* Started: September 2024
* File name: c_create_sample.do
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* Restrict sample to just partnered, might restrict to just survey years with the unpaid labor questions

********************************************************************************
* Import data and some small recodes
********************************************************************************
use "$outputpath/UKHLS_matched.dta", clear
drop if partnered==0

// i am dumb and right now 1-13 are ukhls and 14-31 are bhps, so the wave order doesn't make a lot of sense. These aren't perfect but will work for now.
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

sort pidp year

browse pidp year marital_status_defacto partner_id howlng howlng_sp

// identify couples who transitioned from cohab to marriage
gen marr_trans=0
replace marr_trans=1 if (marital_status_defacto==1 & marital_status_defacto[_n-1]==2) & pidp==pidp[_n-1] & partner_id==partner_id[_n-1] & year==year[_n-1]+1

browse pidp year marital_status_defacto marr_trans partner_id howlng howlng_sp
// this pidp did have transition 16339 - okay confirmed it worked.

// drop same-sex couples?!
tab sex sex_sp
drop if sex==sex_sp

// create DoL variables for the two continuous variables
egen paid_couple_total = rowtotal(jbhrs jbhrs_sp)
gen paid_wife_pct=jbhrs / paid_couple_total if sex==2 & sex_sp==1
replace paid_wife_pct=jbhrs_sp / paid_couple_total if sex==1 & sex_sp==2
sum paid_wife_pct
browse pidp year sex sex_sp jbhrs jbhrs_sp paid_couple_total paid_wife_pct

gen paid_dol=.
replace paid_dol = 1 if paid_wife_pct>=0.400000 & paid_wife_pct<=0.600000 // shared
replace paid_dol = 2 if paid_wife_pct <0.400000 & paid_wife_pct!=. // husband does more
replace paid_dol = 3 if paid_wife_pct >0.600000 & paid_wife_pct!=. // wife does more
replace paid_dol = 4 if jbhrs==0 & jbhrs_sp==0 // neither works

tab partner_match paid_dol, m // okay not quite sure what to do for the couples without a match...
browse partner_match jbhrs jbhrs_sp employed employed_sp paid_couple_total paid_wife_pct if paid_dol==. & partner_match==1

label define paid_dol 1 "Shared" 2 "Husband more" 3 "Wife more" 4 "Neither works"
label values paid_dol paid_dol

egen unpaid_couple_total = rowtotal(howlng howlng_sp)
gen unpaid_wife_pct=howlng / unpaid_couple_total if sex==2 & sex_sp==1
replace unpaid_wife_pct=howlng_sp / unpaid_couple_total if sex==1 & sex_sp==2
sum unpaid_wife_pct
browse pidp year sex sex_sp howlng howlng_sp unpaid_couple_total unpaid_wife_pct

gen unpaid_dol=.
replace unpaid_dol = 1 if unpaid_wife_pct>=0.400000 & unpaid_wife_pct<=0.600000 // shared
replace unpaid_dol = 2 if unpaid_wife_pct >0.600000 & unpaid_wife_pct!=. // wife does more
replace unpaid_dol = 3 if unpaid_wife_pct <0.400000 & unpaid_wife_pct!=. // husband does more
replace unpaid_dol = 4 if howlng==0 & howlng_sp==0 // neither works

tab partner_match unpaid_dol if inlist(wavename,1,2,4,6,8,10,12,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31), m
tab wavename unpaid_dol, m

browse partner_match howlng howlng_sp unpaid_couple_total unpaid_wife_pct if unpaid_dol==. & inlist(wavename,1,2,4,6,8,10,12,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31) // okay a lot of missing, even when matched. need to figure out eligibility.

label define unpaid_dol 1 "Shared" 2 "Wife more" 3 "Husband more" 4 "No one"
label values unpaid_dol unpaid_dol

********************************************************************************
* Create some preliminary descriptive statistics
********************************************************************************
// unique couples - then by marital status (married, cohab, transitioned)

// then describe couples (age, education, race - except need to figure some of these out)

// then DoL - but not quite sure what to do when unmatched...