module keybord_encoder(a,b);
    input  [9:1] a;
    output [3:0] b;
   
    assign b[0] = a[1] | a[3] | a[5] | a[7] | a[9];
    assign b[1] = a[2] | a[3] | a[6] | a[7];
    assign b[2] = a[4] | a[5] | a[6] | a[7];
    assign b[3] = a[8] | a[9];
endmodule
