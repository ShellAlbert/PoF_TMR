//TMR chip sample frequency: 100KHz.
//AD7988-5 data width: 16-bits.
//Temperature: 16-bits.
//Power Consumption: 16-bits.
//Total data size: (16+16+16)*100KHz=4.8Mbps.

module PoF_TMR_Top(

    //PCB Onboard oscillator 12MHz.
	input wire iClk_12MHz,
	
    //Data Upload and Command Download.
    output wire oData_TxD,
    input wire iCmd_RxD,

    //AD7988 SPI-Compatible Interface.
	output wire oSPI_SDI,
	output wire oSPI_CNV,
	output wire oSPI_SCK,
	input wire iSPI_SDO, 

    //100KHz Tick. Used to measured by an oscilloscope.
    output wire o100KHz_Tick,

    //TMP117 I2C Interface.
    output wire oTMP117_SCL,
    inout wire ioTMP117_SDA,
    input wire iTMP117_ALERT,

    //Debug LED*3.
	output wire oLED0, //Sample AD7988 and write data into FIFO.
    output wire oLED1, //UART Tx Indicator.
    output wire oLED2 //Read Temperature Sensor Indicator.
)/* synthesis RGB_TO_GPIO = "oLED0, oLED1, oLED2" */;


//HSOSC
//High-frequency oscillator.
//Generates 48-MHz nominal clock, +/- 10 percent, with user-programmable divider. 
//Can drive global clock network or fabric routing.
//Input Ports
//CLKHFPU :Power up the oscillator. After power up, output will be stable after 100 ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â½s. Active high.
//CLKHFEN :Enable the clock output. Enable should be low for the 100-ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â½s power-up period. Active high.
//Output Ports
//CLKHF :Oscillator output
//Parameters
//CLKHF_DIV
//Clock divider selection:
//0'b00 = 48 MHz
//0'b01 = 24 MHz
//0'b10 = 12 MHz
//0'b11 = 6 MHz
wire clk_48MHz;
//By default, the outputs are routed to global clock network. 
//To route to local fabric, see the examples in the Appendix: Design Entry section.
HSOSC #(.CLKHF_DIV("0b00")) //48 MHz
my_HSOSC(
    .CLKHFPU(1'b1), 
    .CLKHFEN(1'b1), 
    .CLKHF(clk_48MHz)
)/* synthesis ROUTE_THROUGH_FABRIC= 0 */; //the value can be either 0 or 1

///////////////////////////////////////////////////////////////////
//We are not allowed to use PLL output, because it's exclusive with Pin-35. ADQ[7].
//if PLL use internal clock source, Pin-35 can be used as output.
//PLL: 48MHz->66MHz.
//WARNING!!!!!
//If I configured PLL outputs 70MHz, it doesn't work correctly.
//Then I slowed down to 66MHz, it starts to work.
//66MHz is not reliable, down to 48MHz.

//ERROR <67201318> - 
//When PLL.OUTCORE or PLL.OUTGLOBAL is used, the input IO at site 'PR13B' can only drive PLL.REFERENCECLK due to architecture constraint. 
//When PLL is utilized in the design, the I/O site 'PR13B' can only be used exclusively as a PLL clock input. 
//If PLL uses an internal clock, the I/O site 'PR13B' can be used as an output.
wire rst_short_n;
wire clk_48MHz_Global;
wire clk_48MHz_Fabric;
ZPLL ic_pll(
	//.ref_clk_i(clk_48MHz), 
	.ref_clk_i(iClk_12MHz), //External on board oscillator.
	.rst_n_i(1'b1), 
	.lock_o(rst_short_n), 
	.outcore_o(clk_48MHz_Fabric), 
	.outglobal_o(clk_48MHz_Global)
);
//long reset.
reg rst_n;
reg [31:0] cntRst;
always @(posedge clk_48MHz_Global or negedge rst_short_n) 
if(!rst_short_n) begin rst_n<=0; cntRst<=0; end
else begin 
    cntRst<=(cntRst==32'hFFFFF0)?(cntRst):(cntRst+1);
    rst_n<=(cntRst==32'hFFFFF0)?(1):(0);
end

/////////////////////////////////////////////////////////
//Read speed must be faster than Write speed to avoid overflow.
wire [15:0] fifoDataIn; 
wire [15:0] fifoDataOut;
wire fifoWrEn;
wire fifoRdEn;
wire fifoEmptyFlag;
wire fifoFullFlag;
ZFIFO myFIFO(
        .clk_i(clk_48MHz_Global),
        .rst_i(!rst_n),
        .wr_en_i(fifoWrEn),
        .rd_en_i(fifoRdEn),
        .wr_data_i(fifoDataIn),
        .full_o(fifoFullFlag),
        .empty_o(fifoEmptyFlag),
        .rd_data_o(fifoDataOut));
//////////////////////////////////////////////////////////////////////////
ZAD7988_Adapter myAD7988(
	.iClk(clk_48MHz_Global), //input clock.
	.iRstN(rst_n),
	.iEn(1'b1),

	//AD7988 SPI-Compatible Interface.
	.oSDI(oSPI_SDI),
	.oCNV(oSPI_CNV),
	.oSCK(oSPI_SCK),
	.iSDO(iSPI_SDO), 

    //100KHz Tick. Used to measured by an oscilloscope.
    .o100KHz_Tick(o100KHz_Tick),

    //Write Data Into FIFO.
    .iFIFOFullFlag(fifoFullFlag),
    .oFIFOWrEn(fifoWrEn),
    .oFIFODataIn(fifoDataIn),

    //Working LED indicator.
    .oLED(oLED0)
);

/////////////////////////////////////////////////////////////////////////
reg [15:0] Temperature_Latest;
ZUART_Adapter myUART(
	.iClk(clk_48MHz_Global), //input clock.
	.iRstN(rst_n),
	.iEn(1'b1),

    //UART.
    .oUART_TxD(oData_TxD),
    //Working LED indicator.
    .oLED(oLED1),

    //Read Data from FIFO.
    .iFIFOEmptyFlag(fifoEmptyFlag),
    .oFIFORdEn(fifoRdEn),
    .iFIFODataOut(fifoDataOut),

    //Temperature Updated.
    .iTempData(Temperature_Latest)
);

//////////////////////////////////////////////////////////////////////

//TMP117 Temperature Sensor.
reg TMP117_En;
wire TMP117_DataValid;
reg [1:0] TMP117_Cmd;
reg [7:0] TMP117_RegAddr;
reg [15:0] TMP117_RegData;
wire [15:0] TMP117_RdData;
reg [7:0] Temp_Result={8'h00};
reg [7:0] Config_Reg={8'h01};
reg [7:0] Device_ID={8'h0F};
ZTMP117_Controller  myTMP117(
	.iClk(clk_48MHz_Global), //input clock.
	.iRstN(rst_n),
	.iEn(TMP117_En),

    //00: Read Device_ID regiter.
    //01: Read Temp_Result register.
    .iCommand(TMP117_Cmd), 
    .iRegAddr(TMP117_RegAddr),
    .iRegData(TMP117_RegData),

    //I2C Interface.
    .oSCL(oTMP117_SCL),
    .ioSDA(ioTMP117_SDA),

	//acquisition data output interface.
	.oRdData(TMP117_RdData),
	.oDataValid(TMP117_DataValid)
);
//driven by step_i.
reg [7:0] step_i; 
reg [31:0] cnt_delay;
reg Temp_LED;
always @(posedge clk_48MHz_Global or negedge rst_n) 
if(!rst_n) begin step_i<=0; cnt_delay<=0; TMP117_En<=0; Temperature_Latest<=0; Temp_LED<=0; end
else begin
    case(step_i)
    0: //Temperature changes slow, read data every 1 second.
        //48MHz/1Hz=48_000_000
        if(cnt_delay==32'd48_000_000-1) begin cnt_delay<=0; step_i<=step_i+1; end
        else begin cnt_delay<=cnt_delay+1; end
    1: //Read Temperature.
        if(TMP117_DataValid) begin TMP117_En<=0; Temperature_Latest<=TMP117_RdData; step_i<=step_i+1; end
        else begin TMP117_En<=1; TMP117_Cmd<=2'b00; TMP117_RegAddr<=Temp_Result; end
    2: //LED Indicator.
        if(cnt_delay==32'hFFFFF-1) begin cnt_delay<=0; Temp_LED<=0; step_i<=0; end
        else begin cnt_delay<=cnt_delay+1; Temp_LED<=1; end
    endcase
end
assign oLED2=Temp_LED; 

/*
//driven by step_i.
reg [7:0] step_i, step_i_return; // all variables are 8bits.
reg [31:0] cnt_delay;
reg [15:0] frame_head={16'h55AA};
reg [7:0] cnt_led1;
always @(posedge clk_48MHz_Global or negedge rst_n) 
if(!rst_n) begin
    step_i<=0; step_i_return<=0; 
    tx_en<=0; tx_data<=0;
    cnt_delay<=0; cnt_led1<=0; oLED1<=0;
end
else begin
    case(step_i)
        0: //delay 1s. gap between each ADC convertion.
            // if(cnt_delay>=32'd5_000) begin cnt_delay<=0; step_i<=step_i+1; end
            // else begin cnt_delay<=cnt_delay+1; end
            if(tick_100KHz) begin step_i<=step_i+1; end
        1: //Jump to transmit frame head bytes.
            begin tx_data_16bits<=frame_head; step_i<=90; step_i_return<=step_i+1; end
        2:  //capture ADC.
            if(adc_valid) begin adc_en<=0; tx_data_16bits<=adc_data; step_i<=step_i+1; end
            else begin adc_en<=1; end
        3: //Jump to transmit 16bits ADC value.
            begin step_i<=90; step_i_return<=step_i+1; end
        4: //Read Device_Id from TMP117. 
            if(TMP117_DataValid) begin TMP117_En<=0; tx_data_16bits<=TMP117_RdData; step_i<=step_i+1; end
            else begin TMP117_En<=1; TMP117_Cmd<=2'b00; TMP117_RegAddr<=Device_ID; end
        5:
            begin step_i<=90; step_i_return<=step_i+1; end
        6: //Read Temperature from TMP117.
            if(TMP117_DataValid) begin TMP117_En<=0; tx_data_16bits<=TMP117_RdData; step_i<=step_i+1; end
            else begin TMP117_En<=1; TMP117_Cmd<=2'b00; TMP117_RegAddr<=Temp_Result; end     
        7:
            begin step_i<=90; step_i_return<=step_i+1; end
        8: //Read Config_Reg from TMP117.
            if(TMP117_DataValid) begin TMP117_En<=0; tx_data_16bits<=TMP117_RdData; step_i<=step_i+1; end
            else begin TMP117_En<=1; TMP117_Cmd<=2'b00; TMP117_RegAddr<=Config_Reg; end     
        9:
            begin step_i<=90; step_i_return<=step_i+1; end
        10: //Delay 1s to check temperature and ADC.
            if(cnt_delay>=32'd48000000) begin cnt_delay<=0; step_i<=step_i+1; end
            else begin cnt_delay<=cnt_delay+1; end
        11:
            begin 
                step_i<=0; 
                ///////////////////////////////////////////////////////////////
                if(cnt_led1>=8'hFF-1) begin cnt_led1<=0; oLED1<=~oLED1; end
                else begin cnt_led1<=cnt_led1+1; end
            end
        //////////////////////////////////////////////////////////////////
        90: //Tx High 8 bits.
            begin 
                if(tx_done) begin tx_en<=0; step_i<=step_i+1; end
                else begin tx_en<=1; tx_data<=tx_data_16bits[15:8]; end
            end
        91: //Tx Low 8 bits.
            begin
                if(tx_done) begin tx_en<=0; step_i<=step_i+1; end
                else begin tx_en<=1; tx_data<=tx_data_16bits[7:0]; end
            end
        92:
            begin step_i<=step_i_return; end
            
        default:
                begin step_i<=0; end
    endcase
end
*/
endmodule