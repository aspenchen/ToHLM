*! updates; pac-07JAN2018
*! updated stata package for hlm 7 student version: pac 04MAR17
*! version 2.0, sean f. reardon, 30dec2005

/****************************************************

The hlm_s command calls several other subcommands:
 1) mkmdm_s -- which creates an hlm mdm file
 2) mdmset_s -- which sets an mdm file in memory for stata to refer to
 3) hlm2_s -- which creates an hlm2 command file
 4) hlm3_s -- which creates an hlm3 command file
 5) hlmrun_s -- which runs an existing hlm command file

hlm_s.ado and these other .ado files call several other .ado files:
 6) hlmmkmdm2_s -- which creates an hlm2 mdm file
 7) hlmmkmdm3_s -- which creates an hlm3 mdm file
 8) hlmtest_s -- which parses the test option in hlm2.ado and hlm3.ado

*****************************************************/

capture program drop hlm_s
program define hlm_s
version 13
	gettoken subcmd 0: 0
	if "`subcmd'" == "mkmdm_s" {
		mkmdm_s `0'
	}
	else if "`subcmd'" == "mdmset_s" {
		mdmset_s `0'
	}
	else if "`subcmd'" == "hlm2_s" {
		preserve
		use "$varfile", clear
		hlm2_s `0'
		restore
	}
	else if "`subcmd'" == "hlm3_s" {
		preserve
		use "$varfile", clear
		hlm3_s `0'
		restore
	}
	else if "`subcmd'" == "run" {
		hlmrun_s `0'
	}
	else error 199
end


/****************************************************
The mkmdm command creates hlm2 and hlm3 mdm files
****************************************************/

capture program drop mkmdm_s
program define mkmdm_s
version 13
	syntax using/ [if] [in], ID2(varname) ///
		[Type(string) id3(varname) l1(varlist) l2(varlist) l3(varlist) ///
		Miss(string) NOMDMT NODTA NOSTS REPLACE noRUN]

marksample touse
qui count if `touse'
if r(N)==0 {
	di in re "no observations"
	exit 2000 // "no observation"
}

// variable type and length check for options l1, l2, and l3
foreach var of local l1 {
	if "`var'" ~= "`id2'" & "`var'" ~= "`id3'" {
		local vartype : type `var'
		local test = index("`vartype'", "str") // strpos() instead of index()
		if `test' == 0 local l1list `l1list' `var'
		else display in red "String variable `var' has been dropped."
	}
	local varlngth : length local var
	if `varlngth' > 8 {
		di in re "Variable name `var' longer than 8 characters"
		error 197 // "invalid context"
	}
}
foreach var of local l2 {
	if "`var'" ~= "`id2'" & "`var'" ~= "`id3'" {
		local vartype : type `var'
		local test = strpos("`vartype'", "str") // updated from index()
		if `test' == 0 local l2list `l2list' `var'
		else display in red "String variable `var' has been dropped."
	}
	local varlngth : length local var
	if `varlngth' > 8 {
		di in re "Variable name `var' longer than 8 characters"
		error 197 // "invalid context"
	}
}
if upper("`type'") == "HLM3" | upper("`type'") == "HMLM3" {
	foreach var of local l3 {
		if "`var'" ~= "`id2'" & "`var'" ~= "`id3'" {
			local vartype : type `var'
 			local test = strpos("`vartype'", "str")
 			if `test' == 0 local l3list `l3list' `var'
			else display in red "String variable `var' has been dropped."
		}
		local varlngth : length local var
		if `varlngth' > 8 {
			di in re "Variable name `var' longer than 8 characters"
			error 197 // "invalid context"
		}
	}
}
if "`l1list'"=="" {
	di in re "no level 1 variables specified"
	exit
}
if "`l2list'"=="" {
	di in re "no level 2 variables specified"
	exit
}
if "`l3list'"=="" & upper("`type'")=="HLM3" {
	di in re "no level 3 variables specified"
	exit
}

local allvars `id3' `id2' `l1list' `l2list' `l3list'

foreach var of local allvars {
	capture confirm new variable `var'
	if _rc==0 {
		di in re "Variable `var' not found" // check all vars in dataset
		exit
	}
}
// miss option specifies when to delete missing cases
if "`miss'"=="" {
	local vartype : type `id2'
	local test = index("`vartype'", "str")
	if `test' ~= 0 {
		quietly count if `id2'==""
		if r(N)>0 {
			display in red "Variable `id2' has missing cases; specify miss option"
			exit 127
		}
	}
	else local i2 `id2'
	if "`id3'"~="" {
		local vartype : type `id3'
		local test = index("`vartype'", "str")
		if `test' ~= 0 {
			quietly count if `id3'==""
			if r(N)>0 {
				display in red "Variable `id3' has missing cases; specify miss option"
				exit 127
			}
		}
		else local i3 `id3'
	}
	local numvars `i2' `i3' `l1list' `l2list' `l3list'
	foreach var of local numvars {
		quietly count if `var'==.
		if r(N)>0 {
			display in red "Variable `var' has missing cases; specify miss option"
			exit 127
		}
	}
}
if "`miss'"~="" &  "`miss'"~="now" & "`miss'"~="analysis" {
	display in yellow "Miss option must be 'now' or 'analysis'"
	error 197
}

gettoken upath uext: using, p(".")
if "`uext'"=="" | "`uext'"==".mdm" local using "`upath'"
else {
	di in re "using file must have an .mdm extension or no extension"
	error 603
}

preserve
qui keep if `touse'
drop `touse'
qui order `allvars'
if upper("`type'") == "HLM2" | "`type'"=="" {
	hlmmkmdm2_s using `using', id2(`id2') l1(`l1list') l2(`l2list') miss(`miss') ///
	                           `nomdmt' `nodta' `nosts' `replace' `run'
}
else if upper("`type'") == "HLM3" {
	hlmmkmdm3_s using `using', id2(`id2') id3(`id3') l1(`l1list') l2(`l2list') ///
	                           l3(`l3list') miss(`miss') `nomdmt' `nodta' ///
														 `nosts' `replace' `run'
}

restore
end


/*----------------------------------------------------
  this program sets the .mdm file to use for subsequent
  HLM models.  the file can be specified with an .mdm
  extension or without.  "hlm mdmset _drop" drops the
  mdm file from memory.
----------------------------------------------------*/

capture program drop mdmset_s
program define mdmset_s
version 13
	syntax anything(id="mdm filename" name=filename)

if `"`filename'"' == "" global mdmfile ""
else if `"`filename'"' == "_drop" macro drop mdmfile
else {
	gettoken path ext: filename, p(".")
	if "`ext'"=="" local filename `"`filename'.mdm"'
	else if "`ext'" ~= ".mdm" {
		di in re "file must be an .mdm file"
		error 603 // "file ____ cannot be opened"
	}
	confirm file `"`filename'"'

	local junk : subinstr local path ":" "", count(local col) all
	if `col' == 1 {
		confirm file `path'_mdmvars.dta
		global mdmfile `"`filename'"'
		global varfile `"`path'_mdmvars.dta"'
	}
	else if `col' == 0 {
		confirm file `"`c(pwd)'`c(dirsep)'`path'_mdmvars.dta"'
		global mdmfile `"`c(pwd)'`c(dirsep)'`filename'"'
		global mdmfile : subinstr global mdmfile "/" "\"
		global varfile `"`c(pwd)'`c(dirsep)'`path'_mdmvars.dta"'
	}
	else error 601 // "file ____ cannot be found"
	macro drop junk col
}
end
