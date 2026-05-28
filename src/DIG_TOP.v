////////////////////////////////////////////////////////
//	Company:		SKAIChips, Suwon, South Korea 
//	Engineer: 		Y.S.Song
//	Create Date:    2024.08.
//  Module: 		DIG_TOP
//  Project: 		SALUS8_SPI_202408
////////////////////////////////////////////////////////
`timescale 1ns/10ps

module DIG_TOP (
//SPI Interface Port
	input wire			SCLK				,
	output wire			MISO				,
	input wire			MOSI				,
	input wire			CSN					,
	input wire			RSTB				,
//Analog Interface Port
//address: 0x00
	output wire	[15:00]	PF_CTRL				,
//address: 0x01	
	output wire	[01:00]	PF_LOCK_CON_DLY		,
	output wire	[01:00]	PF_LOCK_CON_IN		,
	output wire	[01:00]	PF_LOCK_CON_OUT		,
	output wire			PF_LOCK_EN			,
	output wire			PF_RESETB			,
	output wire			PF_BYPASS			,
	output wire			PF_FSEL				,
	output wire			PF_FEED_EN			,
	output wire			PF_AFC_ENB			,
	output wire	[01:00]	PF_ICP				,
//address: 0x02	
	output wire	[04:00]	PF_EXTAFC			,
	output wire			PF_FOUT_MASK		,
	output wire	[09:00]	PF_M				,
//address: 0x03
	output wire	[15:00]	PF_RSEL				,
//address: 0x04
	output wire	[15:00]	PF_K				,
//address: 0x05
	output wire	[05:00]	PF_P				,
	output wire	[02:00]	PF_S				,
	output wire			PF_SSCG_EN			,
	output wire	[05:00]	PF_MRR				,
//address: 0x06
	output wire	[01:00]	PF_SEL_PF			,
	output wire	[07:00]	PF_MFR				,
//address: 0x07
	output wire	[09:00]	PL1_AFC				,
	output wire			PL1_BGR_BYPASS_EN	,
	output wire			PL1_BGR_EN			,
	output wire	[01:00]	PL1_BGR_I_CON		,
	output wire	[01:00]	PL1_BGR_TC_CON		,
//address: 0x08
	output wire			PL1_LDO_EN			,
	output wire			PL1_RESETB_VCO		,
	output wire			PL1_VCO_EN			,
	output wire	[02:00]	PL1_VC_CON			,
	output wire	[03:00]	PL1_VSEL_LDO		,
//address: 0x09
	output wire	[09:00]	PL2_AFC				,
	output wire			PL2_BGR_BYPASS_EN	,
	output wire			PL2_BGR_EN			,
	output wire	[01:00]	PL2_BGR_I_CON		,
	output wire	[01:00]	PL2_BGR_TC_CON		,
//address: 0x0A
	output wire			PL2_LDO_EN			,
	output wire			PL2_RESETB_VCO		,
	output wire			PL2_VCO_EN			,
	output wire	[02:00]	PL2_VC_CON			,
	output wire	[03:00]	PL2_VSEL_LDO		,
//address: 0x0B
	output wire	[01:00]	TS1_BGR_TC_CON_TS	,
	output wire	[03:00]	TS1_BJT_SEL_TS		,
	output wire	[01:00]	TS1_DMUX_ADDR_TS	,
	output wire			TS1_EN_TS			,
	output wire			TS1_HTOL_SEL		,
	output wire	[03:00]	TS1_OFFSET_CON_TS	,
//address: 0x0C
	output wire	[06:00]	TS1_SLOPE_CON_TS	,
	output wire			TS1_SOC_TS			,
	output wire			TS1_TEST_MODE_TS	,
	output wire	[01:00]	TS1_AMUX_ADDR_TS	,
	output wire	[01:00]	TS1_AVG_MODE_TS		,
	output wire	[01:00]	TS1_BGR_I_CON_TS	,
//address: 0x0D
	output wire	[01:00]	TS2_BGR_TC_CON_TS	,
	output wire	[03:00]	TS2_BJT_SEL_TS		,
	output wire	[01:00]	TS2_DMUX_ADDR_TS	,
	output wire			TS2_EN_TS			,
	output wire			TS2_HTOL_SEL		,
	output wire	[03:00]	TS2_OFFSET_CON_TS	,
//address: 0x0E
	output wire	[06:00]	TS2_SLOPE_CON_TS	,
	output wire			TS2_SOC_TS			,
	output wire			TS2_TEST_MODE_TS	,
	output wire	[01:00]	TS2_AMUX_ADDR_TS	,
	output wire	[01:00]	TS2_AVG_MODE_TS		,
	output wire	[01:00]	TS2_BGR_I_CON_TS	,
//address: 0x0F
	output wire	[15:00]	TS2_RESERVED		,
//address: 0x10
	output wire	[15:00]	POR_RESERVED		,
//address: 0x11
	input wire	[08:00]	TS1_OUT_9BIT_TS		,
//address: 0x12
	input wire	[08:00]	TS2_OUT_9BIT_TS	
);

parameter	WREG_NUM		= 17;
parameter	RREG_NUM		= 2;

parameter	BITS_NUM		= 16;

parameter	INIT_WREG00	= 16'h0000;
parameter	INIT_WREG01	= 16'hFE00;
parameter	INIT_WREG02	= 16'h0000;
parameter	INIT_WREG03	= 16'h0000;
parameter	INIT_WREG04	= 16'h0000;
parameter	INIT_WREG05	= 16'h0000;
parameter	INIT_WREG06	= 16'h8000;
parameter	INIT_WREG07	= 16'h8000;
parameter	INIT_WREG08	= 16'h1200;
parameter	INIT_WREG09	= 16'h8000;
parameter	INIT_WREG0A	= 16'h1200;
parameter	INIT_WREG0B	= 16'h0000;
parameter	INIT_WREG0C	= 16'h0000;
parameter	INIT_WREG0D	= 16'h0000;
parameter	INIT_WREG0E	= 16'h0000;
parameter	INIT_WREG0F	= 16'h0000;
parameter	INIT_WREG10	= 16'h0000;

wire [WREG_NUM*BITS_NUM-1:0]	INIT_WREG;
assign INIT_WREG[BITS_NUM*1-1 :BITS_NUM*0]	= INIT_WREG00;
assign INIT_WREG[BITS_NUM*2-1 :BITS_NUM*1]	= INIT_WREG01;
assign INIT_WREG[BITS_NUM*3-1 :BITS_NUM*2]	= INIT_WREG02;
assign INIT_WREG[BITS_NUM*4-1 :BITS_NUM*3]	= INIT_WREG03;
assign INIT_WREG[BITS_NUM*5-1 :BITS_NUM*4]	= INIT_WREG04;
assign INIT_WREG[BITS_NUM*6-1 :BITS_NUM*5]	= INIT_WREG05;
assign INIT_WREG[BITS_NUM*7-1 :BITS_NUM*6]	= INIT_WREG06;
assign INIT_WREG[BITS_NUM*8-1 :BITS_NUM*7]	= INIT_WREG07;
assign INIT_WREG[BITS_NUM*9-1 :BITS_NUM*8]	= INIT_WREG08;
assign INIT_WREG[BITS_NUM*10-1:BITS_NUM*9]	= INIT_WREG09;
assign INIT_WREG[BITS_NUM*11-1:BITS_NUM*10]	= INIT_WREG0A;
assign INIT_WREG[BITS_NUM*12-1:BITS_NUM*11]	= INIT_WREG0B;
assign INIT_WREG[BITS_NUM*13-1:BITS_NUM*12]	= INIT_WREG0C;
assign INIT_WREG[BITS_NUM*14-1:BITS_NUM*13]	= INIT_WREG0D;
assign INIT_WREG[BITS_NUM*15-1:BITS_NUM*14]	= INIT_WREG0E;
assign INIT_WREG[BITS_NUM*16-1:BITS_NUM*15]	= INIT_WREG0F;
assign INIT_WREG[BITS_NUM*17-1:BITS_NUM*16]	= INIT_WREG10;

wire [BITS_NUM-1:00]	WREG00	;		
wire [BITS_NUM-1:00]	WREG01	;		
wire [BITS_NUM-1:00]	WREG02	;		
wire [BITS_NUM-1:00]	WREG03	;		
wire [BITS_NUM-1:00]	WREG04	;		
wire [BITS_NUM-1:00]	WREG05	;		
wire [BITS_NUM-1:00]	WREG06	;		
wire [BITS_NUM-1:00]	WREG07	;		
wire [BITS_NUM-1:00]	WREG08	;		
wire [BITS_NUM-1:00]	WREG09	;		
wire [BITS_NUM-1:00]	WREG0A	;
wire [BITS_NUM-1:00]	WREG0B	;		
wire [BITS_NUM-1:00]	WREG0C	;		
wire [BITS_NUM-1:00]	WREG0D	;		
wire [BITS_NUM-1:00]	WREG0E	;		
wire [BITS_NUM-1:00]	WREG0F	;
wire [BITS_NUM-1:00]	WREG10	;		

wire [WREG_NUM*BITS_NUM-1:0]	WREG;	
assign WREG00 = WREG[BITS_NUM*1-1:BITS_NUM*0];
assign WREG01 = WREG[BITS_NUM*2-1:BITS_NUM*1];
assign WREG02 = WREG[BITS_NUM*3-1:BITS_NUM*2];
assign WREG03 = WREG[BITS_NUM*4-1:BITS_NUM*3];
assign WREG04 = WREG[BITS_NUM*5-1:BITS_NUM*4];
assign WREG05 = WREG[BITS_NUM*6-1:BITS_NUM*5];
assign WREG06 = WREG[BITS_NUM*7-1:BITS_NUM*6];
assign WREG07 = WREG[BITS_NUM*8-1:BITS_NUM*7];
assign WREG08 = WREG[BITS_NUM*9-1:BITS_NUM*8];
assign WREG09 = WREG[BITS_NUM*10-1:BITS_NUM*9];
assign WREG0A = WREG[BITS_NUM*11-1:BITS_NUM*10];
assign WREG0B = WREG[BITS_NUM*12-1:BITS_NUM*11];
assign WREG0C = WREG[BITS_NUM*13-1:BITS_NUM*12];
assign WREG0D = WREG[BITS_NUM*14-1:BITS_NUM*13];
assign WREG0E = WREG[BITS_NUM*15-1:BITS_NUM*14];
assign WREG0F = WREG[BITS_NUM*16-1:BITS_NUM*15];
assign WREG10 = WREG[BITS_NUM*17-1:BITS_NUM*16];

//Analog Interface REG
//address: 0x00 READ/WRITE
	assign PF_CTRL			=	WREG00[15:00]	;
//address: 0x01
//	assign					=	WREG01[01:00]	;
	assign PF_ICP			=	WREG01[03:02]	;
	assign PF_AFC_ENB		=	WREG01[04]		;
	assign PF_FEED_EN		=	WREG01[05]		;
	assign PF_FSEL			=	WREG01[06]		;
	assign PF_BYPASS		=	WREG01[07]		;
	assign PF_RESETB		=	WREG01[08]		;
	assign PF_LOCK_EN		=	WREG01[09]		;
	assign PF_LOCK_CON_OUT	=	WREG01[11:10]	;
	assign PF_LOCK_CON_IN	=	WREG01[13:12]	;
	assign PF_LOCK_CON_DLY	=	WREG01[15:14]	;
//address: 0x02 READ/WRITE
	assign PF_M				=	WREG02[09:00]	;
	assign PF_FOUT_MASK		=	WREG02[10]		;
	assign PF_EXTAFC		=	WREG02[15:11]	;
//address: 0x03 READ/WRITE
	assign PF_RSEL			=	WREG03[15:00]	;
//address: 0x04 READ/WRITE
	assign PF_K				=	WREG04[15:00]	;
//address: 0x05 READ/WRITE
	assign PF_MRR			=	WREG05[05:00]	;
	assign PF_SSCG_EN		=	WREG05[06]		;
	assign PF_S				=	WREG05[09:07]	;
	assign PF_P				=	WREG05[15:10]	;
//address: 0x06 READ/WRITE
//	assign					=	WREG06[05:00]	;
	assign PF_MFR			=	WREG06[13:06]	;
	assign PF_SEL_PF		=	WREG06[15:14]	;
//address: 0x07 READ/WRITE
	assign PL1_BGR_TC_CON	=	WREG07[01:00]	;
	assign PL1_BGR_I_CON	=	WREG07[03:02]	;
	assign PL1_BGR_EN		=	WREG07[04]		;
	assign PL1_BGR_BYPASS_EN=	WREG07[05]		;
	assign PL1_AFC			=	WREG07[15:06]	;
//address: 0x08 READ/WRITE
//	assign					=	WREG08[05:00]	;
	assign PL1_VSEL_LDO		=	WREG08[09:06]	;
	assign PL1_VC_CON		=	WREG08[12:10]	;
	assign PL1_VCO_EN		=	WREG08[13]		;
	assign PL1_RESETB_VCO	=	WREG08[14]		;
	assign PL1_LDO_EN		=	WREG08[15]		;
//address: 0x09 READ/WRITE
	assign PL2_BGR_TC_CON	=	WREG09[01:00]	;
	assign PL2_BGR_I_CON	=	WREG09[03:02]	;
	assign PL2_BGR_EN		=	WREG09[04]		;
	assign PL2_BGR_BYPASS_EN=	WREG09[05]		;
	assign PL2_AFC			=	WREG09[15:06]	;
//address: 0x0A READ/WRITE
//	assign					=	WREG0A[05:00]	;
	assign PL2_VSEL_LDO		=	WREG0A[09:06]	;
	assign PL2_VC_CON		=	WREG0A[12:10]	;
	assign PL2_VCO_EN		=	WREG0A[13]		;
	assign PL2_RESETB_VCO	=	WREG0A[14]		;
	assign PL2_LDO_EN		=	WREG0A[15]		;
//address: 0x0B READ/WRITE
//	assign					=	WREG0B[01:00]	;
	assign TS1_OFFSET_CON_TS=	WREG0B[05:02]	;
	assign TS1_HTOL_SEL		=	WREG0B[06]		;
	assign TS1_EN_TS		=	WREG0B[07]		;
	assign TS1_DMUX_ADDR_TS	=	WREG0B[09:08]	;
	assign TS1_BJT_SEL_TS	=	WREG0B[13:10]	;
	assign TS1_BGR_TC_CON_TS=	WREG0B[15:14]	;
//address: 0x0C READ/WRITE
//	assign					=	WREG0C[00]		;
	assign TS1_BGR_I_CON_TS	=	WREG0C[02:01]	;
	assign TS1_AVG_MODE_TS	=	WREG0C[04:03]	;
	assign TS1_AMUX_ADDR_TS	=	WREG0C[06:05]	;
	assign TS1_TEST_MODE_TS	=	WREG0C[07]		;
	assign TS1_SOC_TS		=	WREG0C[08]		;
	assign TS1_SLOPE_CON_TS	=	WREG0C[15:09]	;
//address: 0x0D READ/WRITE
//	assign					=	WREG0D[01:00]	;
	assign TS2_OFFSET_CON_TS=	WREG0D[05:02]	;
	assign TS2_HTOL_SEL		=	WREG0D[06]		;
	assign TS2_EN_TS		=	WREG0D[07]		;
	assign TS2_DMUX_ADDR_TS	=	WREG0D[09:08]	;
	assign TS2_BJT_SEL_TS	=	WREG0D[13:10]	;
	assign TS2_BGR_TC_CON_TS=	WREG0D[15:14]	;
//address: 0x0E READ/WRITE
//	assign					=	WREG0E[00]		;
	assign TS2_BGR_I_CON_TS	=	WREG0E[02:01]	;
	assign TS2_AVG_MODE_TS	=	WREG0E[04:03]	;
	assign TS2_AMUX_ADDR_TS	=	WREG0E[06:05]	;
	assign TS2_TEST_MODE_TS	=	WREG0E[07]		;
	assign TS2_SOC_TS		=	WREG0E[08]		;
	assign TS2_SLOPE_CON_TS	=	WREG0E[15:09]	;
//address: 0x0F READ/WRITE
	assign TS2_RESERVED		=	WREG0F[15:00]	;
//address: 0x10 READ/WRITE
	assign POR_RESERVED		=	WREG10[15:00]	;

wire [RREG_NUM*BITS_NUM-1:0]	RREG;
//address: 0x11 READ Only
assign RREG[BITS_NUM*1-1:BITS_NUM*0]	= {TS1_OUT_9BIT_TS, 7'b0000000};	//	RREG11
//address: 0x12 READ Only
assign RREG[BITS_NUM*2-1:BITS_NUM*1]	= {TS2_OUT_9BIT_TS, 7'b0000000};	//	RREG12

wire MISO_OE;

SPI_TOP_R0 #(
	.RWMEM_D		(WREG_NUM),
	.ROMEM_D		(RREG_NUM),
	.BITS_NUM		(BITS_NUM)

) u_SPI_TOP_R0 (
	/*in std_logic						*/	.RST		(~RSTB			), 
	/*in std_logic						*/	.RW_FLAG	(1'b1			),
	/*in std_logic						*/	.CSN		(CSN			), 
	/*in std_logic						*/	.SCLK		(SCLK			), 
	/*in std_logic						*/	.MOSI		(MOSI			), 
	/*out std_logic						*/	.MISO		(MISO			), 
	/*out std_logic						*/	.MISO_OE	(MISO_OE		), 
	/*in std_logic_vector (15 downto 0)*/	.INIT_WREG	(INIT_WREG		),
	/*out std_logic_vector (15 downto 0)*/	.WREG		(WREG			),
	/*in std_logic_vector (15 downto 0)*/	.RREG		(RREG			)
);

endmodule
