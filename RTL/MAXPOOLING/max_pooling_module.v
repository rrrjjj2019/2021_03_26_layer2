module maxpooling(clk,pixel_1and2,pixel_3,pixel_4,curr_state_or,ans);

output reg [`CHANNEL_OUT * 8 - 1 : 0]ans;

input   [`CHANNEL_OUT * 16 - 1 : 0]pixel_1and2;
input   [`CHANNEL_OUT * 8 - 1 : 0]pixel_3;
input   [`CHANNEL_OUT * 8 - 1 : 0]pixel_4;
input   [2:0]                   curr_state_or;
input   clk;
reg    [`CHANNEL_OUT * 8 - 1 : 0]compare1;
reg    [`CHANNEL_OUT * 8 - 1 : 0]compare2;
integer  i;

always@(*) begin
    if(curr_state_or == 4)
    begin
        for(i = 0; i< `SRAM_NUM; i = i + 1) 
        begin
            if($signed(pixel_1and2[(i*2+1)* 8 - 1 -: 8])>=$signed(pixel_1and2[(i+1)* 16 - 1 -: 8])) 
            begin
                compare1[(i+1)* 8 - 1 -: 8]=pixel_1and2[(i*2+1)* 8 - 1 -: 8]; 
            end
            else 
            begin
                compare1[(i+1)* 8 - 1 -: 8]=pixel_1and2[(i+1)* 16 - 1 -: 8]; 
            end

            if($signed(pixel_3[(i+1)* 8 - 1 -: 8])>=$signed(pixel_4[(i+1)* 8 - 1 -: 8])) 
            begin
                compare2[(i+1)* 8 - 1 -: 8]=pixel_3[(i+1)* 8 - 1 -: 8]; 
            end
            else 
            begin
                compare2[(i+1)* 8 - 1 -: 8]=pixel_4[(i+1)* 8 - 1 -: 8]; 
            end
            if($signed(compare1[(i+1)* 8 - 1 -: 8])>=$signed(compare2[(i+1)* 8 - 1 -: 8])) 
            begin
                ans[(i+1)* 8 - 1 -: 8]=compare1[(i+1)* 8 - 1 -: 8]; 
            end
            else begin
                ans[(i+1)* 8 - 1 -: 8]=compare2[(i+1)* 8 - 1 -: 8]; 
            end
        end
    end

    else
    begin
        ans =0 ;
    end
end

endmodule
