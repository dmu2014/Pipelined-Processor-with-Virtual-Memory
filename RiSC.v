//
// RiSC-16 skeleton
//

`define ADD	3'd0
`define ADDI	3'd1
`define NAND	3'd2
`define LUI	3'd3
`define SW	3'd4
`define LW	3'd5
`define BNE	3'd6
`define JALR	3'd7
`define EXTEND	3'd7

// extended sub-classes:
`define SYS_MODE	3'd0
`define SYS_TLB		3'd1
`define SYS_CRMOVE	3'd2
`define SYS_RFE		3'd3
`define SYS_RESERVED	3'd4
`define SYS_EXCEPTION	3'd5
`define SYS_INTERRUPT	3'd6
`define SYS_TRAP	3'd7

// some exception/interrupt sub-types:
`define MODE_RUN	{ `SYS_MODE, 4'd0 }
`define MODE_SLEEP	{ `SYS_MODE, 4'd1 }
`define MODE_HALT	{ `SYS_MODE, 4'd2 }
`define EXC_TLBUMISS	{ `SYS_EXCEPTION, 4'd1 }
`define EXC_TLBKMISS	{ `SYS_EXCEPTION, 4'd2 }
`define EXC_INVALIDOP	{ `SYS_EXCEPTION, 4'd3 }
`define EXC_PRIVILEGES	{ `SYS_EXCEPTION, 4'd5 }
`define TLB_WRITE	{ `SYS_TLB, 4'd1 }
`define RFE_JUMP	{ `SYS_RFE, 4'd0 }
`define TRAP_HALT	{ `SYS_TRAP, 4'd1 }

`define INSTRUCTION_OP	15:13	// opcode
`define INSTRUCTION_RA	12:10	// rA 
`define INSTRUCTION_RB	9:7	// rB 
`define INSTRUCTION_RC	2:0	// rC 
`define INSTRUCTION_IM	6:0	// immediate (7-bit)
`define INSTRUCTION_LI	9:0	// large unsigned immediate (10-bit, 0-extended)
`define INSTRUCTION_SB	6	// immediate's sign bit

`define	PSR_KMODE	7	// k-mode bit of PSR
`define	PSR_ASID	5:0	// ASID bits of PSR

`define	BYTE_TOP	15:8	// convenient way to get top half of word
`define	BYTE_BOT	7:0	// ... and bottom half

`define ZERO		16'd0

`define HALTINSTRUCTION	{ `EXTEND, 3'd0, 3'd0, `MODE_HALT }




//
// how the TLB functions:
//
// vpn1 and asid1 are inputs; search result goes out pfn1 and miss1 (pfn1 is valid if miss1 is 0)
// vpn2 and asid2 are inputs; search result goes out pfn2 and miss2 (pfn2 is valid if miss2 is 0)
// ASID = 0 implies kernel mode
// vpn2 + asid2 + map2 are written into TLB if write is 1
// => tie port 2 (asid2, vpn2, pfn2, miss2) to MEM stage; tie port 1 to IF stage
//
module tlb (clk, reset, vpn1, asid1, vpn2, asid2, pfn1, pfn2, miss1, miss2, map2, write);
	input		clk, reset, write;
	output		miss1, miss2;
	input	[7:0]	vpn1, vpn2;
	input	[5:0]	asid1, asid2;
	output	[7:0]	pfn1, pfn2;
	input	[7:0]	map2;

	wire	clk_A, clk_B, clk_C, clk_D, clk_E, clk_F, clk_G, clk_H,
		res_A, res_B, res_C, res_D, res_E, res_F, res_G, res_H;

	buf	cA(clk_A, clk), cB(clk_B, clk), cC(clk_C, clk), cD(clk_D, clk),
		cE(clk_E, clk), cF(clk_F, clk), cG(clk_G, clk), cH(clk_H, clk),
		rA(res_A, reset), rB(res_B, reset), rC(res_C, reset), rD(res_D, reset),
		rE(res_E, reset), rF(res_F, reset), rG(res_G, reset), rH(res_H, reset);


	wire		tlbA_v;
	wire	[5:0]	tlbA_asid;
	wire	[7:0]	tlbA_vpn;
	wire	[7:0]	tlbA_pfn;
	wire		tlbB_v;
	wire	[5:0]	tlbB_asid;
	wire	[7:0]	tlbB_vpn;
	wire	[7:0]	tlbB_pfn;

	wire		tlbA__we;
	wire	[5:0]	tlbA_asid__in;
	wire	[7:0]	tlbA_vpn__in;
	wire	[7:0]	tlbA_pfn__in;
	wire		tlbB__we;
	wire	[5:0]	tlbB_asid__in;
	wire	[7:0]	tlbB_vpn__in;
	wire	[7:0]	tlbB_pfn__in;

	wire		ctr_out;
	wire		ctr_in = ~ctr_out;

	registerX #(1)		ctr	(.reset(res_A), .clk(clk_A), .out(ctr_out), .in(ctr_in), .we(write));

	registerX #(1)		tlbregA_v	(.reset(res_A), .clk(clk_A), .out(tlbA_v), .in(tlbA__we), .we(tlbA__we));
	registerX #(6)		tlbregA_asid	(.reset(res_B), .clk(clk_B), .out(tlbA_asid), .in(tlbA_asid__in), .we(tlbA__we));
	registerX #(8)		tlbregA_vpn	(.reset(res_C), .clk(clk_C), .out(tlbA_vpn), .in(tlbA_vpn__in), .we(tlbA__we));
	registerX #(8)		tlbregA_pfn	(.reset(res_D), .clk(clk_D), .out(tlbA_pfn), .in(tlbA_pfn__in), .we(tlbA__we));

	registerX #(1)		tlbregB_v	(.reset(res_E), .clk(clk_E), .out(tlbB_v), .in(tlbB__we), .we(tlbB__we));
	registerX #(6)		tlbregB_asid	(.reset(res_F), .clk(clk_F), .out(tlbB_asid), .in(tlbB_asid__in), .we(tlbB__we));
	registerX #(8)		tlbregB_vpn	(.reset(res_G), .clk(clk_G), .out(tlbB_vpn), .in(tlbB_vpn__in), .we(tlbB__we));
	registerX #(8)		tlbregB_pfn	(.reset(res_H), .clk(clk_H), .out(tlbB_pfn), .in(tlbB_pfn__in), .we(tlbB__we));

    
	assign	tlbA__we = write & ctr_in; 
	assign	tlbA_asid__in = asid2;
	assign	tlbA_vpn__in = vpn2;
	assign	tlbA_pfn__in = map2;
	assign	tlbB__we = write & ctr_out; 
	assign	tlbB_asid__in = asid2;
	assign	tlbB_vpn__in = vpn2;
	assign	tlbB_pfn__in = map2;

        wire            port1_Hits_EntryA = (vpn1 == tlbA_vpn) & (asid1 == tlbA_asid) & tlbA_v;
        wire            port1_Hits_EntryB = (vpn1 == tlbB_vpn) & (asid1 == tlbB_asid) & tlbB_v;
        wire            port2_Hits_EntryA = (vpn2 == tlbA_vpn) & (asid2 == tlbA_asid) & tlbA_v;
        wire            port2_Hits_EntryB = (vpn2 == tlbB_vpn) & (asid2 == tlbB_asid) & tlbB_v;

        //debug
        wire            asid1_is_kphys = asid1 == 0;
        wire            asid2_is_kphys = asid2 == 0; 
		assign  pfn1 = (port1_Hits_EntryA) ? tlbA_pfn 
                        : (port1_Hits_EntryB) ? tlbB_pfn
                        : (asid1_is_kphys) ? vpn1
                        : 0;
                
        assign  miss1 = (asid1_is_kphys & ~vpn1[7]) ? 1'b0
                        : (~port1_Hits_EntryA & ~port1_Hits_EntryB);

        assign  pfn2 = (port2_Hits_EntryA) ? tlbA_pfn 
                        : (port2_Hits_EntryB) ? tlbB_pfn
                        : (asid2_is_kphys) ? vpn2
                        : 0;

        assign  miss2 = (asid2_is_kphys & ~vpn2[7]) ? 1'b0
                        : (~port2_Hits_EntryA & ~port2_Hits_EntryB);

endmodule


module not_equivalent (alu1, alu2, out);
	input	[15:0]	alu1;
	input	[15:0]	alu2;
	output		out;

	assign	out = (((((alu1[0] ^ alu2[0]) |
			(alu1[1] ^ alu2[1])) |
			((alu1[2] ^ alu2[2]) |
			(alu1[3] ^ alu2[3]))) |
			(((alu1[4] ^ alu2[4]) |
			(alu1[5] ^ alu2[5])) |
			((alu1[6] ^ alu2[6]) |
			(alu1[7] ^ alu2[7])))) |
			((((alu1[8] ^ alu2[8]) |
			(alu1[9] ^ alu2[9])) |
			((alu1[10] ^ alu2[10]) |
			(alu1[11] ^ alu2[11]))) |
			(((alu1[12] ^ alu2[12]) |
			(alu1[13] ^ alu2[13])) |
			((alu1[14] ^ alu2[14]) |
			(alu1[15] ^ alu2[15])))));
endmodule

module arithmetic_logic_unit (op, alu1, alu2, bus);
	input	[2:0]	op;
	input	[15:0]	alu1;
	input	[15:0]	alu2;
	output	[15:0]	bus;

	assign bus =	(op == `ADD) ? alu1 + alu2 :
			(op == `NAND) ? ~(alu1 & alu2) :
			alu1;
endmodule


module IFID	(clk, reset, IFID_we, IFID_instr__in, IFID_pc__in, IFID_exc__in,
		IFID_instr__out, IFID_pc__out, IFID_exc__out);

	input		clk, reset, IFID_we;
	input	[15:0]	IFID_instr__in, IFID_pc__in;
	input	[6:0]	IFID_exc__in;
	output	[15:0]	IFID_instr__out, IFID_pc__out;
	output	[6:0]	IFID_exc__out;

	wire	clk_A, clk_B, clk_C, clk_D, clk_E, clk_F, clk_G, clk_H,
		res_A, res_B, res_C, res_D, res_E, res_F, res_G, res_H;

	buf	cA(clk_A, clk), cB(clk_B, clk), cC(clk_C, clk), cD(clk_D, clk),
		cE(clk_E, clk), cF(clk_F, clk), cG(clk_G, clk), cH(clk_H, clk),
		rA(res_A, reset), rB(res_B, reset), rC(res_C, reset), rD(res_D, reset),
		rE(res_E, reset), rF(res_F, reset), rG(res_G, reset), rH(res_H, reset);

	registerX #(16)		IFID_instr (.reset(res_A), .clk(clk_A), .out(IFID_instr__out), .in(IFID_instr__in), .we(IFID_we));
	registerX #(16)		IFID_pc (.reset(res_B), .clk(clk_B), .out(IFID_pc__out), .in(IFID_pc__in), .we(IFID_we));
	registerX #(7)		IFID_exc (.reset(res_C), .clk(clk_C), .out(IFID_exc__out), .in(IFID_exc__in), .we(IFID_we));

endmodule


module IDEX	(clk, reset, IDEX_op0__in, IDEX_op1__in, IDEX_op2__in, IDEX_op__in, IDEX_rT__in, IDEX_exc__in, IDEX_pc__in,
		IDEX_op0__out, IDEX_op1__out, IDEX_op2__out, IDEX_op__out, IDEX_rT__out, IDEX_exc__out, IDEX_pc__out);

	input		clk, reset;
	input	[15:0]	IDEX_op0__in, IDEX_op1__in, IDEX_op2__in;
	input	[2:0]	IDEX_op__in;
	input	[3:0]	IDEX_rT__in;
	output	[15:0]	IDEX_op0__out, IDEX_op1__out, IDEX_op2__out;
	output	[2:0]	IDEX_op__out;
	input	[3:0]	IDEX_rT__out;
	input	[15:0]	IDEX_pc__in;
	input	[6:0]	IDEX_exc__in;
	output	[15:0]	IDEX_pc__out;
	output	[6:0]	IDEX_exc__out;

	wire	clk_A, clk_B, clk_C, clk_D, clk_E, clk_F, clk_G, clk_H,
		res_A, res_B, res_C, res_D, res_E, res_F, res_G, res_H;

	buf	cA(clk_A, clk), cB(clk_B, clk), cC(clk_C, clk), cD(clk_D, clk),
		cE(clk_E, clk), cF(clk_F, clk), cG(clk_G, clk), cH(clk_H, clk),
		rA(res_A, reset), rB(res_B, reset), rC(res_C, reset), rD(res_D, reset),
		rE(res_E, reset), rF(res_F, reset), rG(res_G, reset), rH(res_H, reset);

	registerX #(16)		IDEX_op0 (.reset(res_A), .clk(clk_A), .out(IDEX_op0__out), .in(IDEX_op0__in), .we(1'd1));
	registerX #(16)		IDEX_op1 (.reset(res_B), .clk(clk_B), .out(IDEX_op1__out), .in(IDEX_op1__in), .we(1'd1));
	registerX #(16)		IDEX_op2 (.reset(res_C), .clk(clk_C), .out(IDEX_op2__out), .in(IDEX_op2__in), .we(1'd1));
	registerX #(3)		IDEX_op (.reset(res_D), .clk(clk_D), .out(IDEX_op__out), .in(IDEX_op__in), .we(1'd1));
	registerX #(4)		IDEX_rT (.reset(res_E), .clk(clk_E), .out(IDEX_rT__out), .in(IDEX_rT__in), .we(1'd1));
	registerX #(7)		IDEX_exc (.reset(res_F), .clk(clk_F), .out(IDEX_exc__out), .in(IDEX_exc__in), .we(1'd1));
	registerX #(16)		IDEX_pc (.reset(res_G), .clk(clk_G), .out(IDEX_pc__out), .in(IDEX_pc__in), .we(1'd1));

endmodule


module EXMEM	(clk, reset, EXMEM_stdata__in, EXMEM_ALUout__in, EXMEM_op__in, EXMEM_rT__in, EXMEM_exc__in, EXMEM_pc__in,
		EXMEM_stdata__out, EXMEM_ALUout__out, EXMEM_op__out, EXMEM_rT__out, EXMEM_exc__out, EXMEM_pc__out);

	input		clk, reset;
	input	[15:0]	EXMEM_stdata__in, EXMEM_ALUout__in;
	input	[2:0]	EXMEM_op__in;
	input	[3:0]	EXMEM_rT__in;
	output	[15:0]	EXMEM_stdata__out, EXMEM_ALUout__out;
	output	[2:0]	EXMEM_op__out;
	input	[3:0]	EXMEM_rT__out;
	input	[15:0]	EXMEM_pc__in;
	input	[6:0]	EXMEM_exc__in;
	output	[15:0]	EXMEM_pc__out;
	output	[6:0]	EXMEM_exc__out;

	wire	clk_A, clk_B, clk_C, clk_D, clk_E, clk_F, clk_G, clk_H,
		res_A, res_B, res_C, res_D, res_E, res_F, res_G, res_H;

	buf	cA(clk_A, clk), cB(clk_B, clk), cC(clk_C, clk), cD(clk_D, clk),
		cE(clk_E, clk), cF(clk_F, clk), cG(clk_G, clk), cH(clk_H, clk),
		rA(res_A, reset), rB(res_B, reset), rC(res_C, reset), rD(res_D, reset),
		rE(res_E, reset), rF(res_F, reset), rG(res_G, reset), rH(res_H, reset);

	registerX #(16)		EXMEM_stdata (.reset(res_A), .clk(clk_A), .out(EXMEM_stdata__out), .in(EXMEM_stdata__in), .we(1'd1));
	registerX #(16)		EXMEM_ALUout (.reset(res_B), .clk(clk_B), .out(EXMEM_ALUout__out), .in(EXMEM_ALUout__in), .we(1'd1));
	registerX #(3)		EXMEM_op (.reset(res_C), .clk(clk_C), .out(EXMEM_op__out), .in(EXMEM_op__in), .we(1'd1));
	registerX #(4)		EXMEM_rT (.reset(res_D), .clk(clk_D), .out(EXMEM_rT__out), .in(EXMEM_rT__in), .we(1'd1));
	registerX #(7)		EXMEM_exc (.reset(res_E), .clk(clk_E), .out(EXMEM_exc__out), .in(EXMEM_exc__in), .we(1'd1));
	registerX #(16)		EXMEM_pc (.reset(res_F), .clk(clk_F), .out(EXMEM_pc__out), .in(EXMEM_pc__in), .we(1'd1));

endmodule


module MEMWB	(clk, reset, MEMWB_rfdata__in, MEMWB_rT__in, MEMWB_exc__in, MEMWB_pc__in, MEMWB_ifx__in,
		MEMWB_rfdata__out, MEMWB_rT__out, MEMWB_exc__out, MEMWB_pc__out, MEMWB_ifx__out);

	input		clk, reset;
	input	[15:0]	MEMWB_rfdata__in;
	input	[3:0]	MEMWB_rT__in;
	output	[15:0]	MEMWB_rfdata__out;
	output	[3:0]	MEMWB_rT__out;
	input	[15:0]	MEMWB_pc__in;
	input	[6:0]	MEMWB_exc__in;
	input		MEMWB_ifx__in;
	output		MEMWB_ifx__out;
	output	[15:0]	MEMWB_pc__out;
	output	[6:0]	MEMWB_exc__out;

	wire	clk_A, clk_B, clk_C, clk_D, clk_E, clk_F, clk_G, clk_H,
		res_A, res_B, res_C, res_D, res_E, res_F, res_G, res_H;

	buf	cA(clk_A, clk), cB(clk_B, clk), cC(clk_C, clk), cD(clk_D, clk),
		cE(clk_E, clk), cF(clk_F, clk), cG(clk_G, clk), cH(clk_H, clk),
		rA(res_A, reset), rB(res_B, reset), rC(res_C, reset), rD(res_D, reset),
		rE(res_E, reset), rF(res_F, reset), rG(res_G, reset), rH(res_H, reset);

	registerX #(16)		MEMWB_rfdata (.reset(res_A), .clk(clk_A), .out(MEMWB_rfdata__out), .in(MEMWB_rfdata__in), .we(1'd1));
	registerX #(4)		MEMWB_rT (.reset(res_B), .clk(clk_B), .out(MEMWB_rT__out), .in(MEMWB_rT__in), .we(1'd1));
	registerX #(7)		MEMWB_exc (.reset(res_C), .clk(clk_C), .out(MEMWB_exc__out), .in(MEMWB_exc__in), .we(1'd1));
	registerX #(16)		MEMWB_pc (.reset(res_D), .clk(clk_D), .out(MEMWB_pc__out), .in(MEMWB_pc__in), .we(1'd1));
	registerX #(1)		MEMWB_ifx (.reset(res_E), .clk(clk_E), .out(MEMWB_ifx__out), .in(MEMWB_ifx__in), .we(1'd1));

endmodule






module RiSC (clk, reset);
	input	clk;
	input	reset;



	// clock tree, reset tree
	wire	clk_A, clk_B, clk_C, clk_D, clk_E, clk_F, clk_G, clk_H,
		res_A, res_B, res_C, res_D, res_E, res_F, res_G, res_H;

	buf	cA(clk_A, clk), cB(clk_B, clk), cC(clk_C, clk), cD(clk_D, clk),
		cE(clk_E, clk), cF(clk_F, clk), cG(clk_G, clk), cH(clk_H, clk),
		rA(res_A, reset), rB(res_B, reset), rC(res_C, reset), rD(res_D, reset),
		rE(res_E, reset), rF(res_F, reset), rG(res_G, reset), rH(res_H, reset);



	wire	[15:0]	PC__out;

	wire	[15:0]	IFID_instr__out;
	wire	[15:0]	IFID_pc__out;
	wire	[6:0]	IFID_exc__out;

	wire	[15:0]	IDEX_op0__out;
	wire	[15:0]	IDEX_op1__out;
	wire	[15:0]	IDEX_op2__out;
	wire	[2:0]	IDEX_op__out;
	wire	[3:0]	IDEX_rT__out;
	wire	[6:0]	IDEX_exc__out;
	wire	[15:0]	IDEX_pc__out;

	wire	[15:0]	EXMEM_stdata__out;
	wire	[15:0]	EXMEM_ALUout__out;
	wire	[2:0]	EXMEM_op__out;
	wire	[3:0]	EXMEM_rT__out;
	wire	[6:0]	EXMEM_exc__out;
	wire	[15:0]	EXMEM_pc__out;

	wire	[15:0]	MEMWB_rfdata__out;
	wire	[3:0]	MEMWB_rT__out;
	wire	[6:0]	MEMWB_exc__out;
	wire	[15:0]	MEMWB_pc__out;
	wire		MEMWB_ifx__out;



	wire	[15:0]	PC__in;

	wire	[15:0]	IFID_instr__in;
	wire	[15:0]	IFID_pc__in;
	wire	[6:0]	IFID_exc__in;

	wire	[15:0]	IDEX_op0__in;
	wire	[15:0]	IDEX_op1__in;
	wire	[15:0]	IDEX_op2__in;
	wire	[2:0]	IDEX_op__in;
	wire	[3:0]	IDEX_rT__in;
	wire	[6:0]	IDEX_exc__in;
	wire	[15:0]	IDEX_pc__in;

	wire	[15:0]	EXMEM_stdata__in;
	wire	[15:0]	EXMEM_ALUout__in;
	wire	[2:0]	EXMEM_op__in;
	wire	[3:0]	EXMEM_rT__in;
	wire	[6:0]	EXMEM_exc__in;
	wire	[15:0]	EXMEM_pc__in;

	wire	[15:0]	MEMWB_rfdata__in;
	wire	[3:0]	MEMWB_rT__in;
	wire	[6:0]	MEMWB_exc__in;
	wire	[15:0]	MEMWB_pc__in;
	wire		MEMWB_ifx__in;




	wire	[2:0]	IFID_op = IFID_instr__out[ `INSTRUCTION_OP ];
	wire	[2:0]	IFID_rA = IFID_instr__out[ `INSTRUCTION_RA ];
	wire	[2:0]	IFID_rB = IFID_instr__out[ `INSTRUCTION_RB ];
	wire	[2:0]	IFID_rC = IFID_instr__out[ `INSTRUCTION_RC ];
	wire	[6:0]	IFID_im = IFID_instr__out[ `INSTRUCTION_IM ];
	wire		IFID_sb = IFID_instr__out[ `INSTRUCTION_SB ];

	wire	[15:0]	IFID_simm = { {9{IFID_sb}}, IFID_im };
	wire	[15:0]	IFID_uimm = { IFID_instr__out[ `INSTRUCTION_LI ], 6'd0 };



	wire	[15:0]	PC__out_plus1 = PC__out+1;				// dedicated adder
	wire	[15:0]	IFID_pc_plus1 = IFID_pc__out+1;				// dedicated adder
	wire	[15:0]	IFID_pc_plus_signext_plus1 = IFID_pc_plus1+IFID_simm;	// dedicated adder



	wire		PC_we;
	wire		IFID_we;

	wire	[15:0]	MUXpc_out;
	wire	[2:0]	MUXs2_out;
	wire		Pstall;
	wire		Pstomp;
	wire	[15:0]	MUXimm_out;	
	wire	[15:0]	MUXop2_out;
	wire	[15:0]	MUXop1_out;
	wire	[15:0]	MUXalu2_out;
	wire	[15:0]	MUXalu1_out;
	wire	[15:0]	MUXrfe_out;

	wire	[2:0]	FUNCalu = ((IDEX_op__out == `ADDI) || (IDEX_op__out == `SW) || (IDEX_op__out == `LW))
				? `ADD
				: IDEX_op__out;

	wire		WEdmem;
	wire	[15:0]	MUXout_out;

	wire	[15:0]	ALU_out;

	//
	//
	// ****************************************************************
	//
	// note change: RF__src1, RF__src2, and RF__tgt are four-bit busses
	//              and there is now a bus for the PSR coming out of RF
	//
	// ****************************************************************
	//
	//
	wire	[15:0]	RF__out1;
	wire	[3:0]	RF__src1;
	wire	[15:0]	RF__out2;
	wire	[3:0]	RF__src2;
	wire	[15:0]	RF__in1;
	wire	[3:0]	RF__tgt1;
	wire	[15:0]	RF__in2;
	wire	[3:0]	RF__tgt2;
	wire	[15:0]	PSR__in;
	wire	[15:0]	PSR__out;
	wire	[15:0]	MEM__data1;
	wire	[15:0]	MEM__addr1;
	wire	[15:0]	MEM__data2out;
	wire	[15:0]	MEM__addr2;

	wire		kmode = PSR__out[ `PSR_KMODE ];
	wire	[5:0]	asid = PSR__out[ `PSR_ASID ];
	wire		PSR__we;




	//
	// TLB wires
	//
	wire	[7:0]	TLB_vpn1__in;
	wire	[5:0]	TLB_asid1__in;
	wire	[7:0]	TLB_pfn1__out;
	wire		TLB_miss1__out;

	wire	[7:0]	TLB_vpn2__in;
	wire	[5:0]	TLB_asid2__in;
	wire	[7:0]	TLB_pfn2__out;
	wire		TLB_miss2__out;

	wire	[7:0]	TLB_map2__in;
	wire		TLB_write__in;



	wire	rfe_in_WB =		(MEMWB_exc__out == `RFE_JUMP);
	wire	exception_in_WB =	(MEMWB_exc__out != `MODE_RUN);
	wire	x = exception_in_WB;	// shorthand for the above



	//
	// PC UPDATE
	//
	wire		not_equal;
	wire		ifid_is_bne = (IFID_op == `BNE);
	wire		ifid_is_jalr = (IFID_op == `JALR && IFID_im == 7'd0);
	wire		ifid_is_extend = (IFID_op == `JALR && IFID_im != 7'd0);
	wire		takenBranch = (ifid_is_bne & not_equal);

	not_equivalent		NEQ (.alu1(MUXop1_out), .alu2(MUXop2_out), .out(not_equal));

	assign 	MUXpc_out =	(ifid_is_jalr) ? MUXop1_out :
				(takenBranch) ? IFID_pc_plus_signext_plus1 :
				(rfe_in_WB) ? MEMWB_pc__out : //exceptional pc will be handled in execute stage
				(exception_in_WB) ? MEM__data2out : //latch from IVT //mem data 2 out
				PC__out_plus1;

	assign 	PC__in =	MUXpc_out;
	assign	PC_we = 	~Pstall | exception_in_WB;

	registerX #(16)		PC (.reset(res_A), .clk(clk_A), .out(PC__out), .in(PC__in), .we(PC_we));





	//
	// FETCH STAGE
	//
    //debug
	assign	MEM__addr1 = (TLB_pfn1__out << 8) + PC__out[`BYTE_BOT];
	assign	IFID_instr__in = 	(Pstomp) ? `ZERO : MEM__data1;
	assign	IFID_pc__in = 		(Pstomp) ? `ZERO : PC__out;
	assign  IFID_exc__in =          (Pstomp) ? 7'd0 
					: (TLB_miss1__out) ? (kmode ? `EXC_TLBKMISS : `EXC_TLBUMISS)
					: 7'd0;
	assign	IFID_we =		(~Pstall | x); //or exception in writeback



    //debug
	assign	TLB_vpn1__in =		PC__out[`BYTE_TOP]; 
	assign	TLB_asid1__in =		(kmode) ? 6'd0 : asid; 

	IFID	ifid_reg (.reset(res_B), .clk(clk_B), .IFID_instr__in(IFID_instr__in), .IFID_pc__in(IFID_pc__in),
			.IFID_exc__in(IFID_exc__in), .IFID_exc__out(IFID_exc__out),
			.IFID_we(IFID_we), .IFID_instr__out(IFID_instr__out), .IFID_pc__out(IFID_pc__out));

	tlb	TLB	(.reset(res_H), .clk(clk_H), 
			.vpn1(TLB_vpn1__in), .asid1(TLB_asid1__in), .pfn1(TLB_pfn1__out), .miss1(TLB_miss1__out), 
			.vpn2(TLB_vpn2__in), .asid2(TLB_asid2__in), .pfn2(TLB_pfn2__out), .miss2(TLB_miss2__out),
					.map2(TLB_map2__in), .write(TLB_write__in));


	//
	// DECODE STAGE
	//
	wire		s1nonzero = (RF__src1[2:0] != 3'd0);
	wire		s2nonzero = (RF__src2[2:0] != 3'd0);
	wire		ifid_is_addORnand = (IFID_op == `ADD) | (IFID_op == `NAND);
	wire		idex_is_lw = (IDEX_op__out == `LW);
	wire		idex_targets_src1 = ((IDEX_rT__out == RF__src1) & s1nonzero);
	wire		idex_targets_src2 = ((IDEX_rT__out == RF__src2) & s2nonzero);
	wire		exmem_targets_src1 = ((EXMEM_rT__out == RF__src1) & s1nonzero);
	wire		exmem_targets_src2 = ((EXMEM_rT__out == RF__src2) & s2nonzero);
	wire		memwb_targets_src1 = ((MEMWB_rT__out == RF__src1) & s1nonzero);
	wire		memwb_targets_src2 = ((MEMWB_rT__out == RF__src2) & s2nonzero);
	wire		ifid_is_lui = (IFID_op == `LUI);
	wire		ifid_uses_simm = (IFID_op == `ADDI) | (IFID_op == `LW) | (IFID_op == `SW);
	wire		ifid_writesRF =	(~IFID_op[2] | IFID_op[0])	// not a BEQ or SW
					& ((IFID_op != `JALR) | IFID_im == `MODE_RUN);	// extendable ... 

	control_and_general_regfile	RF (.reset(res_C), .clk(clk_C), .abus1(RF__src1), .dbus1(RF__out1),
					.abus2(RF__src2), .dbus2(RF__out2), .abus3(RF__tgt1), .dbus3(RF__in1),
					.abus4(RF__tgt2), .dbus4(RF__in2), .psr_in(PSR__in), .psr_out(PSR__out),
					.psr_we(PSR__we));


	wire	[2:0]	CTL6_out_op =	(Pstall | x) ? `ADD : IFID_op;
	wire	[3:0]	CTL6_out_rT =	(Pstall | ~ifid_writesRF | x) ? {kmode, 3'd0} : {kmode, IFID_rA};

	// this implementation does not check permissions ... if you want a secure implementation, 
	// need to make sure the operation is allowable (via kmode bit)
	wire	[6:0]	CTL6_out_exc =	(Pstall | x) ? 7'd0 : 
					(IFID_op == `EXTEND ? IFID_im : IFID_exc__out);

	assign	Pstall =	(idex_is_lw & (idex_targets_src1 | idex_targets_src2));

	assign	Pstomp =	(ifid_is_jalr | takenBranch) | x;

	assign	RF__src1 =	{kmode, IFID_rB};
	assign	RF__src2 =	{kmode, MUXs2_out};

	assign	MUXs2_out =	(ifid_is_addORnand) ? IFID_rC : IFID_rA;

	assign	MUXimm_out =	(ifid_is_lui) ? IFID_uimm :
				(ifid_uses_simm) ? IFID_simm :
				IFID_pc_plus1;

	assign	MUXop1_out =	(idex_targets_src1) ? ALU_out :
				(exmem_targets_src1) ? MUXout_out :
				(memwb_targets_src1) ? MEMWB_rfdata__out :
				RF__out1;

	assign	MUXop2_out =	(idex_targets_src2) ? ALU_out :
				(exmem_targets_src2) ? MUXout_out :
				(memwb_targets_src2) ? MEMWB_rfdata__out :
				RF__out2;

	assign	IDEX_op__in =	CTL6_out_op;
	assign	IDEX_rT__in =	CTL6_out_rT;
	assign	IDEX_op0__in =	MUXimm_out;
	assign	IDEX_op1__in =	(ifid_is_jalr) ? MUXimm_out : MUXop1_out;
	assign	IDEX_op2__in =	(ifid_is_jalr) ? MUXimm_out : MUXop2_out;

	assign	IDEX_exc__in =	CTL6_out_exc;
	assign	IDEX_pc__in =	IFID_pc__out;

	IDEX	idex_reg(.reset(res_D), .clk(clk_D), .IDEX_op0__in(IDEX_op0__in), .IDEX_op1__in(IDEX_op1__in), 
			.IDEX_op2__in(IDEX_op2__in), .IDEX_op__in(IDEX_op__in), .IDEX_rT__in(IDEX_rT__in), 
			.IDEX_pc__in(IDEX_pc__in), .IDEX_exc__in(IDEX_exc__in),
			.IDEX_pc__out(IDEX_pc__out), .IDEX_exc__out(IDEX_exc__out),
			.IDEX_op0__out(IDEX_op0__out), .IDEX_op1__out(IDEX_op1__out), .IDEX_op2__out(IDEX_op2__out),
			.IDEX_op__out(IDEX_op__out), .IDEX_rT__out(IDEX_rT__out));




	//
	// EXECUTE STAGE
	//
	wire		idex_is_addORnand = (IDEX_op__out == `ADD) | (IDEX_op__out == `NAND);
	wire		idex_is_lui = (IDEX_op__out == `LUI);
	wire		idex_is_tlbw = (IDEX_exc__out == `TLB_WRITE);
	wire		idex_is_rfe = (IDEX_exc__out == `RFE_JUMP);

	assign	MUXalu1_out = 	(idex_is_lui) ? IDEX_op0__out : IDEX_op1__out; //(idex_is_tlbw) ? IDEX_op2__out : 
	assign	MUXalu2_out = 	(idex_is_addORnand) ? IDEX_op2__out : IDEX_op0__out;

	assign	MUXrfe_out = 	(idex_is_rfe) ? IDEX_op1__out : IDEX_pc__out;
	//implement this

	assign	EXMEM_op__in = 		(x) ? 0 : IDEX_op__out;
	assign	EXMEM_rT__in = 		(x) ? 0 : IDEX_rT__out;
	assign	EXMEM_pc__in = 		(x) ? 0 : MUXrfe_out;
	assign	EXMEM_exc__in = 	IDEX_exc__out;
	assign	EXMEM_stdata__in = 	IDEX_op2__out; 
	assign	EXMEM_ALUout__in = 	ALU_out;

	arithmetic_logic_unit	ALU (.op(FUNCalu), .alu1(MUXalu1_out), .alu2(MUXalu2_out), .bus(ALU_out));

	EXMEM	exmem_reg(.reset(res_E|x), .clk(clk_E), .EXMEM_stdata__in(EXMEM_stdata__in), .EXMEM_ALUout__in(EXMEM_ALUout__in),
			.EXMEM_op__in(EXMEM_op__in), .EXMEM_rT__in(EXMEM_rT__in), .EXMEM_stdata__out(EXMEM_stdata__out),
			.EXMEM_pc__in(EXMEM_pc__in), .EXMEM_exc__in(EXMEM_exc__in),
			.EXMEM_pc__out(EXMEM_pc__out), .EXMEM_exc__out(EXMEM_exc__out),
			.EXMEM_ALUout__out(EXMEM_ALUout__out), .EXMEM_op__out(EXMEM_op__out), .EXMEM_rT__out(EXMEM_rT__out));



	//
	// MEMORY STAGE
	//
	wire		exmem_is_lw = (EXMEM_op__out == `LW);
	wire		exmem_is_sw = (EXMEM_op__out == `SW);
	wire		exmem_is_tlbw = (EXMEM_exc__out == `TLB_WRITE);
	wire		exmem_is_tlb_umiss =	(EXMEM_exc__out == `EXC_TLBUMISS);
	wire		exmem_is_tlb_kmiss =	(EXMEM_exc__out == `EXC_TLBKMISS);

	wire	[15:0]	MEM__data2in;
    //To_do
	
	assign	TLB_write__in =		exmem_is_tlbw & ~x;
	assign	TLB_map2__in =		EXMEM_stdata__out[`BYTE_BOT];
	assign	TLB_vpn2__in = 		(exmem_is_tlbw) ? EXMEM_ALUout__out[`BYTE_BOT]
	                           : EXMEM_ALUout__out[`BYTE_TOP];
	assign	TLB_asid2__in =		(exmem_is_tlbw) ? EXMEM_ALUout__out[13:8] 
	                           : asid; 

	assign	MEM__addr2 =	   x
					? {9'd0, MEMWB_exc__out}
					: {TLB_pfn2__out, EXMEM_ALUout__out[`BYTE_BOT]};

	assign	MEM__data2in =		EXMEM_stdata__out;
	assign	WEdmem =		exmem_is_sw & ~exception_in_WB;

	// pretty horrifically complex, so i'll give it to you ...
        assign  MUXout_out =            (exception_in_WB) ? MEM__data2out
                                        : (exmem_is_lw & TLB_miss2__out) ? EXMEM_ALUout__out
                                        : (exmem_is_lw) ? MEM__data2out
                                        : EXMEM_ALUout__out;


	assign	MEMWB_rT__in =		EXMEM_rT__out;
	assign	MEMWB_pc__in =		EXMEM_pc__out;
	assign	MEMWB_exc__in =		(TLB_miss2__out & (exmem_is_lw | exmem_is_sw))
	                         ? ((kmode) ? `EXC_TLBKMISS : `EXC_TLBUMISS)
	                         : (exmem_is_tlbw) ? 7'd0 : EXMEM_exc__out;
	assign	MEMWB_rfdata__in =	MUXout_out;
	assign	MEMWB_ifx__in =		(exmem_is_tlb_umiss | exmem_is_tlb_kmiss);	// i'll give this to you ...

	three_port_aram		MEM (.clk(clk_F), .abus1(MEM__addr1), .dbus1(MEM__data1), .abus2(MEM__addr2),
				.dbus2o(MEM__data2out), .dbus2i(MEM__data2in), .we(WEdmem));

	MEMWB	memwb_reg(.reset(res_G|x), .clk(clk_G), .MEMWB_rfdata__in(MEMWB_rfdata__in), .MEMWB_rT__in(MEMWB_rT__in),
			.MEMWB_pc__in(MEMWB_pc__in), .MEMWB_exc__in(MEMWB_exc__in), .MEMWB_ifx__in(MEMWB_ifx__in),
			.MEMWB_pc__out(MEMWB_pc__out), .MEMWB_exc__out(MEMWB_exc__out), .MEMWB_ifx__out(MEMWB_ifx__out),
			.MEMWB_rfdata__out(MEMWB_rfdata__out), .MEMWB_rT__out(MEMWB_rT__out));




	//
	// WRITEBACK STAGE
	//
	wire	memwb_is_tlb_umiss =	(MEMWB_exc__out == `EXC_TLBUMISS);
	wire	memwb_is_tlb_kmiss =	(MEMWB_exc__out == `EXC_TLBKMISS);
	wire	tlbmiss =		(memwb_is_tlb_umiss | memwb_is_tlb_kmiss);

	assign	RF__tgt1 = 	~exception_in_WB	? MEMWB_rT__out 
							: 4'b1111;
	assign	RF__in1 = 	~exception_in_WB	? MEMWB_rfdata__out
							: (tlbmiss	? MEMWB_pc__out
									: MEMWB_pc__out + 1);
					
	assign	RF__tgt2 = 	tlbmiss ? 4'b1011 : 4'd0;	
	assign	RF__in2 = 	memwb_is_tlb_umiss
					? (MEMWB_ifx__out
						? { 2'b11, asid, MEMWB_pc__out[ `BYTE_TOP ] }
						: { 2'b11, asid, MEMWB_rfdata__out[ `BYTE_TOP ] }) 
					: (MEMWB_ifx__out
						? { 8'd0, MEMWB_pc__out[ `BYTE_TOP ] }
						: { 8'd0, MEMWB_rfdata__out[ `BYTE_TOP ] });

	assign	PSR__we =	x;
	assign	PSR__in =	(MEMWB_exc__out == `RFE_JUMP)
				? {1'd0, (PSR__out[`BYTE_TOP]), 1'b0, asid}
				: {PSR__out[14:7], 1'b1, 1'b0, asid};



	always @(posedge clk) begin
		$display("------------- (time %h)", $time);
		$display("regs    %h %h %h %h %h %h %h",
			RF.m[1], RF.m[2], RF.m[3], RF.m[4], RF.m[5], RF.m[6], RF.m[7]);
		$display("ctl:    %h %h %h %h %h %h %h",
			RF.cr[1], RF.cr[2], RF.cr[3], PSR__out, RF.cr[5], RF.cr[6], RF.cr[7]);
		$display("-Fetch  PC=%h", PC__out);
		$display(" tlb1   asid=%h vpn=%h - pfn=%h miss=%h",
			TLB_asid1__in, TLB_vpn1__in, TLB_pfn1__out, TLB_miss1__out);
		$display(" mem1   a1=%h d1out=%h", MEM.abus1, MEM.dbus1);
		$display("-Decode IFID_instr=%h (op=%h rA=%h rB=%h rC=%h imm=%d) IFID_pc=%h IFID_exc=%h",
			IFID_instr__out, IFID_op, IFID_rA, IFID_rB, IFID_rC, IFID_im, IFID_pc__out, IFID_exc__out);
		$display("-Exec   IDEX_op0=%h IDEX_op1=%h IDEX_op2=%h IDEX_op=%h IDEX_rT=%o IDEX_pc=%h IDEX_exc=%h",
			IDEX_op0__out, IDEX_op1__out, IDEX_op2__out, IDEX_op__out, IDEX_rT__out, IDEX_pc__out, IDEX_exc__out);
		$display(" ALU    func=%d alu1=%h alu2=%h muxrfe=%h",
			FUNCalu, MUXalu1_out, MUXalu2_out, MUXrfe_out);
		$display("ALU_out: %h", ALU_out);
		$display("-Memory EXMEM_stdata=%h EXMEM_ALUout=%h EXMEM_op=%h EXMEM_rT=%o EXMEM_pc=%h EXMEM_exc=%h",
			EXMEM_stdata__out, EXMEM_ALUout__out, EXMEM_op__out, EXMEM_rT__out, EXMEM_pc__out, EXMEM_exc__out);
		$display(" tlb2   asid=%h vpn=%h - pfn=%h miss=%h   map=%h tlb_we=%h",
			TLB_asid2__in, TLB_vpn2__in, TLB_pfn2__out, TLB_miss2__out, TLB_map2__in, TLB_write__in);
		$display(" mem2   a2=%h d2out=%h    we=%d d2in=%h",
			MEM.abus2, MEM.dbus2o, MEM.we, MEM.dbus2i);
		$display("-Write  MEMWB_rfdata=%h MEMWB_rT=%o MEMWB_pc=%h MEMWB_exc=%h MEMWB_ifx=%h",
			MEMWB_rfdata__out, MEMWB_rT__out, MEMWB_pc__out, MEMWB_exc__out, MEMWB_ifx__out);
		$display("etc.    Pstall=%h Pstomp=%h",
			Pstall, Pstomp);
		$display("MUXpc   is_jalr=%d is_bne=%d is_rfe=%d is_exc=%d",
			ifid_is_jalr, takenBranch, rfe_in_WB, exception_in_WB);
		$display("TLB-A   v=%d asid=%d vpn=%h pfn=%h", 
			TLB.tlbA_v, TLB.tlbA_asid, TLB.tlbA_vpn, TLB.tlbA_pfn);
		$display("TLB-B   v=%d asid=%d vpn=%h pfn=%h", 
			TLB.tlbB_v, TLB.tlbB_asid, TLB.tlbB_vpn, TLB.tlbB_pfn);

		if (MEMWB_exc__out == `MODE_HALT) $finish;
	end
endmodule

