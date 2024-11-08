/*****************************************************************************************
* MATCHING INDIVIDUALS WITHIN A HOUSEHOLD                                                *
* In this example we will match the information of respondents living with               *
* partners/spouses onto that of their partners/spouses.                                  *
*****************************************************************************************/

** Step 1. Remove * and replace "filepath of your working directory" 
** with the filepath where you want to save all files
** That is your working directory. 
** Remember to include the double quotes
cd "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\wave 2 (test wave)"

** Step 2. When you download and unzipped the data folder, 
** you will see that the data is provided in two folders "ukhls" and "bhps". 
** In this step, remove * and replace "filepath of downloaded data" 
** with the filepath where you have saved the two folders "ukhls" and "bhps"
** Remember to include the double quotes
global datain "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\wave 2 (test wave)"


// Open data file for all enumerated individuals and select the 
// variables for which you want to create a spouse/partner version
use b_hidp b_pno b_ppno b_sex_dv b_age_dv using "$datain/b_indall", clear

// Restrict to individuals who have a spouse/partner in the household
// If an individual does not have a partner then b_ppno will be 0,
// if they do have a partner then b_ppno is the pno of their partner
keep if b_ppno>0

// rename all individual characteristics to something that would indicate
// the characteristics refer to the spouse/partner. Here the prefix sp_
// before the variable stem name and preserve the wave prefix
rename b_* b_sp_*

// rename the spouse/partner pno variable to respondent pno for matching to their partner
rename b_sp_ppno b_pno

// rename the hidp back to b_hidp  
rename b_sp_hidp b_hidp

// drop the variable b_sp_pno as it is no longer needed
drop b_sp_pno 

// save the file temporarily
save tmp_spinfo, replace


// reopen data file for all enumerated individuals and keep the same set of variables
use b_hidp b_pno b_ppno b_sex_dv b_age_dv using "$datain/b_indall", clear

// restrict the variables to individuals who have a spoise/partner in the household
keep if b_ppno>0

// merge the data with the data relating to the spouse/partner, using
// b_hidp and b_pno as linking variables. Note that there SHOULD NOT BE
// any non-matching records, that is, the value of _merge=3 
merge 1:1 b_hidp b_pno using tmp_spinfo

// drop the merge variable otherwise future merges will not work
drop _merge

// save the data file
save spinfo, replace 

// clean up unwanted files
erase tmp_spinfo.dta


********************************************************************************
**# Now try with mine
********************************************************************************

use "$outputpath/UKHLS_long_all_recoded.dta", clear

drop if partnered==0

// just keep necessary variables
local partnervars "pidp pid hidp pno ppno sampst sex jbstat qfhigh racel racel_dv nmar aidhh aidxhh aidhrs jbhas jboff jbbgy jbhrs jbot jbotpd jbttwt ccare dinner howlng fimngrs_dv fimnlabgrs_dv fimnlabnet_dv paygl paynl paygu_dv payg_dv paynu_dv payn_dv ethn_dv nchild_dv ndepchl_dv rach16_dv qfhigh_dv hiqual_dv lcohnpi coh1bm coh1by coh1mr coh1em coh1ey lmar1m lmar1y cohab cohabn lmcbm1 lmcby41 currpart1 lmspm1 lmspy41 lmcbm2 lmcby42 currpart2 lmspm2 lmspy42 lmcbm3 lmcby43 currpart3 lmspm3 lmspy43 lmcbm4 lmcby44 currpart4 lmspm4 lmspy44 hubuys hufrys humops huiron husits huboss lmcbm5 lmcby45 currpart5 lmspm5 lmspy45 lmcbm6 lmcby46 currpart6 lmspm6 lmspy46 lmcbm7 lmcby47 currpart7 lmspm7 lmspy47 isced11_dv region hiqualb_dv huxpch hunurs race qfedhi qfachi isced nmar_bh racel_bh age_all dob_year marital_status_legal marital_status_defacto partnered employed"

keep survey wavename year `partnervars'

// rename them to indicate they are for spouse
foreach var in `partnervars'{
	rename `var' `var'_sp
}

// rename the spouse/partner pno variable to respondent pno for matching to their partner
rename ppno pno

// rename the hidp back to b_hidp  
rename hidp_sp hidp

// drop the variable b_sp_pno as it is no longer needed
drop pno_sp 
drop if pno==0

save "$temp/UKHLS_partners_test.dta", replace

// now open file and merge on partner characteristics
use "$outputpath/UKHLS_long_all_recoded.dta", clear

merge 1:1 hidp pno wavename using "$temp/UKHLS_partners_test.dta"
drop if _merge==2
tab survey _merge, m
tab partnered _merge, m // okay this still doesn't seem to be helping? it works within a specific wave, but not when combined? is this my fault somehow? in the way I am aggregating? do I have to match all WITHIN a wave first?! then combine? is it also who is in indall v. indresp?!


********************************************************************************
**# Alt test - bc of non-response? need INDALL
********************************************************************************
use "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\wave 2 (test wave)\b_indall.dta", clear
rename pidp partner_id

save "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\wave 2 (test wave)\b_indall_tmp.dta", replace

use "$outputpath/UKHLS_long_all_recoded.dta", clear

drop if partnered==0
keep if wavename==2

merge m:1 partner_id using "G:\Other computers\My Laptop\Documents\WeEqualize (Postdoc)\Dataset info\UK data\data files\wave 2 (test wave)\b_indall_tmp.dta", keepusing(b_ivfio)
drop if _merge==2 // okay so here, 99% matched

tab ivfio, m // main interview status
tab b_ivfio, m // partner's interview status // yeah so about 84% full interview, 7% proxy, 7% refusal or other non-interview. which essentially aligns with my match rate. so this would be why. okay i am so annoying. 

