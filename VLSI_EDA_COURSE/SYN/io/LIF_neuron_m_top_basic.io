(globals
    version = 3
    io_order = default
)
(iopad
    (topleft
	(inst name="CORNER_NW" cell=PCORNER place_status=placed))
    (top
        (inst  name="iopads_inst/Pvss0" place_status=placed )
        (inst  name="iopads_inst/pclk"           place_status=placed )
        (inst  name="iopads_inst/prst_n"         place_status=placed )
        (inst  name="iopads_inst/psvalid"        place_status=placed )
        (inst  name="iopads_inst/precc"      	 place_status=placed )
        (inst  name="iopads_inst/pthres_valid"   place_status=placed )
        (inst  name="iopads_inst/pspike"   place_status=placed )
        (inst  name="iopads_inst/Pvdd0" place_status=placed )
    )
    (bottomleft
    	(inst name="CORNER_SW" cell=PCORNER place_status=placed))
    (left
        (inst  name="iopads_inst/Pvdd1" place_status=placed )
        (inst  name="iopads_inst/pwspike0"      place_status=placed )
        (inst  name="iopads_inst/pwspike1"      place_status=placed )
        (inst  name="iopads_inst/pwspike2"      place_status=placed )
        (inst  name="iopads_inst/pstate0"      place_status=placed )
        (inst  name="iopads_inst/pstate1"      place_status=placed )
        (inst  name="iopads_inst/pstate2"      place_status=placed )
        (inst  name="iopads_inst/pstate3"      place_status=placed )
        (inst  name="iopads_inst/Pvss1" place_status=placed )
    )
    (bottomright
    	(inst name="CORNER_SE" cell=PCORNER offset=0.0 place_status=fixed))    
    (bottom
        (inst  name="iopads_inst/Pvdd2" place_status=placed )
        (inst  name="iopads_inst/pthres0"     place_status=placed )
        (inst  name="iopads_inst/pthres1"     place_status=placed )
        (inst  name="iopads_inst/pthres2"     place_status=placed )
        (inst  name="iopads_inst/pthres3"     place_status=placed )
        (inst  name="iopads_inst/pthres4"     place_status=placed )
        (inst  name="iopads_inst/pthres5"     place_status=placed )
	(inst  name="iopads_inst/Pvss2" place_status=placed )
    )
    (topright
    	(inst name="CORNER_NE" cell=PCORNER offset=0.0 place_status=fixed))        
    (right
        (inst  name="iopads_inst/Pvss3" place_status=placed )
        (inst  name="iopads_inst/pv0"     place_status=placed )
        (inst  name="iopads_inst/pv1"     place_status=placed )
        (inst  name="iopads_inst/pv2"     place_status=placed )
        (inst  name="iopads_inst/pv3"     place_status=placed )
        (inst  name="iopads_inst/pv4"     place_status=placed )
        (inst  name="iopads_inst/pv5"     place_status=placed )
        (inst  name="iopads_inst/Pvdd3" place_status=placed )
    )
)
