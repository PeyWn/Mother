#Commands to set up Modelsim environment
add wave -radix binary {sim:/mother_tb/clk }

add wave -radix unsigned {sim:/mother_tb/uut/c1/pc }

add wave -radix decimal {sim:/mother_tb/uut/c1/pc_jmp } 

add wave -radix hexadecimal -group InstrReg \
{sim:/mother_tb/uut/c1/instr_reg0 } \
{sim:/mother_tb/uut/c1/instr_reg1 } \
{sim:/mother_tb/uut/c1/instr_reg2 } \
{sim:/mother_tb/uut/c1/instr_reg3 }

add wave -radix binary -group flags \
{sim:/mother_tb/uut/c1/z } \
{sim:/mother_tb/uut/c1/n } \
{sim:/mother_tb/uut/c1/o }

add wave -radix decimal \
{sim:/mother_tb/uut/c1/pre_alu_a } \
{sim:/mother_tb/uut/c1/pre_alu_b } 

add wave -radix decimal \
{sim:/mother_tb/uut/c1/alu_res_reg } 

add wave -radix decimal \
{sim:/mother_tb/uut/c1/pre_dmem } \
{sim:/mother_tb/uut/c1/post_dmem } 

add wave -radix decimal \
{sim:/mother_tb/uut/c1/pre_vmem } \
{sim:/mother_tb/uut/c1/post_vmem } 

add wave -radix decimal \
{sim:/mother_tb/uut/c1/c2/registers } 

add wave -radix decimal \
{sim:/mother_tb/uut/c1/regfile_read1 } \
{sim:/mother_tb/uut/c1/regfile_read2 } 

add wave -radix decimal \
{sim:/mother_tb/uut/c1/regfile_wreg } \
{sim:/mother_tb/uut/c1/regfile_wdata }

add wave -radix binary \
{sim:/mother_tb/uut/c1/regfile_wenable } 
 
