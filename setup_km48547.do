// global homedir "T:" // comment this out if you are not using the PRC Remote Server

* This locations of folders containing the original data files
global PSID "/data/PSID"
global SIPP2014 "/data/sipp/2014"
global ACS "/data/ACS"
global CPS "/data/CPS"
global GSOEP "C:\Users\kmcerlea\OneDrive - Istituto Universitario Europeo\datasets\GSOEP\Stata"

********************************************************************************
** Personal Computer and PRC (just the homedir differs)
********************************************************************************

* Note that these directories will contain all "created" files - including intermediate data, results, and log files.
global homedir "G:\Other computers\My Laptop\Documents"

* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global code "$homedir/github/growth-curves"

* created data files
global created_data "$homedir/Research Projects/Growth Curves/created data"

* results
global results "$homedir/Research Projects/Growth Curves/results"

* logdir
global logdir "$homedir/Research Projects/Growth Curves/logs"

* temporary data files (they get deleted without a second thought)
global temp "$homedir/Research Projects/Growth Curves/temp data"

********************************************************************************
** EUI Computer
********************************************************************************
global homedir_EUI "C:\Users\kmcerlea\OneDrive - Istituto Universitario Europeo\projects"

global code "\\bfsrv2\home$\kmcerlea\PersonalData\Documents\GitHub\growth-curves"

* created data files
global created_data "$homedir_EUI/Growth Curves/created data"

* results
global results "$homedir_EUI/Growth Curves/results"

* logdir
global logdir "$homedir_EUI/Growth Curves/logs"

* temporary data files (they get deleted without a second thought)
global temp "$homedir_EUI/Growth Curves/temp data"


********************************************************************************
/* Create macro for current date
global logdate = string( d(`c(current_date)'), "%dCY.N.D" ) 		// create a macro for the date*/

/********************************************************************************
* Notes on order of operations for PSID
1. download data from PSID and run through PSID-generated .do files. Will name those "PSID-full"
2. In this github folder, run x_rename_variables, which you will get frm Excel sheet. This creates "PSID-full-renamed"
3. Then, go into step 1, and can use the renamed file
********************************************************************************/