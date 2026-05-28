`timescale 1ns/10ps

module tb();

	`include "vector_gen.inc"
	reg		CLK;
	reg		RSTB;

	reg		CSN;
	reg 	SCLK;
	reg		MOSI;
	wire	MISO;

//Analog Interface Port
//address: 0x00
	wire	[15:00]	PF_CTRL			 ;
//address: 0x01	
	wire	[01:00]	PF_LOCK_CON_DLY	 ;
	wire	[01:00]	PF_LOCK_CON_IN	 ;
	wire	[01:00]	PF_LOCK_CON_OUT	 ;
	wire			PF_LOCK_EN		 ;
	wire			PF_RESETB		 ;
	wire			PF_BYPASS		 ;
	wire			PF_FSEL			 ;
	wire			PF_FEED_EN		 ;
	wire			PF_AFC_ENB		 ;
	wire	[01:00]	PF_ICP			 ;
//address: 0x02	
	wire	[04:00]	PF_EXTAFC		 ;
	wire			PF_FOUT_MASK	 ;
	wire	[09:00]	PF_M			 ;
//address: 0x03
	wire	[15:00]	PF_RSEL			 ;
//address: 0x04
	wire	[15:00]	PF_K			 ;
//address: 0x05
	wire	[05:00]	PF_P			 ;
	wire	[02:00]	PF_S			 ;
	wire			PF_SSCG_EN		 ;
	wire	[05:00]	PF_MRR			 ;
//address: 0x06
	wire	[01:00]	PF_SEL_PF		 ;
	wire	[07:00]	PF_MFR			 ;
//address: 0x07
	wire	[09:00]	PL1_AFC			 ;
	wire			PL1_BGR_BYPASS_EN;
	wire			PL1_BGR_EN		 ;
	wire	[01:00]	PL1_BGR_I_CON	 ;
	wire	[01:00]	PL1_BGR_TC_CON	 ;
//address: 0x08
	wire			PL1_LDO_EN		 ;
	wire			PL1_RESETB_VCO	 ;
	wire			PL1_VCO_EN		 ;
	wire	[02:00]	PL1_VC_CON		 ;
	wire	[03:00]	PL1_VSEL_LDO	 ;
//address: 0x09
	wire	[09:00]	PL2_AFC			 ;
	wire			PL2_BGR_BYPASS_EN;
	wire			PL2_BGR_EN		 ;
	wire	[01:00]	PL2_BGR_I_CON	 ;
	wire	[01:00]	PL2_BGR_TC_CON	 ;
//address: 0x0A
	wire			PL2_LDO_EN		 ;
	wire			PL2_RESETB_VCO	 ;
	wire			PL2_VCO_EN		 ;
	wire	[02:00]	PL2_VC_CON		 ;
	wire	[03:00]	PL2_VSEL_LDO	 ;
//address: 0x0B
	wire	[01:00]	TS1_BGR_TC_CON_TS;
	wire	[03:00]	TS1_BJT_SEL_TS	 ;
	wire	[01:00]	TS1_DMUX_ADDR_TS ;
	wire			TS1_EN_TS		 ;
	wire			TS1_HTOL_SEL	 ;
	wire	[03:00]	TS1_OFFSET_CON_TS;
//address: 0x0C
	wire	[06:00]	TS1_SLOPE_CON_TS ;
	wire			TS1_SOC_TS		 ;
	wire			TS1_TEST_MODE_TS ;
	wire	[01:00]	TS1_AMUX_ADDR_TS ;
	wire	[01:00]	TS1_AVG_MODE_TS	 ;
	wire	[01:00]	TS1_BGR_I_CON_TS ;
//address: 0x0D
	wire	[01:00]	TS2_BGR_TC_CON_TS;
	wire	[03:00]	TS2_BJT_SEL_TS	 ;
	wire	[01:00]	TS2_DMUX_ADDR_TS ;
	wire			TS2_EN_TS		 ;
	wire			TS2_HTOL_SEL	 ;
	wire	[03:00]	TS2_OFFSET_CON_TS;
//address: 0x0E
	wire	[06:00]	TS2_SLOPE_CON_TS ;
	wire			TS2_SOC_TS		 ;
	wire			TS2_TEST_MODE_TS ;
	wire	[01:00]	TS2_AMUX_ADDR_TS ;
	wire	[01:00]	TS2_AVG_MODE_TS	 ;
	wire	[01:00]	TS2_BGR_I_CON_TS ;
//address: 0x0F
	wire	[15:00]	TS2_RESERVED	 ;
//address: 0x10
	wire	[15:00]	POR_RESERVED	 ;
//address: 0x11
	reg		[08:00]	TS1_OUT_9BIT_TS	 ;
//address: 0x12
	reg		[08:00]	TS2_OUT_9BIT_TS  ;

DIG_TOP u_DIG_TOP (
//SPI Interface Port
/*input wire		*/	.RSTB			(RSTB			),
/*input wire		*/	.CSN			(CSN			),
/*input wire		*/	.SCLK			(SCLK			),
/*input wire		*/	.MOSI			(MOSI			),
/*output wire		*/	.MISO			(MISO			),
/*//Analog Interface Port*/
/*//address: 0x00		*/
/*	output wire	[15:00]	*/	.PF_CTRL			(PF_CTRL			)	,
/*//address: 0x01	    */
/*	output wire	[01:00]	*/	.PF_LOCK_CON_DLY	(PF_LOCK_CON_DLY	)	,
/*	output wire	[01:00]	*/	.PF_LOCK_CON_IN		(PF_LOCK_CON_IN		)	,
/*	output wire	[01:00]	*/	.PF_LOCK_CON_OUT	(PF_LOCK_CON_OUT	)	,
/*	output wire			*/	.PF_LOCK_EN			(PF_LOCK_EN			)	,
/*	output wire			*/	.PF_RESETB			(PF_RESETB			)	,
/*	output wire			*/	.PF_BYPASS			(PF_BYPASS			)	,
/*	output wire			*/	.PF_FSEL			(PF_FSEL			)	,
/*	output wire			*/	.PF_FEED_EN			(PF_FEED_EN			)	,
/*	output wire			*/	.PF_AFC_ENB			(PF_AFC_ENB			)	,
/*	output wire	[01:00]	*/	.PF_ICP				(PF_ICP				)	,
/*//address: 0x02	    */	
/*	output wire	[04:00]	*/	.PF_EXTAFC			(PF_EXTAFC			)	,
/*	output wire			*/	.PF_FOUT_MASK		(PF_FOUT_MASK		)	,
/*	output wire	[09:00]	*/	.PF_M				(PF_M				)	,
/*//address: 0x03       */	
/*	output wire	[15:00]	*/	.PF_RSEL			(PF_RSEL			)	,
/*//address: 0x04       */	
/*	output wire	[15:00]	*/	.PF_K				(PF_K				)	,
/*//address: 0x05		*/
/*	output wire	[05:00]	*/	.PF_P				(PF_P				)	,
/*	output wire	[02:00]	*/	.PF_S				(PF_S				)	,
/*	output wire			*/	.PF_SSCG_EN			(PF_SSCG_EN			)	,
/*	output wire	[05:00]	*/	.PF_MRR				(PF_MRR				)	,
/*//address: 0x06		*/	
/*	output wire	[01:00]	*/	.PF_SEL_PF			(PF_SEL_PF			)	,
/*	output wire	[07:00]	*/	.PF_MFR				(PF_MFR				)	,
/*//address: 0x07       */	
/*	output wire	[09:00]	*/	.PL1_AFC			(PL1_AFC			)	,
/*	output wire			*/	.PL1_BGR_BYPASS_EN	(PL1_BGR_BYPASS_EN	)	,
/*	output wire			*/	.PL1_BGR_EN			(PL1_BGR_EN			)	,
/*	output wire	[01:00]	*/	.PL1_BGR_I_CON		(PL1_BGR_I_CON		)	,
/*	output wire	[01:00]	*/	.PL1_BGR_TC_CON		(PL1_BGR_TC_CON		)	,
/*//address: 0x08       */	
/*	output wire			*/	.PL1_LDO_EN			(PL1_LDO_EN			)	,
/*	output wire			*/	.PL1_RESETB_VCO		(PL1_RESETB_VCO		)	,
/*	output wire			*/	.PL1_VCO_EN			(PL1_VCO_EN			)	,
/*	output wire	[02:00]	*/	.PL1_VC_CON			(PL1_VC_CON			)	,
/*	output wire	[03:00]	*/	.PL1_VSEL_LDO		(PL1_VSEL_LDO		)	,
/*//address: 0x09		*/	
/*	output wire	[09:00]	*/	.PL2_AFC			(PL2_AFC			)	,
/*	output wire			*/	.PL2_BGR_BYPASS_EN	(PL2_BGR_BYPASS_EN	)	,
/*	output wire			*/	.PL2_BGR_EN			(PL2_BGR_EN			)	,
/*	output wire	[01:00]	*/	.PL2_BGR_I_CON		(PL2_BGR_I_CON		)	,
/*	output wire	[01:00]	*/	.PL2_BGR_TC_CON		(PL2_BGR_TC_CON		)	,
/*//address: 0x0A       */	
/*	output wire			*/	.PL2_LDO_EN			(PL2_LDO_EN			)	,
/*	output wire			*/	.PL2_RESETB_VCO		(PL2_RESETB_VCO		)	,
/*	output wire			*/	.PL2_VCO_EN			(PL2_VCO_EN			)	,
/*	output wire	[02:00]	*/	.PL2_VC_CON			(PL2_VC_CON			)	,
/*	output wire	[03:00]	*/	.PL2_VSEL_LDO		(PL2_VSEL_LDO		)	,
/*//address: 0x0B       */	
/*	output wire	[01:00]	*/	.TS1_BGR_TC_CON_TS	(TS1_BGR_TC_CON_TS	)	,
/*	output wire	[03:00]	*/	.TS1_BJT_SEL_TS		(TS1_BJT_SEL_TS		)	,
/*	output wire	[01:00]	*/	.TS1_DMUX_ADDR_TS	(TS1_DMUX_ADDR_TS	)	,
/*	output wire			*/	.TS1_EN_TS			(TS1_EN_TS			)	,
/*	output wire			*/	.TS1_HTOL_SEL		(TS1_HTOL_SEL		)	,
/*	output wire	[03:00]	*/	.TS1_OFFSET_CON_TS	(TS1_OFFSET_CON_TS	)	,
/*//address: 0x0C       */	
/*	output wire	[06:00]	*/	.TS1_SLOPE_CON_TS	(TS1_SLOPE_CON_TS	)	,
/*	output wire			*/	.TS1_SOC_TS			(TS1_SOC_TS			)	,
/*	output wire			*/	.TS1_TEST_MODE_TS	(TS1_TEST_MODE_TS	)	,
/*	output wire	[01:00]	*/	.TS1_AMUX_ADDR_TS	(TS1_AMUX_ADDR_TS	)	,
/*	output wire	[01:00]	*/	.TS1_AVG_MODE_TS	(TS1_AVG_MODE_TS	)	,
/*	output wire	[01:00]	*/	.TS1_BGR_I_CON_TS	(TS1_BGR_I_CON_TS	)	,
/*//address: 0x0D       */                                          
/*	output wire	[01:00]	*/	.TS2_BGR_TC_CON_TS	(TS2_BGR_TC_CON_TS	)	,
/*	output wire	[03:00]	*/	.TS2_BJT_SEL_TS		(TS2_BJT_SEL_TS		)	,
/*	output wire	[01:00]	*/	.TS2_DMUX_ADDR_TS	(TS2_DMUX_ADDR_TS	)	,
/*	output wire			*/	.TS2_EN_TS			(TS2_EN_TS			)	,
/*	output wire			*/	.TS2_HTOL_SEL		(TS2_HTOL_SEL		)	,
/*	output wire	[03:00]	*/	.TS2_OFFSET_CON_TS	(TS2_OFFSET_CON_TS	)	,
/*//address: 0x0E       */                                          
/*	output wire	[06:00]	*/	.TS2_SLOPE_CON_TS	(TS2_SLOPE_CON_TS	)	,
/*	output wire			*/	.TS2_SOC_TS			(TS2_SOC_TS			)	,
/*	output wire			*/	.TS2_TEST_MODE_TS	(TS2_TEST_MODE_TS	)	,
/*	output wire	[01:00]	*/	.TS2_AMUX_ADDR_TS	(TS2_AMUX_ADDR_TS	)	,
/*	output wire	[01:00]	*/	.TS2_AVG_MODE_TS	(TS2_AVG_MODE_TS	)	,
/*	output wire	[01:00]	*/	.TS2_BGR_I_CON_TS	(TS2_BGR_I_CON_TS	)	,
/*//address: 0x0F		*/
/*	output wire	[15:00]	*/	.TS2_RESERVED		(TS2_RESERVED		)	,
/*//address: 0x10       */
/*	output wire	[15:00]	*/	.POR_RESERVED		(POR_RESERVED		)	,
/*//address: 0x11       */
/*	input wire	[08:00]	*/	.TS1_OUT_9BIT_TS	(TS1_OUT_9BIT_TS	)	,
/*//address: 0x12       */
/*	input wire	[08:00]	*/	.TS2_OUT_9BIT_TS	(TS2_OUT_9BIT_TS	)	                        
);                      


	reg	[15:0]	spi_rdata;
	reg	[15:0]	data = 16'h0001;

	always #1000 CLK = ~CLK;

	reg	[4:0] sclk_cnt;

	always@(posedge SCLK or posedge CSN)
	begin
		if(CSN)
		begin
			sclk_cnt <= 5'h0;
		end
		else
		begin
			sclk_cnt <= sclk_cnt + 1;
		end
	end

	task spi_start;
	integer i;
	begin
		$display("SPI_START");
		for(i = 0; i < 3; i = i + 1) @(posedge CLK)
		begin
			CSN = 0;
		end
		for(i = 0; i < 7; i = i + 1) @(negedge CLK)
		begin
			SCLK = 0;
			MOSI = 0;
		end
	end
	endtask

	task spi_stop;
	integer i;
	begin
		$display("SPI_STOP");
		for(i = 0; i < 27; i = i + 1) @(negedge CLK)
		begin
			SCLK = 0;		
			MOSI = 0;		
		end
		for(i = 0; i < 250; i = i + 1) @(posedge CLK)
		begin
			CSN = 1;
		end
	end
	endtask

	task spi_bwrite;
	input	[7:0]	wdata;
	integer j;
	begin
		$display("SPI_WRITE : %02h", wdata);
		for(j = 0; j < 8; j = j + 1) @(negedge CLK) begin
			SCLK = 0;
			MOSI = wdata[7 - j];
			@(posedge CLK);
			SCLK = 1;
		end
	end
	endtask

	task spi_bread;
	output	[7:0] rdata;
	integer k;
	begin
		for(k = 0; k < 8; k = k + 1) @(negedge CLK) begin
			SCLK = 0;
			@(posedge CLK);
			SCLK = 1;
			rdata[7 - k] = MISO;
		end
		$display("SPI_BREAD : %02h", rdata);
	end
	endtask

	task read_op;
	input	[7:0]	rw_add;
	output	[7:0]	read_data1;
	output	[7:0]	read_data2;
	begin
		spi_start;
		spi_bwrite(rw_add);
		spi_bread(read_data1);
		spi_bread(read_data2);
		spi_stop;
	end
	endtask

	task write_op;
	input	[7:0]	wr_add;
	input	[7:0]	write_data1;
	input	[7:0]	write_data2;
	begin
		spi_start;
		spi_bwrite(wr_add);
		spi_bwrite(write_data1);
		spi_bwrite(write_data2);
		spi_stop;
	end
	endtask

	task bit_toggle;
	begin
		data = data + (data | (1<<1));
	end
	endtask
	
	reg [7:0] random_8bit;

	integer loop, i;
	reg	[6:0]	shift_addr;
	
	initial begin
	CSN = 1'b1;
	MOSI = 1'b0;
	SCLK = 1'b0;
	RSTB = 1'b1;
	CLK = 1'b0;

`ifdef VECTOR 
	task_start;
`endif

	#1_000_000_000	RSTB = 1'b0;
	#1_000_000 		RSTB = 1'b1;
	#1_000_000
	shift_addr = 7'd0;	
	$display("________________________________________");
	$display("========================================");
	$display("   SPI Register Default Values RTL SIM  ");
	$display("========================================");
	$display("------------------------------------------------------");	
	$display("###########<0x00~0x10> 16'h0000 READ / WRITE / READ ############");
	$display("------------------------------------------------------");	
	$display("------------------------------------------------------");	
	
	write_op({1'b1, 7'd0 }, 8'h00, 8'h00);
	write_op({1'b1, 7'd1 }, 8'hFC, 8'h00);
	write_op({1'b1, 7'd2 }, 8'h00, 8'hDC);
	write_op({1'b1, 7'd3 }, 8'h00, 8'h00);
	write_op({1'b1, 7'd4 }, 8'h00, 8'h00);
	write_op({1'b1, 7'd5 }, 8'h07, 8'h00);
	write_op({1'b1, 7'd6 }, 8'h80, 8'h00);
	write_op({1'b1, 7'd7 }, 8'h80, 8'h00);
	write_op({1'b1, 7'd8 }, 8'h12, 8'h00);
	write_op({1'b1, 7'd9 }, 8'h80, 8'h00);
	write_op({1'b1, 7'd10}, 8'h12, 8'h00);
	write_op({1'b1, 7'd11}, 8'h00, 8'h00);
	write_op({1'b1, 7'd12}, 8'h00, 8'h00);
	write_op({1'b1, 7'd13}, 8'h00, 8'h00);
	write_op({1'b1, 7'd14}, 8'h00, 8'h00);
	write_op({1'b1, 7'd15}, 8'h00, 8'h00);
	write_op({1'b1, 7'd16}, 8'h00, 8'h00);
	write_op({1'b1, 7'd17}, 8'h00, 8'h00);
	write_op({1'b1, 7'd18}, 8'h00, 8'h00);
	write_op({1'b1, 7'd1 }, 8'hFD, 8'h00);

	read_op({1'b0, 7'd0 }, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd1 }, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd2 }, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd3 }, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd4 }, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd5 }, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd6 }, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd7 }, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd8 }, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd9 }, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd10}, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd11}, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd12}, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd13}, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd14}, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd15}, spi_rdata[15:8], spi_rdata[7:0]);		
	read_op({1'b0, 7'd16}, spi_rdata[15:8], spi_rdata[7:0]);	

`ifdef VECTOR 
task_stop;
`endif

	//$display("------------------------------------------------------");	
	//$display("------------------------------------------------------");	
	//shift_addr = 7'd0;	
	//for(i = 0; i < 17; i=i+1) begin
	//	$display("###########WREG%2h WRITE############", i);
	//	read_op({1'b0,shift_addr}, spi_rdata[15:8], spi_rdata[7:0]);		
	//	write_op({1'b1,shift_addr},8'hAA, 8'hAA);	
	//	read_op({1'b0,shift_addr}, spi_rdata[15:8], spi_rdata[7:0]);
	//	shift_addr = shift_addr + 1;
	//end		
	//$display("------------------------------------------------------");	
	//$display("###########<0x00~0x10> 16'h5555 READ / WRITE / READ ############");
	//$display("------------------------------------------------------");	
	//$display("------------------------------------------------------");	
	//shift_addr = 7'd0;	
	//for(i = 0; i < 17; i=i+1) begin
	//	$display("###########WREG%2h WRITE############", i);
	//	read_op({1'b0,shift_addr}, spi_rdata[15:8], spi_rdata[7:0]);		
	//	write_op({1'b1,shift_addr},8'h55, 8'h55);	
	//	read_op({1'b0,shift_addr}, spi_rdata[15:8], spi_rdata[7:0]);
	//	shift_addr = shift_addr + 1;
	//end			
	//$display("------------------------------------------------------");	
	//$display("###########<0x00~0x10> 16'hFFFF READ / WRITE / READ ############");
	//$display("------------------------------------------------------");	
	//$display("------------------------------------------------------");	
	//shift_addr = 7'd0;	
	//for(i = 0; i < 17; i=i+1) begin
	//	$display("###########WREG%2h WRITE############", i);
	//	read_op({1'b0,shift_addr}, spi_rdata[15:8], spi_rdata[7:0]);		
	//	write_op({1'b1,shift_addr},8'h00, 8'h00);	
	//	read_op({1'b0,shift_addr}, spi_rdata[15:8], spi_rdata[7:0]);
	//	shift_addr = shift_addr + 1;
	//end	
	
	$finish;

	end

endmodule
