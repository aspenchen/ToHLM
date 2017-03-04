** Test using the productivity data
**--- Step 1: Ensure PATH VARIABLE are set: see howto at http://stats.idre.ucla.edu/other/hlm/faq/path/ ---**
**--- Step 2: Place all files in "v14" in your Stata personal directory; type *adopath* to find out directory location ---**
**--- Step 3: cd into "tohlm" directory ---**
capture mkdir testfiles
cd testfiles
clear
use "http://www.stata-press.com/data/r13/productivity", clear
hlm mkmdm using productivity.mdm, replace id(region) ///
           l1(gsp private) l2(hwy) ///
		   miss(now) nosts
hlm mdmset productivity.mdm
hlm hlm2 gsp int(int %hwy rand) ///
          %private(int) rand, ///
		  cmd(productivity) run replace

// delete testfiles and restore folder
confirm file creatmdm.mdmt // confirm location before deleting the testfiles folder
!rm *.*
cd ..
rmdir testfiles

