********************************************************************************
********************************************************************************
********************************************************************************
**# INDRESP
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
* Just get data and pull in vars I need
********************************************************************************
capture program drop getVars
capture program drop getExistingVars

use "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\wave 2 (test wave)\b_indresp.dta", clear

local allWaves = "b"

local indvars "age_dv aidhh aidhrs aidxhh birthy ccare coh1bm coh1by coh1em coh1ey coh1mr cohab cohab_dv cohabn country currpart1 currpart2 currpart3 currpart4 doby_dv ethn_dv feend fenow fimngrs_dv fimnlabgrs_dv fimnlabnet_dv gor_dv hgpart hhsize hhtype hhtype_dv hid hidp hiqual_dv howlng hrpid hrpno huboss hubuys hufrys huiron humops husits ind5mus_lw indin01_lw ivfio j2hrs jbbgy jbhas jbhrs jboff jbot jbotpd jbstat jbttwt jshrs lcoh lcohnpi livesp_dv lmar1m lmar1y lmcbm1 lmcbm2 lmcbm3 lmcbm4 lmcby41 lmcby42 lmcby43 lmcby44 lmspm1 lmspm2 lmspm3 lmspm4 lmspy41 lmspy42 lmspy43 lmspy44 lnprnt lprnt marstat marstat_dv mastat mastat_dv mlstat nchild_dv ndepchl_dv nmar payg_dv paygl paygu_dv paygw paygwc payn_dv paynl paynu_dv plbornc pno ppid ppno psu qfhigh qfhigh_dv racel racel_dv rach16_dv sampst scend school sex sex_dv single_dv sppid sppno strata ukborn urban_dv"

// pid pidp

// this program returns all variable names with the wave prefix
program define getVars, rclass
    version 14.0
	if ("`1'" != "") {
		local wavemyvars = " `1'"
		local wavemyvars = subinstr("`wavemyvars'"," "," `2'_",.)
		local wavemyvars = substr("`wavemyvars'",2,.)
	}
	else local wavemyvars = ""
	return local fixedVars "`wavemyvars'"
end

// this program to returns  which variables exist in this wave
program define getExistingVars, rclass
    version 14.0
	local all = ""
	foreach var in `1' {
		capture confirm variable `var'
		if !_rc {
			local all = "`all' `var'"
		}
	}
	return local existingVars "`all'"
end  

//loop through each wave
foreach wave in `allWaves' {
	// find the wave number
	local waveno=strpos("abcdefghijklmnopqrstuvwxyz","`wave'")

	// find the wave individual vars
	getVars "`indvars'" `wave'
	local waveindvars = "`r(fixedVars)'"
}

display `waveindvars'
keep pid pidp `waveindvars'

// failed vars: age aidhrs_bh currmstat currpart5 currpart6 currpart7 dinner doby emboost fenow_bh hubuys_bh hufrys_bh humops_bh hgr2r hgra hgsex hhch12 hiqualb_dv hoh  huiron_bh hunurs husits2 huxpch ind5mus_xw indbd91_lw indbdub_lw indin01_xw indin91_lw indin91_xw indin99_lw indin99_xw indinub_lw indinub_xw  indinui_xw indinus_lw indinui_lw indinus_xw indns91_lw indnsub_lw indpxub_lw indpxub_xw indpxui_lw indpxui_xw indpxus_lw indpxus_xw indscub_lw indscub_xw indscui_lw indscui_xw indscus_lw indscus_xw isced lmcbm5 lmcbm6 lmcbm7 lmcby45 lmcby46 lmcby47 lmspm5 lmspm6 lmspm7 lmspy45 lmspy46 lmspy47 mlstat_bh nmar_bh racel_bh qfachi qfedhi race region sampst_bh spjb spjbhr spjbot sppayg sppid_bh tenure_dv

********************************************************************************
* Inspect
********************************************************************************
tab b_age, m
tab b_sex, m
tab b_sex_dv, m

// why are there so many marital statuses?!
tab b_mlstat, m // legal marital status - so don't use this one, 85% are inapplicable
tab b_marstat, m // legal marital status - so think this doesn't include cohabiting? yes, okay
tab b_marstat_dv, m // harmonized de facto - includes cohabiting, okay yes this is cleanest
tab b_mastat_dv, m // de facto

gen b_partnered=0
replace b_partnered=1 if inlist(b_marstat_dv,1,2)

browse pidp pid b_hidp b_pno b_marstat_dv b_hgpart b_ppid b_ppno b_sppid b_sppno // first just look at people and their potential partner matches (and see which id to use to match) some of these don't need partner match, but the two that are raw hours will

tab b_hgpart if b_partnered==1
tab b_hgpart if b_marstat_dv==1
tab b_hgpart if b_marstat_dv==2 // so hgpart is ONLY for married, not cohab. this is also not a unique id - range is only 1-14 essentially

tab b_ppno if b_partnered==1
tab b_ppno if b_marstat_dv==1
tab b_ppno if b_marstat_dv==2 // so if I want the PNO of a partner, use this, covers both

// so ppid / ppno covers BOTH cohab and married, but sppid, sppno JUST covers husbands and wives. okay perfect. I want both, so use the partner version (and they match for spouses, it seems)

browse pidp pid b_marstat_dv b_ppid b_nchild_dv b_howlng b_husits b_hubuys b_hufrys b_huiron b_humops b_huboss b_jbhrs if b_partnered==1 // then look at DoL info - need to confirm the DoL questions are asked to ALL partnered not just married, okay yes, that seems to be the case.

foreach var in b_howlng b_husits b_hubuys b_hufrys b_huiron b_humops b_huboss{
	recode `var' (-9/-1=.)
}

fre b_jbstat
gen b_employed=0
replace b_employed=1 if inlist(b_jbstat,1,2)

recode b_jbhrs (-8=0)(-9=.)(-7/-1=.)

sum b_howlng, detail
sum b_jbhrs, detail
sum b_jbhrs if b_employed==1, detail
tab b_husits, m
fre b_husits
tab b_hubuys, m
fre b_hubuys
tab b_hufrys, m
tab b_huiron, m
tab b_humops, m
tab b_huboss, m

tab b_husits if b_partnered==1, m
tab b_husits if b_nchild_dv!=0, m
tab b_hubuys if b_partnered==1, m
tab b_hufrys if b_partnered==1, m
tab b_huiron if b_partnered==1, m
tab b_humops if b_partnered==1, m
tab b_huboss if b_partnered==1, m

// key DoL variables: husits howlng hubuys hufrys huiron humops jbhrs huboss (but in less waves of the old survey)
// key other variables: scend_dv jbstat mastat mastat_dv nchild_dv marstat age age_dv doby doby_dv qfhigh_dv hiqual_dv racel_dv ethn_dv sex sex_dv
// key ID variables: pidp pid b_hidp b_pno
// key linking variables: hgpart ppid ppno sppid sppno

********************************************************************************
********************************************************************************
********************************************************************************
**# INDALL
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
* Just get data and pull in vars I need
********************************************************************************

use "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\wave 2 (test wave)\b_indall.dta", clear

local indallvars "age age_dv ageif birthy cohab_dv country doby_dv emboost ethn_dv gor_dv hgpart hgr2r hgra hgsex hhsize hid hidp hoh hrpid hrpno ivfio livesp_dv marstat marstat_dv mastat mastat_dv nchild_dv ndepchl_dv pid pidp pno ppid ppno psnen01_lw psnen01_xw psnen91_lw psnen91_xw psnen99_lw psnen99_xw psnenub_lw psnenub_xw psnenui_lw psnenui_xw psnenus_lw psnenus_xw psu racel_dv rach16_dv region sampst sampst_bh sex sex_dv single_dv sppid sppid_bh sppno strata urban_dv"

// okay i don't actaully think I need this file, looking at my spreadsheet.

********************************************************************************
********************************************************************************
********************************************************************************
**# EGO ALT
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
* Just get data and pull in vars I need
********************************************************************************

use "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\wave 2 (test wave)\b_egoalt.dta", clear

fre b_relationship // 1=husband / wife, 2=cohabiting, 3=civil partner
tab b_relationship, m
fre b_rel_dv // alter's relation to ego
fre b_relationship_dv // ego's relation to alter

// okay, I don't think I need this either, because I have this info already in main file? check if relationship status in indresp seems to align.

********************************************************************************
********************************************************************************
********************************************************************************
**# HHRESP
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
* Just get data and pull in vars I need
********************************************************************************
capture program drop getVars
capture program drop getExistingVars

use "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\wave 2 (test wave)\b_hhresp.dta", clear

local allWaves = "b"

local hhvars "agechy_dv country emboost fihhmngrs_dv fihhmnlabgrs_dv fihhmnlabnet_dv fihhmnnet1_dv gor_dv hhsize hhtype hhtype_dv hid hidp hrpid hrpno ieqmoecd_dv nch02_dv nch1215_dv nch34_dv nch511_dv ncouple_dv nemp_dv nkids_dv npens_dv psu strata tenure_dv urban_dv"


// this program returns all variable names with the wave prefix
program define getVars, rclass
    version 14.0
	if ("`1'" != "") {
		local wavemyvars = " `1'"
		local wavemyvars = subinstr("`wavemyvars'"," "," `2'_",.)
		local wavemyvars = substr("`wavemyvars'",2,.)
	}
	else local wavemyvars = ""
	return local fixedVars "`wavemyvars'"
end

// this program to returns  which variables exist in this wave
program define getExistingVars, rclass
    version 14.0
	local all = ""
	foreach var in `1' {
		capture confirm variable `var'
		if !_rc {
			local all = "`all' `var'"
		}
	}
	return local existingVars "`all'"
end  

//loop through each wave
foreach wave in `allWaves' {
	// find the wave number
	local waveno=strpos("abcdefghijklmnopqrstuvwxyz","`wave'")

	// find the wave household vars
	getVars "`hhvars'" `wave'
	local wavehhvars = "`r(fixedVars)'"
}

display `wavehhvars'

keep `wavehhvars'

// failed vars: fihhml fihhyl grpay hhden01_xw hhden91_xw hhden99_xw hhdenub_xw hhdenui_xw hhdenus_xw hhyneti hhneti hhyrlg hhyrln na75pl netlab region

********************************************************************************
* Inspect
********************************************************************************
browse

********************************************************************************
********************************************************************************
********************************************************************************
**# CROSS-WAVE FILES
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
* Family matrix
********************************************************************************

use "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\cross wave\xhhrel.dta", clear

// so, takeaway here, for now, is that i don't need this for partner matching within waves. Might need to deal with for history purposes, but not right now.

********************************************************************************
*Fixed individual characteristics
********************************************************************************

use "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\cross wave\xwavedat.dta", clear

// this actually seems more important for some of the relationship history - some marital / cohab history questions only asked here - okay that might actually be false gah, I am so dumb.
// vars I had noted in my spreadsheet: pid pidp anychild_dv ch1by_dv feend_dv scend_dv school_dv coh1m_dv coh1mr coh1y_dv evercoh_dv evermar_dv lmar1m_dv lmar1y_dv birthy doby_dv lprnt_bh plbornc ukborn bornuk_dv lwenum_dv lwenum_dv_bh lwintvd_dv lwintvd_dv_bh psu strata

browse pidp birthy evercoh_dv evermar_dv lmar1y_dv lmar1m_dv coh1y_dv coh1m_dv coh1mr

tab evermar_dv, m // why are there so many missing? (30%) - doesn't seem to be an age thing...
tab memorig evermar_dv, row // doesn't seem to be a sample thing either
tab fwenum_dv evermar_dv, row // seems to get worse with each passing wave
tab fwenum_dv_bh evermar_dv, row // seems to get worse with each passing wave. idk, also come back to this. maybe once i have main file, can append this (since this will go with all records)


********************************************************************************
* ID info
********************************************************************************

use "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\cross wave\xwaveid.dta", clear

browse // okay yeah, maybe this is useful if I want wide data, but don't think I need for the moment.