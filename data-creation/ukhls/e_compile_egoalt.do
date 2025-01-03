********************************************************************************
********************************************************************************
* Project: Relative Density Approach - UK
* Code owner: Kimberly McErlean
* Started: September 2024
* File name: compile_egoalt.do
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This file takes all of the wave specific egoalt data and appends it.
* I am going to see if this improves partner matching.

********************************************************************************
* First create some macros
* Will use most of the other macros from the setup file
********************************************************************************

clear all
set more off

// Replace "where" with the filepath of the working folder (where any temporary files created by this programme will be stored)   eg:  c:\ukhls\temp
cd "$temp_ukhls"

// The file produced by this programme will be named as below. If you want to change the name do it here.
local outputfilename "UKHLS_egoalt_all"

// By default the data will be extracted from the waves whose letter prefixes are written below, and merged. If you want to a different selection of waves, make the change here
local allWaves = "a b c d e f g h i j k l m ba bb bc bd be bf bg bh bi bj bk bl bm bn bo bp bq br"
local bhps = "ba bb bc bd be bf bg bh bi bj bk bl bm bn bo bp bq br"
local ukhls = "a b c d e f g h i j k l m"

********************************************************************************
* Then edit each specific file and append
********************************************************************************

** Have to do some things differently based on whether bhps or ukhls
** UKHLS

local i=1

foreach wave in `ukhls' {
	// find the wave number
	//local waveno=strpos("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz","`wave'")
	local waveno=`i'
	
	
	// open the the egoalt file
	use "$egoalt/`wave'_egoalt", clear

	// only keep those in a partnership
	keep if inlist(`wave'_relationship,1,2,3)

	// create a wave variable - think this will get messed up below so use 2 to indicate ukhls
	gen survey=2
	gen wavename=`waveno'

	// drop the wave prefix from all variables
	rename `wave'_* *

	// variables to keep
	keep survey wavename pidp hidp pno apidp apno relationship sex asex pid // psu strata elwstat enwstat anwstat 
	
	// save the file that was created
	save temp_ego_`wave', replace
	
local ++i
	
}

** BHPS
local i=1

foreach wave in `bhps' {
	// find the wave number
	//local waveno=strpos("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz","`wave'")
	local waveno=`i'
	
	// open the the egoalt file
	use "$egoalt/`wave'_egoalt", clear
	
	// only keep those in a partnership
	keep if inlist(`wave'_relationship_bh,1,2)
	rename `wave'_relationship_bh relationship // to match ukhls

	// create a wave variable - think this will get messed up below so use 1 to indicate bhps
	gen survey=1
	gen wavename=`waveno'

	// drop the wave prefix from all variables
	rename `wave'_* *

	// variables to keep
	rename esex sex
	keep survey wavename pidp hidp pno apidp apno relationship sex asex pid // psu strata apid lwstat nwstat
	
	// save the file that was created
	save temp_ego_`wave', replace
	
local ++i
	
}

** Now append
// open the file for the first wave (wave a_)
local firstWave = substr("`allWaves'", 1, 1)
use temp_ego_`firstWave', clear

// loop through the remaining waves appending them in the long format
local remainingWaves = substr("`allWaves'", 3, .)

foreach w in `remainingWaves' {
	// append the files for the second wave onwards
	append using temp_ego_`w'
}

// check how many observations are available from each wave
tab wavename survey

// to be able to order better
gen year=.
replace year=1991 if wavename==1 & survey==1
replace year=1992 if wavename==2 & survey==1
replace year=1993 if wavename==3 & survey==1
replace year=1994 if wavename==4 & survey==1
replace year=1995 if wavename==5 & survey==1
replace year=1996 if wavename==6 & survey==1
replace year=1997 if wavename==7 & survey==1
replace year=1998 if wavename==8 & survey==1
replace year=1999 if wavename==9 & survey==1
replace year=2000 if wavename==10 & survey==1
replace year=2001 if wavename==11 & survey==1
replace year=2002 if wavename==12 & survey==1
replace year=2003 if wavename==13 & survey==1
replace year=2004 if wavename==14 & survey==1
replace year=2005 if wavename==15 & survey==1
replace year=2006 if wavename==16 & survey==1
replace year=2007 if wavename==17 & survey==1
replace year=2008 if wavename==18 & survey==1
replace year=2009 if wavename==1 & survey==2
replace year=2010 if wavename==2 & survey==2
replace year=2011 if wavename==3 & survey==2
replace year=2012 if wavename==4 & survey==2
replace year=2013 if wavename==5 & survey==2
replace year=2014 if wavename==6 & survey==2
replace year=2015 if wavename==7 & survey==2
replace year=2016 if wavename==8 & survey==2
replace year=2017 if wavename==9 & survey==2
replace year=2018 if wavename==10 & survey==2
replace year=2019 if wavename==11 & survey==2
replace year=2020 if wavename==12 & survey==2
replace year=2021 if wavename==13 & survey==2

// move pidp to the beginning of the file
order pidp, first
sort pidp survey year

// save the long file
save "$created_data_ukhls/`outputfilename'", replace

// erase temporary files
foreach w in `allWaves' {
	erase temp_ego_`w'.dta
}

** Some checks
tab relationship, m
tab wavename relationship if survey==2 // check against codebook
tab wavename relationship if survey==1 // check against codebook

browse pidp apidp year survey wavename relationship
unique pidp apidp if sex==2

********************************************************************************
**# Try to match characteristics from other created file
********************************************************************************
// use "$created_data_ukhls\UKHLS_egoalt_all.dta", clear

local keepvars "sampst jbstat qfhigh racel racel_dv nmar aidhh aidxhh aidhrs jbhas jboff jbbgy jbhrs jbot jbotpd jbttwt ccare dinner howlng fimngrs_dv fimnlabgrs_dv fimnlabnet_dv paygl paynl paygu_dv payg_dv paynu_dv payn_dv ethn_dv nchild_dv ndepchl_dv rach16_dv qfhigh_dv hiqual_dv lcohnpi coh1bm coh1by coh1mr coh1em coh1ey lmar1m lmar1y cohab cohabn lmcbm1 lmcby41 currpart1 lmspm1 lmspy41 lmcbm2 lmcby42 currpart2 lmspm2 lmspy42 lmcbm3 lmcby43 currpart3 lmspm3 lmspy43 lmcbm4 lmcby44 currpart4 lmspm4 lmspy44 hubuys hufrys humops huiron husits huboss lmcbm5 lmcby45 currpart5 lmspm5 lmspy45 lmcbm6 lmcby46 currpart6 lmspm6 lmspy46 lmcbm7 lmcby47 currpart7 lmspm7 lmspy47 isced11_dv region hiqualb_dv huxpch hunurs race qfedhi qfachi isced nmar_bh racel_bh age_all dob_year marital_status_legal marital_status_defacto partnered employed"

** First, the reference person
merge m:1 pidp year using "$created_data_ukhls/UKHLS_long_all_recoded.dta", keepusing(`keepvars')
drop if _merge==2 // using makes sense, bc I just have partnered people, so it's probably those not partnered
gen ref_match=0
replace ref_match=1 if _merge==3
drop _merge

tab survey ref_match, m row
tab year ref_match, m row

** Now, the spouse
merge m:1 apidp year using "$temp_ukhls/UKHLS_partners.dta" // feels like the same amount matched? yes, so it's like the inverse. some people just missing, so will be missing as references but also as spouse (bc I have deduplicated yet)
drop if _merge==2 // using makes sense, bc I just have partnered people, so it's probably those not partnered
gen sp_match=0
replace sp_match=1 if _merge==3
drop _merge

tab survey sp_match, m row

drop if sex<0
tab ref_match sp_match
tab sex ref_match
tab sex sp_match

gen both_match=0
replace both_match=1 if ref_match==1 & sp_match==1

gen rel_type=.
replace rel_type=1 if inlist(relationship,1,3)
replace rel_type=2 if relationship==2

unique pidp apidp if sex ==2
unique pidp apidp if sex ==2 & both_match==1 // okay so this is my 32,000. is it the SAME 32,000?! that is the question. I guess let's try to find out??
unique pidp apidp if sex ==2 & both_match==1, by(rel_type)

// want to export list to qa
preserve

drop if sex==1
drop if both_match==0
collapse (count) year, by(pidp apidp)
browse

restore
