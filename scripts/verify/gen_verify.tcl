set_param general.MaxThreads 12
open_project ../../vivado/i-2DDCT.xpr
# Update top_level tesbench
update_compile_order -fileset sources_1
set_property -name {xsim.simulate.runtime} -value {0us} -objects [get_filesets TOP_LEVEL_sim]
set fp [open .gen_verify_tcl_results.txt w]
launch_simulation -simset [get_filesets TOP_LEVEL_sim ]
set a "234,-23,-12,-8,-1,1,-2,-3,-3,-18,-10,-3,-1,-1,-1,1,-14,-7,-2,0,1,1,-1,-4,-7,-4,1,1,1,-1,-2,-2,0,-3,0,1,-1,-1,0,2,-4,0,-2,-1,-1,1,1,1,-4,0,-1,-1,0,1,0,-1,-1,-2,-1,0,1,-2,-2,-1,376,22,0,27,0,40,0,115,60,73,0,-75,0,-32,0,-182,261,244,0,-40,0,103,0,108,82,31,0,-53,0,-34,0,-148,-384,-208,0,108,0,-14,0,162,424,-315,0,82,0,-102,0,-33,304,-76,0,45,0,1,0,79,-44,62,0,-32,0,4,0,-46,162,-83,-234,-24,-118,0,-58,-82,-124,-4,-52,-33,-59,-34,-66,93,52,130,-45,141,14,101,19,-29,-84,-8,6,-16,-31,-18,-36,23,13,25,20,5,19,17,4,13,131,-78,-165,-1,-20,62,54,-219,114,-71,-73,0,9,38,53,-176,-31,-2,31,-29,-8,-24,-7,45,-336,-20,-10,-5,-1,2,6,-5,53,19,10,-32,-3,-3,45,-55,-13,-6,0,0,-4,-2,0,3,51,37,22,-31,1,-7,58,-69,-4,-6,-4,-1,3,-1,1,-4,80,61,31,-49,-3,-14,87,-94,-5,-3,-6,-9,1,-2,7,-7,258,176,90,-142,1,-26,245,-286,234,-23,-12,-8,-1,1,-2,-3,-3,-18,-10,-3,-1,-1,-1,1,-14,-7,-2,0,1,1,-1,-4,-7,-4,1,1,1,-1,-2,-2,0,-3,0,1,-1,-1,0,2,-4,0,-2,-1,-1,1,1,1,-4,0,-1,-1,0,1,0,-1,-1,-2,-1,0,1,-2,-2,-1,376,22,0,27,0,40,0,115,60,73,0,-75,0,-32,0,-182,261,244,0,-40,0,103,0,108,82,31,0,-53,0,-34,0,-148,-384,-208,0,108,0,-14,0,162,424,-315,0,82,0,-102,0,-33,304,-76,0,45,0,1,0,79,-44,62,0,-32,0,4,0,-46,162,-83,-234,-24,-118,0,-58,-82,-124,-4,-52,-33,-59,-34,-66,93,52,130,-45,141,14,101,19,-29,-84,-8,6,-16,-31,-18,-36,23,13,25,20,5,19,17,4,13,131,-78,-165,-1,-20,62,54,-219,114,-71,-73,0,9,38,53,-176,-31,-2,31,-29,-8,-24,-7,45,-336,-20,-10,-5,-1,2,6,-5,53,19,10,-32,-3,-3,45,-55,-13,-6,0,0,-4,-2,0,3,51,37,22,-31,1,-7,58,-69,-4,-6,-4,-1,3,-1,1,-4,80,61,31,-49,-3,-14,87,-94,-5,-3,-6,-9,1,-2,7,-7,258,176,90,-142,1,-26,245,-286,-101010"
puts $fp "vtrace_delay;input_started_time;input_finished_time;output_finished_time;vtrace_rom_raddr;dct2d_cnt;halt_time;2ddct_correct;2ddct_data;"
# Simulation start
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 0
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 1
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 2
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 3
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 4
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 5
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 6
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 7
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 8
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 9
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 10
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 11
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 12
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 13
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 14
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 15
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 16
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 17
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 18
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 19
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 20
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 21
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 22
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 23
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 24
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 25
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 26
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 27
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 28
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 29
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 30
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 31
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 32
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 33
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 34
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 35
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 36
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 37
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 38
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 39
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 40
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 41
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 42
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 43
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 44
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 45
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 46
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 47
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 48
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 49
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 50
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 51
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 52
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 53
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 54
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 55
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 56
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 57
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 58
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 59
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 60
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 61
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 62
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 63
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
add_force -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d 64
run 22 us
puts $fp "[get_value -radix unsigned /TOP_LEVEL_TB/c_start_input_send_wait_clk_d];[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time];[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time];[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr];[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt];[get_value -radix unsigned /TOP_LEVEL_TB/halt_time];[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]];[get_value -radix dec /TOP_LEVEL_TB/dct2d_data];"
remove_forces -all
restart
# Simulation end
