// Accellera Standard V2.5 Open Verification Library (OVL).
// Accellera Copyright (c) 2005-2011. All rights reserved.


`ifdef OVL_ASSERT_ON
  
  wire error_event, error_event_xz;
  reg  error_coverage_fire, xz_detected_in_test_expr;

`ifdef OVL_SYNTHESIS
`else
  initial begin
    error_coverage_fire      = 1'b0; 
    xz_detected_in_test_expr = 1'b0;
  end
`endif

  always @( posedge clk ) begin
    if(`OVL_RESET_SIGNAL != 1'b1)
      begin
        error_coverage_fire      <= 1'b0; 
        xz_detected_in_test_expr <= 1'b0;
      end
    end

  assign error_event    = error_coverage_fire;
  assign error_event_xz = xz_detected_in_test_expr;

`endif // OVL_ASSERT_ON

`ifdef OVL_REVISIT // Tied low in V2.3 (in top-level file)
  `ifdef OVL_ASSERT_ON
    assign fire[0] = error_event;
    assign fire[1] = error_event_xz;
  `else
    assign fire[0] = 1'b0;
    assign fire[1] = 1'b0;
  `endif // OVL_ASSERT_ON

  `ifdef OVL_COVER_ON
    assign fire[2] = 1'b0;
  `else
    assign fire[2] = 1'b0;
  `endif // OVL_COVER_ON
`endif // OVL_REVISIT

`ifdef OVL_SHARED_CODE

  localparam stat_cnt_width = 32; 

  reg [stat_cnt_width-1:0] covered_count;
  wire                     covered_fire_combo;
  
  assign covered_fire_combo = (enable === 1'b1 && (test_expr^test_expr) === 1'b0 && test_expr === 1'b1);

`ifdef OVL_SYNTHESIS
`else
  initial begin
    covered_count = {stat_cnt_width{1'b0}};
  end
`endif
   
  always @(posedge clock) begin
    if(`OVL_RESET_SIGNAL != 1'b1) begin
      covered_count <= {stat_cnt_width{1'b0}};
    end
    else begin
      // Count the number of times a new value is loaded into the checked register
      if (enable === 1'b1 && test_expr === 1'b1) begin
        if (covered_count != {stat_cnt_width{1'b1}})
          covered_count <= covered_count + 1'b1;
      end 
    end 
  end 

`endif // OVL_SHARED_CODE


`ifdef OVL_ASSERT_ON

  property OVL_COVERAGE_CHECK_P;
  @(posedge clock)
    disable iff (`OVL_RESET_SIGNAL != 1'b1)
      (covered_fire_combo == 1'b0);
  endproperty

 `ifdef OVL_XCHECK_OFF
    // Do nothing
 `else

  `ifdef OVL_IMPLICIT_XCHECK_OFF
  `else

  property OVL_COVERAGE_XZ_IN_TEST_EXPR_P;
  @(posedge clock)
    disable iff (`OVL_RESET_SIGNAL != 1'b1)
      (!($isunknown(test_expr)));
  endproperty

  `endif // OVL_IMPLICIT_XCHECK_OFF
 `endif // OVL_XCHECK_OFF


  generate
    case (property_type)
      `OVL_ASSERT_2STATE,
      `OVL_ASSERT: begin : ovl_assert

           A_OVL_COVERAGE_CHECK_P:
           assert property (OVL_COVERAGE_CHECK_P)
	     error_coverage_fire <= 1'b0;
           else begin
             ovl_error_t(`OVL_FIRE_2STATE,"The HDL statement was covered");
	     error_coverage_fire <= 1'b1;
	   end  

`ifdef OVL_XCHECK_OFF
  //Do nothing
`else
  `ifdef OVL_IMPLICIT_XCHECK_OFF
    //Do nothing
  `else
         
	 A_OVL_COVERAGE_XZ_IN_TEST_EXPR_P:
         assert property (OVL_COVERAGE_XZ_IN_TEST_EXPR_P)
           xz_detected_in_test_expr <= 1'b0;
         else begin
           ovl_error_t(`OVL_FIRE_XCHECK,"test_expr contains X or Z");
           xz_detected_in_test_expr <= 1'b1;
         end

  `endif // OVL_IMPLICIT_XCHECK_OFF
`endif // OVL_XCHECK_OFF

      end

      `OVL_ASSUME_2STATE,
      `OVL_ASSUME: begin : ovl_assume
      
         M_OVL_COVERAGE_CHECK_P:
         assume property (OVL_COVERAGE_CHECK_P);

`ifdef OVL_XCHECK_OFF
  //Do nothing
`else
  `ifdef OVL_IMPLICIT_XCHECK_OFF
    //Do nothing
  `else

	M_OVL_COVERAGE_XZ_IN_TEST_EXPR_P:
        assume property (OVL_COVERAGE_XZ_IN_TEST_EXPR_P);

  `endif // OVL_IMPLICIT_XCHECK_OFF
`endif // OVL_XCHECK_OFF

      end

      `OVL_IGNORE : begin : ovl_ignore
        // do nothing;
      end
      default     : initial ovl_error_t(`OVL_FIRE_2STATE,"");
    endcase
  endgenerate

`endif // OVL_ASSERT_ON


`ifdef OVL_COVER_ON

  generate

    if (coverage_level != `OVL_COVER_NONE) begin : ovl_cover

      if (OVL_COVER_SANITY_ON) begin : ovl_cover_sanity

        cover_values_checked :
          cover property (
            @(posedge clock)
             (`OVL_RESET_SIGNAL != 1'b0) && !$stable(test_expr))
             ovl_cover_t("Test expression changed value");

      end : ovl_cover_sanity

      if (OVL_COVER_STATISTIC_ON) begin : ovl_cover_statistic
        
	cover_computations_checked :
          cover property (
            @(posedge clock)
             (`OVL_RESET_SIGNAL != 1'b0) && !$stable(covered_count))
             ovl_cover_t("Covered Count changed value");

      end : ovl_cover_statistic

    end : ovl_cover

  endgenerate

`endif // OVL_COVER_ON


