
********************************************************************************
* Set base directory
********************************************************************************

// Kim's computers
* personal
if `"`c(hostname)'"' == "LAPTOP-TP2VHI6B" global root `"C:/Users/mcerl/OneDrive - Istituto Universitario Europeo/datasets/UKHLS"'
if `"`c(hostname)'"' == "LAPTOP-TP2VHI6B" global code    "G:/Other computers/My Laptop/Documents/GitHub/we-equalize/data-creation/ukhls" 

* PRC stats server
// if `"`c(hostname)'"' == "PPRC-STATS-P01" global root `"T:/Research Projects/Relationship Life Course (with LP)"'

* EUI computer
if `"`c(hostname)'"' == "60018D" global root `"C:/Users/kmcerlea/OneDrive - Istituto Universitario Europeo/datasets/UKHLS"'
if `"`c(hostname)'"' == "60018D" global code "//bfsrv2/home$/kmcerlea/PersonalData/Documents/GitHub/we-equalize/data-creation/ukhls"

// Add your computers here (for root + code). If you need to display your hostname, type: display `"`c(hostname)'"'

// if `"`c(hostname)'"' == "{insert hostname here}" global root "Directory"
// if `"`c(hostname)'"' == "{insert hostname here}" global code "Directory"

********************************************************************************
* Relevant folders
********************************************************************************
// raw data
global UKHLS "$root/UKDA-6614-stata/stata/stata13_se" // Main data
global UKHLS_mh "$root/UKDA-8473-stata/stata" // Cohab / marriage history
global egoalt "$root/UKDA-6614-stata/stata/egoalt (all waves)" // Ego alt relationship matrices

// created data
global created_data_ukhls "$root/created_data"
global temp_ukhls "$root/temp_data" 

cd "$code"

