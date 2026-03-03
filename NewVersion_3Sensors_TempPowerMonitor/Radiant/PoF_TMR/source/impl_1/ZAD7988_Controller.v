/*
* filename: zad7988_controller.v
* function: ad7988 works in 3 wires mode, acquire data and output.
* date: April 4,2024.
* author: Shell Albert 
* 
* SCK Period (CS Mode), VIO above 1.71V, tSCK=22nS(Min), f=45MHz.
* therefore we set SCK to 48MHz/2=24MHz.
*/
module ZAD7988_Controller(
	//common signals.
	input iClk, //input clock.
	input iRstN,
	input iEn,

	//AD7988 SPI-Compatible Interface.
	output oSDI,
	output reg oCNV,
	output reg oSCK,
	input iSDO, 

	//acquisition data output interface.
	output reg [15:0] oData,
	output reg oDataValid
);

//With SDI tied to VIO(1.8V),
//a rising edge on CNV initiates a conversion, select the CS mode.
//and forces SDO to high impedance.
assign oSDI=1;

//generate 6MHz clock.
//48MHz/8MHz=6.
reg [15:0] cntClkPrescale;
always @(posedge iClk or negedge iRstN)
if(!iRstN) begin
    cntClkPrescale<=0;
end
else begin
	if(iEn) begin
		if(cntClkPrescale==6-1) begin cntClkPrescale<=0; end
		else begin cntClkPrescale<=cntClkPrescale+1; end
	end
	else begin cntClkPrescale<=0; end
end
wire tick_Clk;
assign tick_Clk=(cntClkPrescale==6-1)?1:0;

//Driven by step i.
reg [7:0] step_i;
reg [7:0] CNT1;
always @(posedge iClk or negedge iRstN)
if(!iRstN) begin
	step_i<=0;
	CNT1<=0;
	oCNV<=0; oSCK<=0;
	oData<=0; oDataValid<=0;
end
else if(iEn) begin
		case(step_i)
		0:
			begin oCNV<=1; step_i<=step_i+1; end
		1:
			//give ADC adequate time to convert.(10 clocks period)
			//AD7988-1,Conversion time,CNV Rising Edge to Data Available, 9.5uS(Max).
			if(tick_Clk) begin
				if(CNT1==10-1) begin CNT1<=0; oCNV<=0; step_i<=step_i+1; end
				else begin CNT1<=CNT1+1; end
			end
		2: //output 16 clock.
			if(tick_Clk) begin
				if(CNT1==16) begin CNT1<=0; step_i<=step_i+2; end
				else begin oSCK<=1; CNT1<=CNT1+1; step_i<=step_i+1; end
			end
		3: //latch data in at falling edge.
			if(tick_Clk) begin oSCK<=0; oData<={oData[14:0],iSDO}; step_i<=step_i-1; end
		4:
			begin oCNV<=1; oDataValid<=1; step_i<=step_i+1; end
		5:
			begin oDataValid<=0; step_i<=0; end
		default:
			begin step_i<=0; end
		endcase
end
else begin 
	oDataValid<=0; oData<=0;
	oCNV<=0; oSCK<=0;
end

endmodule


