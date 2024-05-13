module SP(
	// INPUT SIGNAL
	clk,
	rst_n,
	in_valid,
	inst,
	mem_dout,
	// OUTPUT SIGNAL
	out_valid,
	inst_addr,
	mem_wen,
	mem_addr,
	mem_din
);

//------------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//------------------------------------------------------------------------

input                    clk, rst_n, in_valid;
input             [31:0] inst;
input  signed     [31:0] mem_dout;
output reg               out_valid;
output reg        [31:0] inst_addr;
output reg               mem_wen;
output reg        [11:0] mem_addr;
output reg signed [31:0] mem_din;

//------------------------------------------------------------------------
//   DECLARATION
//------------------------------------------------------------------------
reg  [31:0] inst_r, inst_w;
wire [ 5:0] opcode;
wire [ 4:0] rs;
wire [ 4:0] rt;
wire [ 4:0] rd;
wire [ 4:0] shamt;
wire [ 5:0] funct;
wire [15:0] imm;
assign opcode = inst_r[31:26];
assign rs 	  = inst_r[25:21];
assign rt     = inst_r[20:16];
assign rd     = inst_r[15:11];
assign shamt  = inst_r[10:6];
assign funct  = inst_r[5:0];
assign imm    = inst_r[15:0];

reg [31:0] PC;
// Register file
// REGISTER FILE, DO NOT EDIT THE NAME.
reg	 signed [31:0] r [0:31]; 
reg   	    [ 4:0] ra1;
wire signed [31:0] rd1;
reg   	    [ 4:0] ra2;
wire signed [31:0] rd2;
reg   	    [ 4:0] wa;
reg  signed [31:0] wd;
reg                en_write;
integer i;
//------------------------------------------------------------------------
//   DESIGN
//------------------------------------------------------------------------
// Main FSM
parameter S_IDLE   = 0;
parameter S_AND    = 1;
parameter S_OR     = 2;
parameter S_ADD    = 3;
parameter S_SUB    = 4;
parameter S_SLT    = 5;
parameter S_SLL    = 6;
parameter S_NOR    = 7;
parameter S_ANDI   = 8;
parameter S_ORI    = 9;
parameter S_ADDI   = 10;
parameter S_SUBI   = 11;
parameter S_LW     = 12;
parameter S_LWWAIT = 13;
parameter S_SW     = 14;
parameter S_SWWAIT = 15;
parameter S_BEQ    = 16;
parameter S_BNE    = 17;
parameter S_LUI    = 18;
parameter S_OUTPUT = 19;
reg [5:0] state_typ_w, state_typ_r;

always@(*) begin
	case (state_typ_r)
		S_IDLE: begin
			if(!rst_n) begin
				inst_addr = 0;
				for ( i=0; i<32; i=i+1) begin
					r[i] = 0;
				end
				mem_wen = 0;
			end else begin
				mem_wen  = 1;
			end
			mem_addr = 0;
			mem_din = 0;
			out_valid = 0;
			if (in_valid) begin
				PC = inst_addr;
				inst_w = inst;
				ra1 = inst[25:21];
				ra2 = inst[20:16];
				case (inst[31:26])
					0:begin  // R type
						case (inst[5:0])
							0: begin 
								state_typ_w = S_AND;
							end
							1: begin 
								state_typ_w = S_OR;
							end
							2: begin 
								state_typ_w = S_ADD;
							end
							3: begin 
								state_typ_w = S_SUB;
							end
							4: begin 
								state_typ_w = S_SLT;
							end
							5: begin 
								state_typ_w = S_SLL;
							end
							6: begin 
								state_typ_w = S_NOR;
							end
							default: begin
								state_typ_w = state_typ_r;
							end
						endcase
					end
					1: begin
						state_typ_w = S_ANDI;
					end
					2: begin
						state_typ_w = S_ORI;
					end
					3: begin
						state_typ_w = S_ADDI;
					end
					4: begin
						state_typ_w = S_SUBI;
					end
					5: begin
						state_typ_w = S_LW;
					end
					6: begin
						state_typ_w = S_SW;
					end
					7: begin
						state_typ_w = S_BEQ;
					end
					8: begin
						state_typ_w = S_BNE;
					end
					9: begin
						state_typ_w = S_LUI;
					end
					default: begin
						state_typ_w = state_typ_r;
					end
				endcase
			end else begin
				inst_w = inst_r;
				state_typ_w = state_typ_r;
			end
		end

		// R type
		S_AND: begin
			wa = rd;
			wd = rd1 & rd2;
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_OR: begin
			wa = rd;
			wd = rd1 | rd2;
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_ADD: begin
			wa = rd;
			wd = $signed(rd1 + rd2);
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_SUB: begin
			wa = rd;
			wd = $signed(rd1 - rd2);
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_SLT: begin
			wa = rd;
			if (rd1 < rd2) begin
				wd = 1;
			end else begin
				wd = 0;
			end
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_SLL: begin
			wa = rd;
			wd = rd1 << shamt;
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_NOR: begin
			wa = rd;
			wd = ~(rd1 | rd2);
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end

		// I type
		S_ANDI: begin
			wa = rt;
			wd = rd1 & {16'b0, imm};
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_ORI: begin
			wa = rt;
			wd = rd1 | {16'b0, imm};
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_ADDI: begin
			wa = rt;
			wd = $signed(rd1 + {{16{imm[15]}}, imm});
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_SUBI: begin
			wa = rt;
			wd = $signed(rd1 - {{16{imm[15]}}, imm});
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_LW: begin
			mem_wen  = 1;
			mem_addr = rd1 + {{16{imm[15]}}, imm};
			en_write = 0;
			state_typ_w = S_LWWAIT;
		end
		S_LWWAIT: begin
			wa = rt;
			wd = mem_dout;
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_SW: begin
			mem_wen  = 0;
			mem_addr = rd1 + {{16{imm[15]}}, imm};
			mem_din  = rd2;
			en_write = 0;
			state_typ_w = S_SWWAIT;
		end
		S_SWWAIT: begin
			mem_wen   = 1;
			// mem_addr = rd1 + {{16{imm[15]}}, imm};
			// mem_din  = rd2;
			en_write  = 0;
			state_typ_w = S_OUTPUT;
		end
		S_BEQ: begin
			if (rd1 == rd2) begin
				PC = inst_addr + {{14{imm[15]}}, imm, 2'b0};
			end
			state_typ_w = S_OUTPUT;
		end
		S_BNE: begin
			if (rd1 != rd2) begin
				PC = inst_addr + {{14{imm[15]}}, imm, 2'b0};
			end
			state_typ_w = S_OUTPUT;
		end
		S_LUI: begin
			wa = rt;
			wd = {imm, 16'b0};
			en_write = 1;
			state_typ_w = S_OUTPUT;
		end
		S_OUTPUT: begin
			mem_wen   = 1;
			mem_addr  = 0;
			mem_din   = 0;
			en_write  = 0;
			out_valid = 1;
			inst_addr = PC + 4;
			state_typ_w = S_IDLE;
		end
		default: begin
			state_typ_w = state_typ_r;
		end
	endcase
	
end

assign rd1 = r[ra1];
assign rd2 = r[ra2];
always@(posedge clk or negedge rst_n) begin
	if (en_write) begin
		r[wa] <= wd;
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		inst_r       <= 0;
		state_typ_r  <= S_IDLE;
    end else begin
		inst_r       <= inst_w;
		state_typ_r  <= state_typ_w;
    end
end
endmodule