********************************************************************************
********************************************************************************
* Project: Relative Density Approach - UK
* Code owner: Kimberly McErlean
* Started: September 2024
* File name: a_compile_data.do
********************************************************************************
********************************************************************************

********************************************************************************
* Description
********************************************************************************
* This file taks all of the wave specific data, appends to create one longitudinal
* file, as well as matches on some wave-specific HH characteristics
* This file also has relevant macros to use throughout the code
* (will work on a separate macro specific file to make this easier)

********************************************************************************
* Note: this code has been adapted from UKHLS code creator (available when you
* add variables to your cart here: https://www.understandingsociety.ac.uk/documentation/mainstage/variables/)
* Sample Code for your request:  2d16f6ee0ebf4c37a54bb709c012e475
********************************************************************************

clear all
set more off

// Replace "where" with the filepath of the working folder (where any temporary files created by this programme will be stored)   eg:  c:\ukhls\temp
// cd "$temp_ukhls"

// The file produced by this programme will be named as below. If you want to change the name do it here.
local outputfilename "UKHLS_long_all"

// By default the data will be extracted from the waves whose letter prefixes are written below, and merged. If you want to a different selection of waves, make the change here
local allWaves = "a b c d e f g h i j k l m n ba bb bc bd be bf bg bh bi bj bk bl bm bn bo bp bq br"

// These variables from the indresp files will be included. These include some key variables as determined by us PLUS any variables requested by you. 
local indvars "age age_dv aidhh aidhrs aidhrs_bh aidxhh birthy ccare coh1bm coh1by coh1em coh1ey coh1mr cohab cohab_dv cohabn country currmstat currpart1 currpart2 currpart3 currpart4 currpart5 currpart6 currpart7 dinner doby doby_dv emboost ethn_dv feend fenow fenow_bh fimngrs_dv fimnlabgrs_dv fimnlabnet_dv gor_dv hgpart hgr2r hgra hgsex hhch12 hhsize hhtype hhtype_dv hid hidp hiqual_dv hiqualb_dv hoh howlng hrpid hrpno huboss hubuys hubuys_bh hufrys hufrys_bh huiron huiron_bh humops humops_bh hunurs husits husits2 huxpch ind5mus_lw ind5mus_xw indbd91_lw indbdub_lw indin01_lw indin01_xw indin91_lw indin91_xw indin99_lw indin99_xw indinub_lw indinub_xw indinui_lw indinui_xw indinus_lw indinus_xw indns91_lw indnsub_lw indpxub_lw indpxub_xw indpxui_lw indpxui_xw indpxus_lw indpxus_xw indscub_lw indscub_xw indscui_lw indscui_xw indscus_lw indscus_xw isced ivfio j2hrs jbbgy jbhas jbhrs jboff jbot jbotpd jbstat jbttwt jshrs lcoh lcohnpi livesp_dv lmar1m lmar1y lmcbm1 lmcbm2 lmcbm3 lmcbm4 lmcbm5 lmcbm6 lmcbm7 lmcby41 lmcby42 lmcby43 lmcby44 lmcby45 lmcby46 lmcby47 lmspm1 lmspm2 lmspm3 lmspm4 lmspm5 lmspm6 lmspm7 lmspy41 lmspy42 lmspy43 lmspy44 lmspy45 lmspy46 lmspy47 lnprnt lprnt marstat marstat_dv mastat mastat_dv mlstat mlstat_bh nchild_dv ndepchl_dv nmar nmar_bh payg_dv paygl paygu_dv paygw paygwc payn_dv paynl paynu_dv pid pidp plbornc pno ppid ppno psu qfachi qfedhi qfhigh qfhigh_dv race racel racel_bh racel_dv rach16_dv region sampst sampst_bh scend school sex sex_dv single_dv spjb spjbhr spjbot sppayg sppid sppid_bh sppno strata tenure_dv ukborn urban_dv intdatd_dv intdatm_dv intdaty_dv istrtdatd istrtdatm istrtdaty month"

// These variables from the hhresp files will be included. These include some key variables as determined by us PLUS any variables requested by you. 
local hhvars "agechy_dv country emboost fihhml fihhmngrs_dv fihhmnlabgrs_dv fihhmnlabnet_dv fihhmnnet1_dv fihhyl gor_dv grpay hhden01_xw hhden91_xw hhden99_xw hhdenub_xw hhdenui_xw hhdenus_xw hhneti hhsize hhtype hhtype_dv hhyneti hhyrlg hhyrln hid hidp hrpid hrpno ieqmoecd_dv na75pl nch02_dv nch1215_dv nch34_dv nch511_dv ncouple_dv nemp_dv netlab nkids_dv npens_dv psu region strata tenure_dv urban_dv intdatey intdatem intdated"

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Anything below this line should not be changed! Any changes to the selection of variables and waves, and location of folders, should be made above. //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
local i=1

foreach wave in `allWaves' {
	// find the wave number
	//local waveno=strpos("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz","`wave'")
	local waveno=`i'

	// find the wave household vars
	getVars "`hhvars'" `wave'
	local wavehhvars = "`r(fixedVars)'"
	
	// find the wave individual vars
	getVars "`indvars'" `wave'
	local waveindvars = "`r(fixedVars)'"
	
	
	// open the the household level file with the required variables
	use "$UKHLS/`wave'_hhresp", clear
	getExistingVars "`wave'_hidp `wavehhvars'"
	keep `r(existingVars)'
	
	// if only household variables are required, skip this part and return all households
	if ("`indvars'" != "" || "`chvars'" != "" || "`youthvars'" != "") {
		// if any individual variable is required, first  merge INDALL keeping the pipd (and possibly some default variables?), so that other files can merge on it.
		// merge 1:m `wave'_hidp using "$UKHLS/`wave'_indall"
		// drop _merge
		// drop loose households with no individuals
		// drop if (pidp == .)
		
		// keep only variables that were requested and exist in this wave
		getExistingVars "pidp pid `wave'_hidp `wavehhvars'"
		keep `r(existingVars)'
		
		// add any requested individual variables
		if ("`indvars'" != "") {
			merge 1:m `wave'_hidp using "$UKHLS/`wave'_indresp"
			drop _merge
			// keep only variables that were requested and exist in this wave
			getExistingVars "pidp pid `wave'_hidp `wavehhvars' `waveindvars'"
			keep `r(existingVars)'
		}
	}

	// create a wave variable
	gen wavename=`waveno'

	// drop the wave prefix from all variables
	rename `wave'_* *

	// save the file that was created
	save "$temp_ukhls/temp_`wave'", replace
	
local ++i
	
}

// open the file for the first wave (wave a_)
local firstWave = substr("`allWaves'", 1, 1)
use "$temp_ukhls/temp_`firstWave'", clear

// loop through the remaining waves appending them in the long format
local remainingWaves = substr("`allWaves'", 3, .)

foreach w in `remainingWaves' {
	// append the files for the second wave onwards
	append using "$temp_ukhls/temp_`w'"
}

// check how many observations are available from each wave
tab wavename

// move pidp to the beginning of the file
order pidp, first
sort pidp wavename

// save the long file
save "$created_data_ukhls/`outputfilename'", replace

// erase temporary files
foreach w in `allWaves' {
	erase "$temp_ukhls/temp_`w'.dta"
}

browse pidp pid hidp wavename age age_dv marstat_dv husits howlng hubuys hufrys huiron humops jbhrs

// $syntax;