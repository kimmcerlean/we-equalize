set maxvar 10000

* Set home directory based on computing environment. 
if `"`c(hostname)'"' == "LAPTOP-TP2VHI6B" global homedir `"C:/Users/mcerl/OneDrive - Istituto Universitario Europeo"' // One Drive on Kim's PC
if `"`c(hostname)'"' == "PPRC-STATS-P01" global homedir `"T:"' // PRC Stats Server
if `"`c(hostname)'"' == "60018D" global homedir `"C:/Users/kmcerlea/OneDrive - Istituto Universitario Europeo"' // One Drive on EUI Computer

* This is where your code is. It is the directory you should change into before executing any files
if `"`c(hostname)'"' == "LAPTOP-TP2VHI6B" global code "G:/Other computers/My Laptop/Documents/GitHub/we-equalize/data-creation/gsoep"
if `"`c(hostname)'"' == "60018D" global code "\\bfsrv2\home$\kmcerlea\PersonalData\Documents\GitHub\we-equalize\data-creation\gsoep"

* This locations of folders containing the original data files
global GSOEP "$homedir/datasets/GSOEP/Stata"

* created data files
global created_data_gsoep "$homedir/datasets/GSOEP/created data"

* temporary data processing files
global temp_gsoep "$homedir/datasets/GSOEP/temp data"

cd "$code"