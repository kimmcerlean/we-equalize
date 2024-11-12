********************************************************************************
** Set home directory
********************************************************************************
global homedir "G:\Other computers\My Laptop\Documents"

********************************************************************************
** Original / base data
********************************************************************************
* UKHLS
global UKHLS "$homedir/data/UKHLS"
global UKHLS_mh "C:\Users\kmcerlea\OneDrive - Istituto Universitario Europeo\datasets\UKHLS\UKDA-8473-stata\stata\stata13"
global created_data_ukhls "$homedir/WeEqualize (Postdoc)/Compiled Data/UKHLS"
global temp_ukhls "$homedir/WeEqualize (Postdoc)/Temp Data/UKHLS"

********************************************************************************
** Project specific data files
********************************************************************************
* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global code "$homedir/github/we-equalize/projects/relative-density"

* PROJECT SPECIFIC created data files
global created_data "$homedir/WeEqualize (Postdoc)/Paper 1 - Relative Density Approach/output data"

* PROJECT SPECIFIC results
global results "$homedir/WeEqualize (Postdoc)/Paper 1 - Relative Density Approach/results"

* PROJECT SPECIFIC logdir
global logdir "$homedir/WeEqualize (Postdoc)/Paper 1 - Relative Density Approach/logs"

* PROJECT SPECIFIC temporary data files (they get deleted without a second thought)
global temp "$homedir/WeEqualize (Postdoc)/Paper 1 - Relative Density Approach/temp data"
