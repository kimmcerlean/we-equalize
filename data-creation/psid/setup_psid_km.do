

* Note that these directories will contain all "created" files - including intermediate data, results, and log files.
// global homedir "G:\Other computers\My Laptop\Documents"
global homedir "T:" // PRC server
// global homedir_EUI "C:\Users\kmcerlea\OneDrive - Istituto Universitario Europeo\projects" // EUI computer

* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global code "$homedir/github/we-equalize/data-creation/psid"

* This locations of folders containing the original data files
global PSID "$homedir/data/PSID"

* created data files
global created_data "$homedir/WeEqualize (Postdoc)/Compiled Data/PSID"

* temporary data files (they get deleted without a second thought)
global temp "$homedir/WeEqualize (Postdoc)/Temp Data/PSID"