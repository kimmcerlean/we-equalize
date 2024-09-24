global homedir "T:" // comment this out if you are not using the PRC Remote Server

* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global code "$homedir/github/growth-curves"


* This locations of folders containing the original data files
global PSID "/data/PSID"
global SIPP2014 "/data/sipp/2014"
global ACS "/data/ACS"
global CPS "/data/CPS"


* Note that these directories will contain all "created" files - including intermediate data, results, and log files.

* created data files
global created_data "$homedir/Research Projects/Growth Curves/created data"

* results
global results "$homedir/Research Projects/Growth Curves/results"

* logdir
global logdir "$homedir/Research Projects/Growth Curves/logs"

* temporary data files (they get deleted without a second thought)
global temp "$homedir/Research Projects/Growth Curves/temp data"

********************************************************************************
/* Create macro for current date
global logdate = string( d(`c(current_date)'), "%dCY.N.D" ) 		// create a macro for the date*/

/********************************************************************************
* Notes on order of operations
1. download data from PSID and run through PSID-generated .do files. Will name those "PSID-full"
2. In this github folder, run x_rename_variables, which you will get frm Excel sheet. This creates "PSID-full-renamed"
3. Then, go into step 1, need to add any new variables to the reshape (see Excel) and run through step 1 to get new long data file.
4. Then, run through step 1a - this is where most recodes happen
5. Then, turn to step 3 - analysis

********************************************************************************/