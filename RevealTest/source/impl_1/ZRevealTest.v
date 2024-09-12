module ZRevealTest(
	output reg oLED1,
	output reg oLED2
)/* synthesis RGB_TO_GPIO = "oLED1, oLED2" */;

wire clk_48MHz;
//By default, the outputs are routed to global clock network. 
//To route to local fabric, see the examples in the Appendix: Design Entry section.
HSOSC #(.CLKHF_DIV("0b00")) //48 MHz
my_HSOSC(
    .CLKHFPU(1'b1), 
    .CLKHFEN(1'b1), 
    .CLKHF(clk_48MHz)
)/* synthesis ROUTE_THROUGH_FABRIC= 0 */; //the value can be either 0 or 1

wire clk_Global; //Global Clock Network.
wire clk_Local; //Local Fabric.
wire rst_n;
ZPLL ic_PLL(
    .ref_clk_i(clk_48MHz), 
    //.rst_n_i(rst_n_POR), //Enable this line in ModelSim.
    .rst_n_i(1'b1), //Enable this line in Lattice Radiant.
    .lock_o(rst_n),  
    .outcore_o(clk_Local), //A Channel-Local Faric.
    .outglobal_o(clk_Global) //A Channel-Global Clock Network.
    //Since iCE40UP5K only has 1 PLL, so Channel-B left empty.
	//.outcoreb_o(), //B Channel-Local Fabric.
    //.outglobalb_o() //B Channel-Global Clock Network.
);

/*
reg [15:0] CNT;
reg rst_n;
always @(posedge clk_48MHz)
begin
    if(CNT==16'hFF) begin
        rst_n<=1;
    end
    else begin
        CNT<=CNT+1;
        rst_n<=0;
    end
end
*/

reg [31:0] CNT2; //48MHz='h2DC6C00

always @(posedge clk_48MHz or negedge rst_n)
if(!rst_n) begin
	CNT2<=0;
	oLED1<=0; oLED2<=0;
end
else begin
	if(CNT2==32'h2DC6C00) begin 
		CNT2<=0;
		oLED1<=~oLED1;
		oLED2<=~oLED2;
	end
	else begin 
			CNT2<=CNT2+1;
		end 
end
	
endmodule