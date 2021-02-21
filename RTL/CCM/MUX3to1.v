module MUX3to1(In1, In2, In3, Out, sel);

input 		[7:0]	In1;
input 		[7:0]	In2;
input 		[7:0]	In3;
input		[1:0]	sel;
output	reg	[7:0]	Out;

always @(*)
begin
	case (sel)
		2'b00 :
		begin
			Out = In1;
		end
		2'b01 :
		begin
			Out = In2;
		end
		2'b10 :
		begin
			Out = In3;
		end
		2'b11 :
		begin
			Out = 8'b0;
		end
	endcase
end

endmodule