//-------------------------------------
//--------- fulladder -----------------
//-------------------------------------
module fulladder (a,b,cin,cout,s);

input a,b,cin;
output cout,s;
wire [2:0] o ;

xorgate xor1(a,b,o[0]);
xorgate xor2(o[0],cin,s);

andgate and1(a,b,o[2]);
andgate and2(o[0],cin,o[1]);

orgate or1(o[1],o[2],cout);

endmodule
//---------------------------------------
//------------ andgate ------------------
//---------------------------------------
module andgate(a,b,c);
input a,b;
output c;
assign c = a&b;
endmodule

//---------------------------------------
//------------ orgate -------------------
//---------------------------------------
module orgate(a,b,c);
input a,b;
output c;
assign c = a|b;
endmodule
//---------------------------------------
//------------ xorgate ------------------
//---------------------------------------
module xorgate(a,b,c);
input a,b;
output c;
assign c = ~a&b | ~b&a;
endmodule


