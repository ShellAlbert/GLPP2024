module ZGPIOMultiplexer(
    //iDir=0: input direciton.
    //iDir=1: output direction.
	input iDir,
	inout [7:0] GPIO,
    input [7:0] iGPIO,
    output [7:0] oGPIO
);
assign GPIO=(iDir==1'b1)?oGPIO:iGPIO;
endmodule