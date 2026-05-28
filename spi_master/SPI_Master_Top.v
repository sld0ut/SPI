////////////////////////////////////////////////////////
//
//  Module: SPI_Master_Top
//  Project: MCUP
//  Description: 
// 
//  Change history: 
//
////////////////////////////////////////////////////////
`timescale 1ns/10ps

module SPI_Master_Top #(
	parameter	REG_CONFIG	= 15,
	parameter	REG_DEPTH	= 3
) (
	input  wire			SE				,
	input  wire			TE				,
	input  wire			CKE_IP			,
	input  wire			RESET_IP		,
	input  wire			HCLK_CG_EN		,
	// AHB Common
	input  wire			HCLK			,
	input  wire			FCLK			,
	input  wire			HRESETN			,
	// AHB Slave
	input wire			SLV_HSEL		,
	input wire [31:0]	SLV_HADDR		,
	input wire [ 1:0]	SLV_HTRANS		,
	input wire [ 2:0]	SLV_HSIZE		,
	input wire [ 3:0]	SLV_HPROT		,
	input wire [ 2:0]	SLV_HBURST		,
	input wire			SLV_HMLOCK		,
	input wire			SLV_HWRITE		,
	input wire [31:0]	SLV_HWDATA		,
	input wire		  	SLV_HREADYIN	,
	output wire [1:0]	SLV_HRESP		,
	output wire [31:0] 	SLV_HRDATA		,
	output wire        	SLV_HREADYOUT	,
	output  wire		O_INTR			,
	// SPI Master Signals
	input wire			I_SPI_MISO_IN	,
	output wire			O_SPI_MISO_OUT	,
	output wire			O_SPI_MISO_OEN	,
	//
	input wire			I_SPI_MOSI_IN	,
	output wire			O_SPI_MOSI_OUT	,
	output wire			O_SPI_MOSI_OEN	,
	//
	output wire			O_SPI_CLK		,
	output wire			O_SPI_SSN	
);

`include "ahb_def.inc"

//----------------------------------------------------------------------------
// Constraints
//----------------------------------------------------------------------------
wire	w_SPI_MISO_IN_P	;
wire	w_SPI_MOSI_IN_P	;
wire	w_SPI_MISO_OUT	;
wire	w_SPI_MISO_OEN	;
wire	w_SPI_MOSI_OUT	;
wire	w_SPI_MOSI_OEN	;
wire	w_SPI_CLK_P		;
wire	w_SPI_SSN_P		;
CLK_BUF u_SPI_MISO_IN	(.A(I_SPI_MISO_IN), 	.Y(w_SPI_MISO_IN_P));
CLK_BUF u_SPI_MISO_OUT	(.A(w_SPI_MISO_OUT), 	.Y(O_SPI_MISO_OUT));
CLK_BUF u_SPI_MISO_OEN	(.A(w_SPI_MISO_OEN),	.Y(O_SPI_MISO_OEN));
//
CLK_BUF u_SPI_MOSI_IN	(.A(I_SPI_MOSI_IN), 	.Y(w_SPI_MOSI_IN_P));
CLK_BUF u_SPI_MOSI_OUT	(.A(w_SPI_MOSI_OUT), 	.Y(O_SPI_MOSI_OUT));
CLK_BUF u_SPI_MOSI_OEN	(.A(w_SPI_MOSI_OEN),	.Y(O_SPI_MOSI_OEN));
//
CLK_BUF	u_SPI_CLK		(.A(w_SPI_CLK_P),		.Y(O_SPI_CLK));
CLK_BUF	u_SPI_SSN		(.A(w_SPI_SSN_P),		.Y(O_SPI_SSN));

//----------------------------------------------------------------------------
// Rest & Clock Control
//----------------------------------------------------------------------------
wire           	sig_rstb;
wire         	hclkg, FLCKG;
assign sig_rstb = HRESETN & (TE|RESET_IP);

CLK_GATE I_CG_HCLK (.EN(CKE_IP), .TE(SE), .ICLK(HCLK), .OCLK(hclkg));
CLK_GATE I_CG_FCLK (.EN(CKE_IP), .TE(SE), .ICLK(FCLK), .OCLK(FCLKG));

//----------------------------------------------------------------------------
// AHB2AHB Bridge
//----------------------------------------------------------------------------
wire [4-1:0]	w_HMASTERM	= 'h0;
wire			w_HRESPS;
assign SLV_HRESP	= {1'b0,w_HRESPS};

wire [32-1:0]	S_HADDR		;
wire   [1:0] 	S_HTRANS	;
wire   [2:0] 	S_HSIZE		;
wire         	S_HWRITE	;
wire [4-1:0]	S_HMASTER	;
wire   [3:0] 	S_HPROT		;
wire         	S_HMASTLOCK	;
wire   [2:0] 	S_HBURST	;
wire [32-1:0]	S_HWDATA	;
wire			S_HSEL		= S_HTRANS[1];

wire         	S_HREADYOUT	;
wire [1:0]		S_HRESP		;
wire [32-1:0]	S_HRDATA	;

wire			S_HREADYIN	= S_HREADYOUT;

cmsdk_ahb_to_ahb_sync u_cmsdk_ahb_to_ahb_sync (
/*input  wire		  */	.HCLK		(hclkg			),
/*input  wire		  */	.HRESETn	(sig_rstb		),

// AHB connection to master
/*input  wire         */	.HSELS		(SLV_HSEL		),
/*input  wire [AW-1:0]*/	.HADDRS		(SLV_HADDR		),
/*input  wire    [1:0]*/	.HTRANSS	(SLV_HTRANS		),
/*input  wire    [2:0]*/	.HSIZES		(SLV_HSIZE		),
/*input  wire         */	.HWRITES	(SLV_HWRITE		),
/*input  wire         */	.HREADYS	(SLV_HREADYIN	),
/*input  wire    [3:0]*/	.HPROTS		(SLV_HPROT		),
/*input  wire [MW-1:0]*/	.HMASTERS	(w_HMASTERM		),
/*input  wire         */	.HMASTLOCKS	(SLV_HMLOCK		),
/*input  wire [DW-1:0]*/	.HWDATAS	(SLV_HWDATA		),
/*input  wire    [2:0]*/	.HBURSTS	(SLV_HBURST		),

/*output wire         */	.HREADYOUTS	(SLV_HREADYOUT	),
/*output wire         */	.HRESPS		(w_HRESPS		),
/*output wire [DW-1:0]*/	.HRDATAS	(SLV_HRDATA		),

// AHB connection to slave
/*output wire [AW-1:0]*/	.HADDRM		(S_HADDR		),
/*output wire   [1:0] */	.HTRANSM	(S_HTRANS		),
/*output wire   [2:0] */	.HSIZEM		(S_HSIZE		),
/*output wire         */	.HWRITEM	(S_HWRITE		),
/*output wire   [3:0] */	.HPROTM		(S_HPROT		),
/*output wire [MW-1:0]*/	.HMASTERM	(S_HMASTER		),
/*output wire         */	.HMASTLOCKM	(S_HMASTLOCK	),
/*output wire [DW-1:0]*/	.HWDATAM	(S_HWDATA		),
/*output wire   [2:0] */	.HBURSTM	(S_HBURST		),

/*input  wire         */	.HREADYM	(S_HREADYOUT	),
/*input  wire         */	.HRESPM		(S_HRESP[0]		),
/*input  wire [DW-1:0]*/	.HRDATAM	(S_HRDATA		)
);

//----------------------------------------------------------------------------
// AHB Slave
//----------------------------------------------------------------------------
wire	w_hclk_cg;
hclk_cg u_HCLK_CG (
/*input wire	*/	.SE				(SE			),
/*input wire	*/	.HCLK			(hclkg		),
/*input wire	*/	.HRESET_N		(sig_rstb	),
/*input wire	*/	.HSEL			(S_HSEL		),
/*input wire	*/	.HCLK_CG_EN		(HCLK_CG_EN	),
/*output wire	*/	.HCLK_CG		(w_hclk_cg	)
);

wire hsel_cfg	= (S_HSEL & S_HADDR[REG_CONFIG]==1'b0) ? 1'b1 : 1'b0;
wire hsel_mem	= (S_HSEL & S_HADDR[REG_CONFIG]==1'b1) ? 1'b1 : 1'b0;

//----------------------------------------------------------------------------
// 	Signals
//----------------------------------------------------------------------------
wire [3:0]		w_Bitlen	;

reg				r_TX_DV		;
wire			w_TX_Ready	;

wire [4:0]		w_RX_Count	;
wire			w_RX_DV		;
wire [15:0]		w_RX_Byte	;

reg				r_SPI_Busy	;

parameter	FIFO_DEPTH	= 32;
parameter	FIFO_WIDTH	= 8;
parameter	MXB			= 32;

wire		w_core_fflsuh	;
wire		w_core_fwrite	;
wire		w_core_fread	;
wire [7:0]	w_core_fdin		;
wire [7:0]	w_core_fdout	;
wire		w_core_fvalid	;
wire		w_core_fempty	;
wire		w_core_ffull	;
wire [4:0]	w_core_fwptr	;
wire [4:0]	w_core_frptr	;

wire [31:0]	w_haddr_mem		;
wire [31:0]	w_haddr_mem_	;
wire [31:0]	w_hwdata_mem	;

reg						r_read_done		;
reg						r_hready_mem	;
reg [31:0]				r_hwdata_mem	;
reg						r_read_en		;
reg						r_rd_phase		;
reg [2:0]				r_cnt_max		;
reg						r_tx_run		;
reg						r_rx_run		;
reg						r_fwrite		;
reg						r_dfwrite		;
reg						r_dfread		;
reg [FIFO_WIDTH-1:0]	r_dfdin			;
reg						r_fread			;
wire					w_core_done		= ~r_SPI_Busy;
wire					w_fifo_flush	=  w_core_fflsuh	;
wire					w_fifo_read		= (r_dfread  | w_core_fread	| r_fread	);	
wire					w_fifo_write	= (r_dfwrite | w_core_fwrite| r_fwrite	);
wire [FIFO_WIDTH-1:0]	w_data_in		= (r_dfwrite) ? r_dfdin	:
										  (r_fwrite) ? w_RX_Byte[7:0] : w_core_fdin	;

//wire [4:0]			w_af_threshold	= (FIFO_DEPTH/2);
wire [1:0]				w_af_threshold_	;
reg [4:0]				w_af_threshold	;	//1,8,16,31
always @(*) begin
	w_af_threshold <= {w_af_threshold_,3'd0};
	if(w_af_threshold_==2'd0)		w_af_threshold <= 1;
	else if(w_af_threshold_==2'd3)	w_af_threshold <= (FIFO_DEPTH-1);
end

wire [4:0]				w_fifo_wptr		;
wire [4:0]				w_fifo_rptr		;
wire [FIFO_WIDTH-1:0]	w_data_out		;
wire					w_ram_valid		;
wire					w_fifo_full_req	;
wire					w_fifo_full_raw	;
wire					w_fifo_inpempty	;
wire					w_fifo_outempty	;
wire					w_fifo_full_ack	;

assign w_core_fdout		= w_data_out;

//----------------------------------------------------------------------------
// 	AHB Slave
//----------------------------------------------------------------------------
reg   [31:0] haddr_reg;
reg          hvalid_reg;
reg          hwrite_reg;
reg    [1:0] hsize_reg;

reg   [31:0] haddr_mem_reg;
reg          hvalid_mem_reg;
reg          hwrite_mem_reg;
reg    [1:0] hsize_mem_reg;

reg   [31:0] hrdata_reg;

wire         byte_00_we;
wire         byte_01_we;
wire         byte_10_we;
wire         byte_11_we;

assign byte_00_we = (haddr_reg[1:0]==2'b00);
assign byte_01_we = (((hsize_reg[1:0]==2'b00)&&(haddr_reg[1:0]==2'b01)) ||
					((hsize_reg[1:0]==2'b01)&&(haddr_reg[1:0]==2'b00)) ||
					((hsize_reg[1]==1'b1)&&(haddr_reg[1:0]==2'b00)));
assign byte_10_we = (((hsize_reg[1:0]==2'b00)&&(haddr_reg[1:0]==2'b10)) ||
					((hsize_reg[1:0]==2'b01)&&(haddr_reg[1:0]==2'b10)) ||
					((hsize_reg[1]==1'b1)&&(haddr_reg[1:0]==2'b00)));
assign byte_11_we = (((hsize_reg[1:0]==2'b00)&&(haddr_reg[1:0]==2'b11)) ||
					((hsize_reg[1:0]==2'b01)&&(haddr_reg[1:0]==2'b10)) ||
					((hsize_reg[1]==1'b1)&&(haddr_reg[1:0]==2'b00)));

always @(posedge w_hclk_cg or negedge sig_rstb)
begin
	if (~sig_rstb) begin
		haddr_reg <= #1 20'b0;
		hvalid_reg <= #1 1'b0;
		hwrite_reg <= #1 1'b0;
		hsize_reg <= #1 2'b10; //word

		haddr_mem_reg <= #1 'h0;
		hvalid_mem_reg <= #1 1'b0;
		hsize_mem_reg <= #1 2'b10;
		hwrite_mem_reg <= #1 1'b0;
	end
	else begin
		if (S_HREADYIN & S_HTRANS[1] & hsel_cfg) begin
			haddr_reg <= #1 S_HADDR[19:0];
		end
		hvalid_reg <= #1 S_HREADYIN & S_HTRANS[1] & hsel_cfg;
		hwrite_reg <= #1 S_HWRITE;
		hsize_reg <= #1 S_HSIZE[1:0];

		if (S_HREADYIN & S_HTRANS[1] & hsel_mem) begin
			haddr_mem_reg <= #1 S_HADDR[19:0];
			hsize_mem_reg <= #1 S_HSIZE[1:0];
			hwrite_mem_reg <= #1 S_HWRITE;
		end
		hvalid_mem_reg <= #1 S_HREADYIN & S_HTRANS[1] & hsel_mem;
	end
end

integer	i;
reg [31:0]	c_reg	[0:REG_DEPTH-1];

always @(posedge w_hclk_cg or negedge sig_rstb) 
	if (~sig_rstb) begin
		for(i=0;i<REG_DEPTH;i=i+1) begin
			c_reg[i] <= 'd0;
		end
		c_reg[0][01]	<= 1'b1;	//MISO_OEN
		c_reg[0][07:04] <= 3'd7;	//default Bitlen 7
		c_reg[1][03]	<= 1'b1;	//w_spi_ssn_static
		c_reg[1][19:18]	<= 2'd2;	//w_af_threshold=16
	end else begin
		if (hvalid_reg & hwrite_reg) begin
			if(byte_00_we) begin c_reg[haddr_reg[9:2]][07:00] <= S_HWDATA[07:00]; end
			if(byte_01_we) begin c_reg[haddr_reg[9:2]][15:08] <= S_HWDATA[15:08]; end
			if(byte_10_we) begin c_reg[haddr_reg[9:2]][23:16] <= S_HWDATA[23:16]; end
			if(byte_11_we) begin c_reg[haddr_reg[9:2]][31:24] <= S_HWDATA[31:24]; end
		end //hwrite_valid
	end //clock edge

parameter	INTR_NUM	= 3;

wire [INTR_NUM-1:0]	w_intr_src	= {w_core_done,w_core_fempty,w_core_ffull};
wire [INTR_NUM-1:0]	w_intr_r	;
reg [INTR_NUM-1:0]	r_intr_req	;

always @(*)
begin
	hrdata_reg <= 32'b0;
	if (hvalid_reg & ~hwrite_reg) begin
		if(haddr_reg[9:2]>=REG_DEPTH) begin
			if(haddr_reg[9:2]==(REG_DEPTH+0)) begin
				hrdata_reg[04:00]	<= w_fifo_wptr;
				hrdata_reg[05]		<= w_core_fvalid;
				hrdata_reg[06]		<= w_core_ffull;
				hrdata_reg[07]		<= w_core_fempty;
				hrdata_reg[12:08]	<= w_fifo_rptr;
				hrdata_reg[13]		<= w_TX_Ready;
				hrdata_reg[14]		<= r_SPI_Busy;
				hrdata_reg[15]		<= w_RX_DV;
				hrdata_reg[20:16]	<= w_RX_Count;
				hrdata_reg[21]		<= w_core_done;
				//hrdata_reg[23:22]	<= ;
				//hrdata_reg[31:24]	<= ; //FIFO
				hrdata_reg[31:24]	<= w_core_fdout;
			end else if(haddr_reg[9:2]==(REG_DEPTH+1)) begin
				hrdata_reg[02:00]	<= r_intr_req;
				hrdata_reg[03]		<= r_rx_run;
				hrdata_reg[04]		<= r_tx_run;
				hrdata_reg[07:05]	<= 'h0;
				hrdata_reg[15:08]	<= w_RX_Byte[15:08];
				hrdata_reg[31:16]	<= 'h0;
			end
		end else begin
				hrdata_reg <= c_reg[haddr_reg[9:2]];
		end
	end
end

reg			r_hsel_mem_d;
reg [31:0]	r_hrdata_mem;
always @(posedge hclkg or negedge sig_rstb)
	if(!sig_rstb) begin
		r_hsel_mem_d	<= `Td 0;
	end else begin
		if(hsel_mem) begin
			r_hsel_mem_d	<= `Td 1;
		end else if(r_hsel_mem_d&&r_hready_mem) begin
			r_hsel_mem_d	<= `Td 0;
		end
	end

wire		hvalid_rd_p;
wire		w_core_fwrite_p;
reg			r_hready_fifo;
always @(posedge hclkg or negedge sig_rstb)
	if(!sig_rstb) begin
		r_hready_fifo	<= `Td 1;
	end else begin
		if(w_core_fwrite_p&&(w_ram_valid==1'b0)) begin
			r_hready_fifo <= `Td 0;
		end else if((r_hready_fifo==1'b0)&&(w_ram_valid==1'b1)) begin
			r_hready_fifo <= `Td 1;
		end
	end

assign S_HRESP		= 2'd0;
assign S_HRDATA		= (r_hsel_mem_d) ? r_hrdata_mem : hrdata_reg;
assign S_HREADYOUT	= 1'b1&r_hready_mem&r_hready_fifo;

wire [7:0]		w_cmd;

wire			w_MISO_OUT					= c_reg[0][00];
wire			w_MISO_OEN					= c_reg[0][01];
assign			w_cmd[1:0]					= c_reg[0][03:02];
assign			w_Bitlen					= c_reg[0][07:04]; 
wire [$clog2(MXB)-1:0]	w_Max_Count			= c_reg[0][08+$clog2(MXB)-1:08];
//											= c_reg[0][15:13];
wire [15:0]				w_CS_INACTIVE_CLKS	= c_reg[0][31:16];

assign w_core_fflsuh						= c_reg[1][00];
wire [1:0]		w_spi_ssn_sel				= c_reg[1][02:01];
wire			 w_spi_ssn_static			= c_reg[1][03];
wire [3:0]		w_core_adrb					= c_reg[1][07:04];
wire [2:0]		w_core_inte					= c_reg[1][10:08];
wire [2:0]		w_core_intc					= c_reg[1][13:11];
wire [1:0]		w_SPI_MODE					= (TE) ? 'h0 : c_reg[1][15:14];
wire 			w_MOSI_MASK					= c_reg[1][16];
wire			w_wire3_mode				= c_reg[1][17];
assign			w_af_threshold_				= c_reg[1][19:18]; 	//1,8,16,31
wire [3:0]		w_CLKS_PER_HALF_BIT			= c_reg[1][23:20];
//											= c_reg[1][31:24];	//FIFO

wire [23:0]		w_ext_addr					= c_reg[2][23:00];
wire [6:0]		w_ssi_ssn_dly				= c_reg[2][30:24];
//											= c_reg[2][31];
assign w_cmd[7:2]	= 'h0;

//----------------------------------------------------------------------------
// 	AHB Master
//----------------------------------------------------------------------------
wire hvalid_mem			= S_HREADYIN & S_HTRANS[1] & hsel_mem;

//----------------------------------------------------------------------------
// 	FIFO
//----------------------------------------------------------------------------
assign hvalid_p			= S_HREADYIN & S_HTRANS[1] & hsel_cfg;
assign w_core_fwrite_p	= (hvalid_p& S_HWRITE&(S_HADDR[9:2]=='h1)&S_HADDR[1:0]==2'd3);		//addr_phase

wire hvalid_rd_a		= (haddr_reg[1:0]==2'd3) ? 1'b1 : 1'b0;
assign w_core_fwrite	= (hvalid_reg& hwrite_reg&(haddr_reg[9:2]=='h1)&byte_11_we);		//data_phase
assign w_core_fread		= (hvalid_reg&~hwrite_reg&(haddr_reg[9:2]==REG_DEPTH)&hvalid_rd_a);	//addr_phase
assign w_core_fdin		= S_HWDATA[31:24];

async_fifo #(
	.N	(FIFO_WIDTH),
	.M	(FIFO_DEPTH)
) u_async_fifo (
/*input wire		*/	.test_se		(TE				),
/*input wire		*/	.rst_n			(sig_rstb		),
/*input wire		*/	.in_clk			(hclkg			),
/*input wire		*/	.out_clk		(hclkg			),
/*input wire		*/	.fifo_read		(w_fifo_read	),
/*input wire		*/	.fifo_write		(w_fifo_write	),
/*input wire		*/	.fifo_flush		(w_fifo_flush	),
/*input wire [N-1:0]*/	.data_in		(w_data_in		),
/*input wire [4:0]	*/	.af_threshold	(w_af_threshold	),

/*output wire [4:0]	*/	.fifo_wptr		(w_fifo_wptr	),
/*output wire [4:0]	*/	.fifo_rptr		(w_fifo_rptr	),
/*output wire [N-1:0]*/	.data_out		(w_data_out		),
/*output reg		*/	.ram_valid		(w_ram_valid	),
/*output reg		*/	.fifo_full_req	(w_fifo_full_req),
/*output reg		*/	.fifo_full_int	(w_fifo_full_raw),
/*output reg		*/	.fifo_inpempty	(w_fifo_inpempty),
/*output wire		*/	.fifo_outempty	(w_fifo_outempty),
/*input wire		*/	.fifo_full_ack	(w_fifo_full_ack)
);
assign w_fifo_full_ack	= w_core_intc[0];

//----------------------------------------------------------------------------
// 	SPI Master
//----------------------------------------------------------------------------
wire 			w_SPI_MOSI;
wire [1:0]		w_spi_rstb;
assign w_spi_rstb[0]	= (sig_rstb&r_SPI_Busy);
CLK_MUX u_TMUX (.A(w_spi_rstb[0]), .B(sig_rstb), .S(TE), .Y(w_spi_rstb[1]));

wire	w_SPI_SSN;

wire [15:0]	w_TX_Byte	= (w_Bitlen>7) ? {w_cmd,w_data_out} : w_data_out;

wire		w_mosi_swap		= (w_wire3_mode&&r_rd_phase) ? 1'b1 : 1'b0;
wire		w_SPI_MISO_IN	= (w_mosi_swap) ? w_SPI_MOSI_IN_P : w_SPI_MISO_IN_P;

SPI_Master_Core #(
	.MXB	(MXB)
) u_SPI_Master_Core (
/*input wire [1:0]	*/	.SPI_MODE			(w_SPI_MODE			),
/*input wire [15:0]	*/	.CS_INACTIVE_CLKS	(w_CS_INACTIVE_CLKS	),
/*input wire [3:0]	*/	.CLKS_PER_HALF_BIT	(w_CLKS_PER_HALF_BIT),
/*input wire [3:0]  */  .i_Bitlen			(w_Bitlen			),
// Control/Data Signals,
/*input wire		*/	.i_Rst_L			(w_spi_rstb[1]		),	// Reset
/*input wire		*/	.i_Clk				(hclkg				),	// Clock
   
// TX (MOSI) Signals
/*input wire [3:0]	*/	.i_TX_Count			(w_Max_Count		),	// # bytes per CS low
/*input wire [7:0]	*/	.i_TX_Byte			(w_TX_Byte			),	// Byte to transmit on MOSI
/*input wire      	*/	.i_TX_DV			(r_TX_DV			),	// Data Valid Pulse with i_TX_Byte
/*output wire		*/	.o_TX_Ready			(w_TX_Ready			),	// Transmit Ready for next byte
   
// RX (MISO) Signals
/*output reg [3:0]	*/	.o_RX_Count			(w_RX_Count			),	// Index RX byte
/*output wire		*/	.o_RX_DV			(w_RX_DV			),	// Data Valid pulse (1 clock cycle)
/*output wire [7:0]	*/	.o_RX_Byte			(w_RX_Byte			),	// Byte received on MISO

// SPI Interface
/*output wire		*/	.o_SPI_Clk			(w_SPI_CLK_P		),
/*input wire		*/	.i_SPI_MISO			(w_SPI_MISO_IN		),
/*output wire		*/	.o_SPI_MOSI			(w_SPI_MOSI			),
/*output wire		*/	.o_SPI_CS_n			(w_SPI_SSN			)
);

assign w_SPI_MISO_OUT	= w_MISO_OUT;
assign w_SPI_MISO_OEN	= w_MISO_OEN;

reg [63:0]	w_core_fempty_d;
always @(posedge hclkg or negedge sig_rstb)
	if(!sig_rstb) begin
		w_core_fempty_d	<= `Td 0;
	end else begin
		w_core_fempty_d	<= `Td {w_core_fempty_d[62:0],w_core_fempty};
	end

wire w_spi_ssn_dynamic	= (w_core_fempty&w_core_fempty_d[w_ssi_ssn_dly]);
assign w_SPI_SSN_P =(w_spi_ssn_sel==2'd0) ? w_SPI_SSN			:
					(w_spi_ssn_sel==2'd1) ? w_spi_ssn_dynamic	:
					(w_spi_ssn_sel==2'd2) ? w_spi_ssn_static		: 1'b1;
				   
reg [2:0]			s_state;
reg [15:0]			s_cnt;
parameter	ST_SPI_IDLE		= 3'b000;
parameter	ST_SPI_TX_0		= 3'b001;
parameter	ST_SPI_TX_1		= 3'b010;
parameter	ST_SPI_RX_0		= 3'b011;
parameter	ST_SPI_RX_1		= 3'b100;
parameter	ST_SPI_RX_2		= 3'b101;
parameter	ST_SPI_RX_3		= 3'b110;
parameter	ST_SPI_DONE		= 3'b111;

wire		w_fifo_valid	= ((w_core_fempty==1'b0)||(w_ram_valid==1'b1)) ? 1'b1 : 1'b0;

always @(posedge hclkg or negedge sig_rstb)
	if(!sig_rstb) begin
		r_SPI_Busy 	<= `Td 0;
		r_TX_DV 	<= `Td 0;
		r_read_en 	<= `Td 0;
		r_rd_phase 	<= `Td 0;
		r_fwrite	<= `Td 0;
		r_fread		<= `Td 0;
		s_cnt		<= `Td 0;
		s_state		<= `Td ST_SPI_IDLE;
	end else begin
		case(s_state)
			ST_SPI_IDLE : begin
				r_rd_phase	<= `Td 0;
				r_fread		<= `Td 0;
				s_cnt	<= `Td w_CS_INACTIVE_CLKS;
				if(r_tx_run) begin
					if(w_fifo_valid) begin			//wait for address or data write to fifo
							s_state		<= `Td ST_SPI_TX_0;
					end
				end else if(r_rx_run) begin
					if(w_core_adrb==0) begin				//no wait for fifo write
							s_state		<= `Td ST_SPI_RX_0;
					end else begin
						if(w_fifo_valid) begin		//wait for address write to fifo
							s_state		<= `Td ST_SPI_RX_0;
						end
					end
				end
			end
			////////////////////////////////////////////////////
			//SPI TX
			ST_SPI_TX_0 : begin
				if(s_cnt==0) begin
					r_SPI_Busy 	<= `Td 1;
					r_fread		<= `Td 0;
					if(w_TX_Ready) begin
						if(w_RX_Count==(w_core_adrb+r_cnt_max)) begin
							if(w_fifo_valid) begin
								r_fread		<= `Td 1;
								s_state		<= `Td ST_SPI_DONE;
							end else begin
								r_TX_DV		<= `Td 0;
								r_SPI_Busy 	<= `Td 0;
								s_state		<= `Td ST_SPI_IDLE;
							end
						end else begin
							r_TX_DV		<= `Td 1;
							r_SPI_Busy 	<= `Td 1;
							s_state		<= `Td ST_SPI_TX_1;
						end
					end
				end else begin
					s_cnt	<= `Td s_cnt - 1;
				end
			end
			ST_SPI_TX_1 : begin
				r_TX_DV		<= `Td 0;
				if(w_fifo_valid) begin
					if(w_RX_Count==((w_core_adrb+r_cnt_max)-1)) begin
						r_fread		<= `Td 0;
					end else begin
						r_fread		<= `Td 1;
					end
					r_SPI_Busy 	<= `Td 1;
					s_state		<= `Td ST_SPI_TX_0;
				end else begin
					s_state		<= `Td ST_SPI_TX_0;
				end
			end
			////////////////////////////////////////////////////
			//SPI RX
			ST_SPI_RX_0 : begin
				if(s_cnt==0) begin
					r_SPI_Busy 	<= `Td 1;
					if(w_TX_Ready) begin
						if(w_RX_Count==(w_core_adrb+r_cnt_max)) begin
							if(w_core_adrb==0) begin
									r_rd_phase	<= `Td 0;
							end else begin
								if(w_RX_Count>=w_core_adrb) begin
									r_rd_phase	<= `Td 0;
								end 
							end
							r_read_en	<= `Td 0;
							r_TX_DV		<= `Td 0;
							r_SPI_Busy 	<= `Td 0;
							s_state		<= `Td ST_SPI_RX_3;
						end else begin
							if(w_RX_Count>=w_core_adrb) begin
								r_rd_phase	<= `Td 1;
							end 
							r_TX_DV		<= `Td 1;
							r_SPI_Busy 	<= `Td 1;
							s_state		<= `Td ST_SPI_RX_1;
						end
					end
				end else begin
					s_cnt	<= `Td s_cnt - 1;
				end
			end
			ST_SPI_RX_1 : begin
				r_TX_DV		<= `Td 0;
				if(w_core_adrb==0) begin
					if(w_RX_DV) begin
						r_read_en	<= `Td 1;
						r_fwrite	<= `Td 1;
						r_SPI_Busy 	<= `Td 1;
						s_state		<= `Td ST_SPI_RX_2;
					end
				end else begin
					if(w_RX_DV&&(w_fifo_valid)) begin
						if(w_RX_Count>=w_core_adrb) begin	//skip address
							r_read_en	<= `Td 1;
							r_fwrite	<= `Td 1;
						end
						r_SPI_Busy 	<= `Td 1;
						s_state		<= `Td ST_SPI_RX_2;
					end
				end
			end
			ST_SPI_RX_2 : begin
				r_fwrite	<= `Td 0;
				s_state		<= `Td ST_SPI_RX_0;
			end
			ST_SPI_RX_3 : begin
				if(r_read_done) begin
					s_state	<= `Td ST_SPI_IDLE;
				end
			end
			////////////////////////////////////////////////////
			//SPI DONE
			ST_SPI_DONE : begin
				r_rd_phase	<= `Td 0;
				r_fread		<= `Td 0;
				r_TX_DV		<= `Td 0;
				r_SPI_Busy 	<= `Td 0;
				s_state		<= `Td ST_SPI_IDLE;
			end
			default : begin
				r_SPI_Busy 	<= `Td 0;
				r_TX_DV 	<= `Td 0;
				r_read_en 	<= `Td 0;
				r_rd_phase 	<= `Td 0;
				r_fwrite	<= `Td 0;
				r_fread		<= `Td 0;
				s_state		<= `Td ST_SPI_IDLE;
			end
		endcase
	end

reg [3:0]			c_state;
reg [$clog2(MXB):0]	cnt;
parameter	ST_IDLE		= 4'b0000;
parameter	ST_RW		= 4'b0001;
parameter	ST_ADR_0	= 4'b0010;
parameter	ST_ADR_1	= 4'b0011;
parameter	ST_XDAT_0	= 4'b0100;
parameter	ST_XDAT_1	= 4'b0101;
parameter	ST_RDAT_0	= 4'b1000;
parameter	ST_RDAT_1	= 4'b1001;
parameter	ST_RDAT_2	= 4'b1010;
parameter	ST_RDAT_3	= 4'b1011;
parameter	ST_WREADY	= 4'b1100;
parameter	ST_RREADY	= 4'b1101;
parameter	ST_DONE		= 4'b1111;

assign w_haddr_mem	=	(hsize_mem_reg==`SZ_BYTE) ? {w_ext_addr[32-REG_CONFIG-1+0:0],haddr_mem_reg[REG_CONFIG-1:0]}	:
						(hsize_mem_reg==`SZ_HALF) ? {w_ext_addr[32-REG_CONFIG-1+1:0],haddr_mem_reg[REG_CONFIG-1:1]} :
						(hsize_mem_reg==`SZ_WORD) ? {w_ext_addr[32-REG_CONFIG-1+2:0],haddr_mem_reg[REG_CONFIG-1:2]} : 'h0;
assign w_haddr_mem_	= ((c_state==ST_ADR_0)||(c_state==ST_ADR_1)) 	? ((w_haddr_mem)>>(cnt*8)) 	: 'h0;
assign w_hwdata_mem	= ((c_state==ST_XDAT_0)||(c_state==ST_XDAT_1))	? ((r_hwdata_mem)>>(cnt*8))	: 'h0;

reg		hvalid_mem_req;
reg		hvalid_mem_ack;
always @(posedge hclkg or negedge sig_rstb)
	if(!sig_rstb) begin
		r_hwdata_mem	<= `Td 0;
		hvalid_mem_req	<= `Td 0;
	end else begin
		if(hvalid_mem_req) begin
			if(cnt==r_cnt_max) begin
				r_hwdata_mem<= `Td S_HWDATA;
			end
		end else begin
			if(hvalid_mem_reg) begin
				r_hwdata_mem<= `Td S_HWDATA;
			end
		end

		if((hvalid_mem_req==1'b0)&&hvalid_mem_reg&&(S_HREADYIN==1'b0)) begin
			hvalid_mem_req	<= `Td 1;
		end else if(hvalid_mem_req&&hvalid_mem_ack) begin
			hvalid_mem_req	<= `Td 0;
		end
	end

always @(posedge hclkg or negedge sig_rstb)
	if(!sig_rstb) begin
		cnt 		<= `Td 0;
		r_cnt_max	<= `Td 0;
		r_tx_run	<= `Td 0;
		r_rx_run	<= `Td 0;
		r_dfwrite	<= `Td 0;
		r_dfread	<= `Td 0;
		r_dfdin		<= `Td 0;
		r_hrdata_mem<= `Td 0;
		r_hready_mem<= `Td 1;
		r_read_done	<= `Td 0;
		hvalid_mem_ack <= `Td 0;
		c_state 	<= `Td ST_IDLE;
	end else begin
		case(c_state)
			ST_IDLE : begin
				if(w_ram_valid==1'b0) begin
					r_tx_run	<= `Td 0;
					r_rx_run	<= `Td 0;
				end
				r_read_done	<= `Td 0;
				if(hvalid_mem) begin
					if((S_HWRITE==1'b1)&&(w_fifo_full_raw==1'b1)) begin
						r_hready_mem<= `Td 0;
						c_state 	<= `Td ST_WREADY;
					end else if((S_HWRITE==1'b0)&&(w_core_fempty==1'b1)) begin
						r_hready_mem<= `Td 0;
						c_state 	<= `Td ST_RW;
					end else begin
						r_hready_mem<= `Td 1;
						c_state 	<= `Td ST_RW;
					end
				end
			end
			/////////////////////////////////////////////////
			ST_WREADY : begin
				if((w_fifo_full_raw==1'b0)) begin
					r_hready_mem<= `Td 1;
					c_state 	<= `Td ST_RW;
				end
			end
			ST_RREADY : begin
				if((w_fifo_valid)) begin
					r_hready_mem<= `Td 1;
					c_state 	<= `Td ST_RW;
				end
			end
			/////////////////////////////////////////////////
			//RW
			ST_RW : begin
				if(hwrite_mem_reg) begin
					r_tx_run	<= `Td 1;
					r_rx_run	<= `Td 0;
				end else begin
					r_tx_run	<= `Td 0;
					r_rx_run	<= `Td 1;
				end
				r_cnt_max		<= `Td	(hsize_mem_reg==`SZ_BYTE) ? 3'd1 : 
						 				(hsize_mem_reg==`SZ_HALF) ? 3'd2 :
						 				(hsize_mem_reg==`SZ_WORD) ? 3'd4 : 'h0;
				c_state 		<= `Td ST_ADR_0;
			end
			/////////////////////////////////////////////////
			//Address
			ST_ADR_0 : begin
				if(cnt==w_core_adrb) begin
					if(r_tx_run) begin
						cnt			<= `Td 0;
						c_state 	<= `Td ST_XDAT_0;
					end else if(r_rx_run) begin
						r_hrdata_mem<= `Td 0;
						cnt			<= `Td 0;
						c_state 	<= `Td ST_RDAT_0;
					end
				end else begin
					if(w_fifo_full_raw==1'b0) begin
						r_dfwrite	<= `Td 1;
						r_dfdin		<= `Td w_haddr_mem_[7:0];
						c_state 	<= `Td ST_ADR_1;
					end
				end
			end
			ST_ADR_1 : begin
				r_dfwrite	<= `Td 0;
				cnt			<= `Td cnt + 1;
				c_state 	<= `Td ST_ADR_0;
			end
			/////////////////////////////////////////////////
			//TX DATA
			ST_XDAT_0 : begin
				if(cnt==r_cnt_max) begin
					cnt		 	<= `Td 0;
					r_dfwrite	<= `Td 0;
					r_dfdin		<= `Td 0;
					if(hvalid_mem_req) begin
						hvalid_mem_ack <= `Td 1;
						if(w_fifo_full_raw==1'b0) begin
							r_dfwrite	<= `Td 1;
							r_dfdin		<= `Td w_hwdata_mem[7:0];
							c_state 	<= `Td ST_XDAT_1;
						end else begin
							r_hready_mem<= `Td 0;
						end
					end else begin
						r_hready_mem<= `Td 1;
						c_state 	<= `Td ST_IDLE;
					end
				end else begin
					if(w_fifo_full_raw==1'b0) begin
						r_dfwrite	<= `Td 1;
						r_dfdin		<= `Td w_hwdata_mem[7:0];
						c_state 	<= `Td ST_XDAT_1;
					end else begin
						r_hready_mem<= `Td 0;
					end
				end
			end
			ST_XDAT_1 : begin
				hvalid_mem_ack <= `Td 0;
				r_dfwrite	<= `Td 0;
				cnt			<= `Td cnt + 1;
				c_state 	<= `Td ST_XDAT_0;
			end
			/////////////////////////////////////////////////
			//RX DATA
			ST_RDAT_0 : begin
				if(hvalid_mem_req) begin
					hvalid_mem_ack <= `Td 1;
				end
				if(cnt==r_cnt_max) begin
					if(w_fifo_valid) begin
						r_dfread	<= `Td 1;
					end else begin
						r_dfread	<= `Td 0;
					end
					r_hrdata_mem<= `Td	(hsize_mem_reg==`SZ_BYTE) ? {4{r_hrdata_mem[07:00]}} : 
										(hsize_mem_reg==`SZ_HALF) ? {2{r_hrdata_mem[15:00]}} : r_hrdata_mem;
					cnt		 	<= `Td 0;
					c_state 	<= `Td ST_RDAT_3;
				end else begin
					if(r_read_en&&w_TX_Ready) begin
						if(w_fifo_valid) begin
							r_dfread	<= `Td 1;
						end else begin
							r_dfread	<= `Td 0;
						end
						c_state 	<= `Td ST_RDAT_1;
					end
				end
			end
			ST_RDAT_1 : begin
				r_dfread	<= `Td 0;
				c_state 	<= `Td ST_RDAT_2;
			end
			ST_RDAT_2 : begin
				r_hrdata_mem<= `Td r_hrdata_mem + (w_data_out<<(cnt*8));
				cnt			<= `Td cnt + 1;
				c_state 	<= `Td ST_RDAT_0;
			end
			ST_RDAT_3 : begin
				hvalid_mem_ack	<= `Td 0;
				r_hready_mem	<= `Td 1;
				r_dfread		<= `Td 0;
				r_read_done		<= `Td 1;
				c_state 		<= `Td ST_IDLE;
			end
			/////////////////////////////////////////////////
			default : begin
				cnt 		<= `Td 0;
				r_cnt_max	<= `Td 0;
				r_tx_run	<= `Td 0;
				r_rx_run	<= `Td 0;
				r_dfwrite	<= `Td 0;
				r_dfread	<= `Td 0;
				r_dfdin		<= `Td 0;
				r_hrdata_mem<= `Td 0;
				r_hready_mem<= `Td 1;
				r_read_done	<= `Td 0;
				hvalid_mem_ack	<= `Td 0;
				c_state 	<= `Td ST_IDLE;
			end
		endcase
	end

assign w_SPI_Busy 		= (c_state==ST_IDLE) ? 1'b0 : 1'b1;
assign w_SPI_MOSI_OUT	= (w_MOSI_MASK&&r_rd_phase) ? 1'b0 : w_SPI_MOSI;
assign w_SPI_MOSI_OEN	= (w_mosi_swap) ? 1'b1 : 1'b0;

//----------------------------------------------------------------------------
// 	Interrupt
//----------------------------------------------------------------------------
assign w_core_fempty	= (w_fifo_inpempty|w_fifo_outempty);
assign w_core_ffull		= w_fifo_full_req;
assign w_core_fvalid	= w_ram_valid;

genvar g;
generate for (g = 0; g < INTR_NUM; g = g + 1) begin : GEN_INTR
	GET_EDGE #(.ASYNC(0)) u_GEN_INTR (.src(w_intr_src[g]),.rising(w_intr_r[g]),.falling(),.clk(FCLKG),.rstb(sig_rstb));

	always @(posedge FCLKG or negedge sig_rstb) 
		if (~sig_rstb) begin
			r_intr_req[g] <= `Td 0;
		end else begin
			if(w_core_intc[g]) begin
				r_intr_req[g] <= `Td 0;
			end else if((w_core_inte[g]==1'b1)&&(w_intr_r[g]==1'b1)) begin
				r_intr_req[g] <= `Td 1;
			end
		end
end endgenerate
assign O_INTR	= |r_intr_req;

endmodule
