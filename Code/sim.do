#Commands to set up Modelsim environment
add wave -radix binary {sim:/mother_tb/clk }

add wave -radix unsigned {sim:/mother_tb/uut/cpu_con/pc }

add wave -radix decimal {sim:/mother_tb/uut/cpu_con/pc_jmp } 

add wave -radix hexadecimal -group InstrReg \
{sim:/mother_tb/uut/cpu_con/instr_reg0 } \
{sim:/mother_tb/uut/cpu_con/instr_reg1 } \
{sim:/mother_tb/uut/cpu_con/instr_reg2 } \
{sim:/mother_tb/uut/cpu_con/instr_reg3 }

add wave -radix binary -group flags \
{sim:/mother_tb/uut/cpu_con/z } \
{sim:/mother_tb/uut/cpu_con/n } \
{sim:/mother_tb/uut/cpu_con/o }

add wave -radix decimal \
{sim:/mother_tb/uut/cpu_con/pre_alu_a } \
{sim:/mother_tb/uut/cpu_con/pre_alu_b } 

add wave -radix decimal \
{sim:/mother_tb/uut/cpu_con/alu_res_reg } 

add wave -radix decimal \
{sim:/mother_tb/uut/cpu_con/pre_dmem } \
{sim:/mother_tb/uut/cpu_con/post_dmem } 

add wave -radix decimal \
{sim:/mother_tb/uut/cpu_con/pre_vmem } \
{sim:/mother_tb/uut/cpu_con/post_vmem } 

add wave -radix decimal \
{sim:/mother_tb/uut/cpu_con/c2/registers } 

add wave -radix decimal \
{sim:/mother_tb/uut/cpu_con/regfile_read1 } \
{sim:/mother_tb/uut/cpu_con/regfile_read2 } 

add wave -radix decimal \
{sim:/mother_tb/uut/cpu_con/regfile_wreg } \
{sim:/mother_tb/uut/cpu_con/regfile_wdata }

add wave -radix binary \
{sim:/mother_tb/uut/cpu_con/regfile_wenable } 
 
