
wire		miso;
reg			ss; 
reg			sck; 
reg			mosi; 
wire		clk = CLK;
reg [15:0]	srdata;

task TSPI_START;
integer st_i;
	begin
		for(st_i=0;st_i<32;st_i=st_i+1)	@(posedge clk);
			ss<=0;
		for(st_i=0;st_i<2;st_i=st_i+1)	@(posedge clk);
			sck<=0;mosi<=0;
		for(st_i=0;st_i<3;st_i=st_i+1)@(posedge clk);
	end
endtask

task TSPI_STOP;
integer so_i;
	begin
		for(so_i=0;so_i<3;so_i=so_i+1)	@(posedge clk);
			sck<=0;mosi<=0;
		for(so_i=0;so_i<2;so_i=so_i+1)	@(posedge clk);
			ss<=1;
		for(so_i=0;so_i<32;so_i=so_i+1)	@(posedge clk);
		#10000;
	end
endtask

task TSPI_BREAD;
output [7:0]	dataout;
integer r_i;
	begin
	for(r_i=0;r_i<8;r_i=r_i+1) begin
		sck<=0;
		@(posedge clk);
		sck<=1;
		dataout[7-r_i]=miso;
		@(posedge clk);
	end
		sck<=0;
	$display($stime, " ns : TSPI read end (%02x)",dataout);
	end
endtask

task TSPI_BWRITE;
input	[7:0]	datain;
integer w_i;
	begin
	$display($stime, " ns : TSPI write start (%02x)",datain);
	for(w_i=0;w_i<8;w_i=w_i+1) begin
		sck<=0;
		mosi<=datain[7-w_i];
		@(posedge clk);
		sck<=1;
		@(posedge clk);
	end
		sck<=0;
	end
endtask

initial begin
	ss = 1;
	sck = 0;
	mosi = 0;
	#100000;

	/*
	TSPI_START;
	TSPI_BWRITE({1'b0,7'h00});	//address
	TSPI_BREAD(srdata[15:8]);
	TSPI_BREAD(srdata[07:0]);
	TSPI_STOP;

	TSPI_START;
	TSPI_BWRITE({1'b1,7'h00});	//address
	TSPI_BWRITE(8'h12);
	TSPI_BWRITE(8'h34);
	TSPI_STOP;

	TSPI_START;
	TSPI_BWRITE({1'b0,7'h00});	//address
	TSPI_BREAD(srdata[15:8]);
	TSPI_BREAD(srdata[07:0]);
	TSPI_STOP;
	*/

	#1000;
	$finish;
end

