// -------------------------------------------------------------
// Display Regression Footnote
// -------------------------------------------------------------
cap pr drop reghdfe_footnote
program reghdfe_footnote
syntax [, linesize(int 79)]


if (e(model)=="ols" & e(vce)=="unadjusted") {
	local dfa1  = e(df_a) + 1
	local todisp `"F(`e(df_a)', `e(df_r)') = "'
	local skip3 = max(23-length(`"`todisp'"')-2,0)
	local skip2 = max(14-length(`"`dfa1'"')-2,0)

	* This is messy b/c when displaying AvgE(..) we might go beyond 12 chars
	local vars : colnames e(b)
	local skip1 12
	foreach var of local vars {
		local skip1 = max(`skip1', length("`var'"))
	}
	foreach fe in `e(absvars)' {
		local skip1 = max(`skip1', length("`fe'"))
	}

	di as text %`skip1's "Absorbed" " {c |}" ///
		_skip(`skip3') `"`todisp'"' ///
		as res %10.3f e(F_absorb) %8.3f fprob(e(df_a),e(df_r),e(F_absorb)) ///
		as text _skip(13) `"(Joint test)"'

	* Col width
	local WX = `skip1' + 1

	* Show by-fe FStats
	* Relevant macros: NUM_FE, FE1, .., FE_TARGET1, .., FE_VARLIST
	local i 0
	local r2 = 1 - e(rss0)/e(tss)
	local r2_report %4.3f `r2'
	foreach fe in `e(absvars)' {
		local ++i
		if (e(F_absorb`i')<.) {
			di as text %`skip1's "`fe'" " {c |}" _continue
			
			local todisp `"F(`e(df_a`i')', `e(df_r`i')') = "'
			local skip3 = max(23-length(`"`todisp'"')-2,0)
			di as text _skip(`skip3') `"`todisp'"' _continue
			
			di as res %10.3f e(F_absorb`i') %8.3f fprob(e(df_a`i'),e(df_r`i'),e(F_absorb`i')) _continue
			di as text _skip(12) `"(Nested test)"'

			local r2 = 1 - e(rss`i')/e(tss)
			local r2_report `r2_report' " -> " %4.3f `r2'
			*local cats = e(K`i') - e(M`i')
			*local data = "`e(K`i')' categories, `e(M`i')' collinear, `cats' unique"
			*local skip = 62 - length("`data'")
			*di as text _skip(`skip') `"(`data')"'
		}
	}
	di as text "{hline `=1+`skip1''}{c BT}{hline 64}"
	if (e(rss0)<.) di as text " R-squared as we add HDFEs: " `r2_report'
} // regress-unadjusted specific
else {
	local skip1 12
	foreach fe in `e(absvars)' {
		local skip1 = max(`skip1', length("`fe'"))
	}
	local WX = `skip1' + 1
}

* Show category data
di as text _n "{hline `WX'}{c TT}{hline 49}{c TT}{hline 14}"
di as text %`skip1's "Absorbed FE" " {c |}" ///
	%13s "Num. Coefs." ///
	%16s "=   Categories" ///
	%15s "-   Redundant" ///
	"     {c |} " _continue

if ("`e(corr1)'"!="") di as text %13s "Corr. w/xb" _continue
di as text _n "{hline `WX'}{c +}{hline 49}{c +}{hline 14}"

	local i 0
	local explain_questionmark 0
	foreach fe in `e(absvars)' {
		local ++i
		di as text %`skip1's "`fe'" " {c |}" _continue
		local numcoefs = e(K`i') - e(M`i')
		local exact = cond(`i'>=3, "?", " ")
		local exact = cond(`e(M`i'_exact)'==0, "?", " ")
		if ("`exact'"=="?") local explain_questionmark 1
		di as text %13s "`numcoefs'" _continue
		di as text %16s "`e(K`i')'" _continue
		di as text %15s "`e(M`i')'" _continue
		di as text %2s "`exact'" "   {c |} " _continue
		if ("`e(corr`i')'"!="") {
			di as text %13.4f `e(corr`i')' _continue
		}
		di
	}
di as text "{hline `WX'}{c BT}{hline 49}{c BT}{hline 14}"
if (`explain_questionmark') di as text "? = number of redundant parameters may be higher"
// di as text _skip(4) "Fixed effect indicators: " in ye "`e(absvars)'"

end