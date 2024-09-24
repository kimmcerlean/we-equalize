********************************************************************************
* Marital dissolution
* setup_environment.do
* Kim McErlean
********************************************************************************

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file sets up the directories and specifies file locations for the project
* It also checks for any required packages

********************************************************************************
* SET UP
********************************************************************************

* Set up the base environment for my project.

* The current directory is assumed to be the one with the base code.

* We expect to find your setup file, named setup_<username>.do
* in "T:\github\SOC384\kmcerlean"


* Find my home directory, depending on OS.
if ("`c(os)'" == "Windows") {
    local temp_drive : env HOMEDRIVE
    local temp_dir : env HOMEPATH
    global homedir "`temp_drive'`temp_dir'"
    macro drop _temp_drive _temp_dir`
}
else {
    if ("`c(os)'" == "MacOSX") | ("`c(os)'" == "Unix") {
        global homedir : env HOME
    }
    else {
        display "Unknown operating system:  `c(os)'"
        exit
    }
}

********************************************************************************
* set seed for random variables
********************************************************************************

set seed 5389

********************************************************************************
* Check for personal setup file
********************************************************************************
* You must have a file in your current folder named setup_<your user name>.do
    * It will define your directories. See setup_example.do as an example of what you need to do.
    
// Checks that the setup file exists and runs it.
capture confirm file "setup_`c(username)'.do"
if _rc==0 {
    do setup_`c(username)'
      }
  else {
    display as error "The file setup_`c(username)'.do does not exist"
	exit
  }

********************************************************************************
* Check for package dependencies 
********************************************************************************
* This checks for packages that the user should install prior to running the project do files.

// fre: https://ideas.repec.org/c/boc/bocode/s456835.html
capture : which fre
if (_rc) {
    display as error in smcl `"Please install package {it:fre} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install fre":auto-install fre}"'
    log close
    exit 199
}

capture: which ereplace 
if (_rc) {
    display as error in smcl `"Please install package {it:ereplace} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install ereplace":auto-install ereplace}"'
    log close
    exit 199
}

capture: which stcompet 
if (_rc) {
    display as error in smcl `"Please install package {it:stcompet} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install stcompet":auto-install stcompet}"'
    log close
    exit 199
}


