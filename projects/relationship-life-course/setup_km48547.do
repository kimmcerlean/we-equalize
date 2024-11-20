********************************************************************************
** Set home directory
********************************************************************************
global homedir "G:\Other computers\My Laptop\Documents"
// global homedir "T:" // comment this out if you are not using the PRC Remote Server

********************************************************************************
** Original / base data
********************************************************************************

* PSID
global PSID "$homedir/data/PSID"
global created_data_psid "$homedir/WeEqualize (Postdoc)/Compiled Data/PSID"
global temp_psid "$homedir/WeEqualize (Postdoc)/Temp Data/PSID"

* UKHLS
global UKHLS "$homedir/data/UKHLS"
global UKHLS_mh "C:\Users\kmcerlea\OneDrive - Istituto Universitario Europeo\datasets\UKHLS\UKDA-8473-stata\stata\stata13"
global created_data_ukhls "$homedir/WeEqualize (Postdoc)/Compiled Data/UKHLS"
global temp_ukhls "$homedir/WeEqualize (Postdoc)/Temp Data/UKHLS"

* GSOEP
global GSOEP "$homedir/data/GSOEP"
global created_data_gsoep "$homedir/WeEqualize (Postdoc)/Compiled Data/GSOEP"
global temp_gsoep "$homedir/WeEqualize (Postdoc)/Temp Data/GSOEP"

********************************************************************************
** Project specific data files
********************************************************************************
* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global code "$homedir/github/we-equalize/projects/relationship-life-course"

* PROJECT SPECIFIC created data files
global created_data "$homedir/Research Projects/Growth Curves/created data"

* PROJECT SPECIFIC results
global results "$homedir/Research Projects/Growth Curves/results & output"

* PROJECT SPECIFIC logdir
global logdir "$homedir/Research Projects/Growth Curves/logs"

* PROJECT SPECIFIC temporary data files (they get deleted without a second thought)
global temp "$homedir/Research Projects/Growth Curves/temp data"


********************************************************************************
**# EUI Computer
********************************************************************************
global homedir "C:\Users\kmcerlea\OneDrive - Istituto Universitario Europeo"

********************************************************************************
** Original / base data
********************************************************************************

* PSID
global PSID "$homedir/datasets/PSID"
global created_data_psid "$homedir/datasets/PSID/created data"
global temp_psid "$homedir/datasets/PSID/temp data"

* UKHLS
global UKHLS "$homedir/datasets/UKHLS/UKDA-6614-stata/stata/stata13_se"
global UKHLS_mh "$homedir/datasets\UKHLS\UKDA-8473-stata/stata/stata13"
global created_data_ukhls "$homedir/projects/UK Relative Density/output data" 
global temp_ukhls "$homedir/projects/UK Relative Density/temp created files"

* GSOEP
global GSOEP "$homedir/datasets/GSOEP/Stata"
global created_data_gsoep "$homedir/datasets/GSOEP/created data"
global temp_gsoep "$homedir/datasets/GSOEP/temp data"


********************************************************************************
** Project specific data files
********************************************************************************
* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global code "$homedir/github/we-equalize/projects/relationship-life-course"

* PROJECT SPECIFIC created data files
global created_data "$homedir/projects/Growth Curves/created data"

* PROJECT SPECIFIC results
global results "$homedir/projects/Growth Curves/results"

* PROJECT SPECIFIC logdir
global logdir "$homedir/projects/Growth Curves/logs"

* PROJECT SPECIFIC temporary data files (they get deleted without a second thought)
global temp "$homedir/projects/Growth Curves/temp data"

