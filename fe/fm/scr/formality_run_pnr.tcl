#set_app_var hdlin_dwroot /home6/uranus/tools/dc_2019

set synopsys_auto_setup true

set DESIGN_MODULE DIG_TOP

set_svf -append { ../../syn/svf/DIG_TOP.svf }

read_db {	/proj003/soc/users/yssong/sorento/trunk/lib/sec4n/sc/synopsys/ln04lpp_sc_s7p94t_flk_rvt_c60l04_ffpg_nominal_min_0p8250v_125c_lvf_dth.db_ccs_tn	\
			/proj003/soc/users/yssong/sorento/trunk/lib/sec4n/sc/synopsys/ln04lpp_sc_s7p94t_flkp_rvt_c60l04_ffpg_nominal_min_0p8250v_125c.db	\
			/proj003/soc/users/yssong/sorento/trunk/lib/sec4n/sc/synopsys/ln04lpp_sc_s7p94t_flk_rvt_c60l04_sspg_nominal_max_0p6750v_m40c_lvf_dth.db_ccs_tn	\
			/proj003/soc/users/yssong/sorento/trunk/lib/sec4n/sc/synopsys/ln04lpp_sc_s7p94t_flkp_rvt_c60l04_sspg_nominal_max_0p6750v_m40c.db	\
			/proj003/soc/users/yssong/sorento/trunk/lib/sec4n/sc/synopsys/ln04lpp_esd_s7p94t_cdm_rvt_c60l04_ffpg_nominal_min_0p8250v_125c.db_ccs_tn	\
			/proj003/soc/users/yssong/sorento/trunk/lib/sec4n/sc/synopsys/ln04lpp_esd_s7p94t_cdm_rvt_c60l04_sspg_nominal_max_0p6750v_m40c.db_ccs_tn	\			
			}



read_verilog -container r -libname WORK -05 { ../../syn/net/final.DIG_TOP.v } 
set_top r:/WORK/DIG_TOP

read_verilog -container i -libname WORK -05 ../../../be/DIG_TOP_nopg.v
set_top i:/WORK/DIG_TOP

current_design {DIG_TOP}

match                                                > ../rpt/1_${DESIGN_MODULE}.match.rpt
report_unmatched_points

if { [verify r:/WORK/$DESIGN_MODULE i:/WORK/$DESIGN_MODULE] != 1} {
	diagnose
	report_error_candidates
	report_failing_points

	save_session -replace ${DESIGN_MODULE}.session
	return
} else {
	verify                                               > ../rpt/2_${DESIGN_MODULE}.verify.rpt
	report_designs                                       > ../rpt/3_${DESIGN_MODULE}.design.rpt
	report_hierarchy r:/WORK/$DESIGN_MODULE 			 > ../rpt/4_${DESIGN_MODULE}.ref_hier.rpt
	report_hierarchy i:/WORK/$DESIGN_MODULE 			 > ../rpt/5_${DESIGN_MODULE}.imp_hier.rpt
	report_parameters                                    > ../rpt/6_${DESIGN_MODULE}.para.rpt
	report_svf                                           > ../rpt/7_${DESIGN_MODULE}.svf.rpt
	report_verify_points                                 > ../rpt/8_${DESIGN_MODULE}.verify.rpt
	report_matched_points                                > ../rpt/9_${DESIGN_MODULE}.match.rpt
}

exit
