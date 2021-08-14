# launch this script on DCT1S_TB in GUI with:
# source ./path/to/script
restart
run 50 us

set databuf_path "/DCT1S_TB/U_DCT1S/databuf_reg"
set gen_cnt_path "/DCT1S_TB/P_DCT_DATA_GEN/process_cnt"
set row_cnt_path "/DCT1S_TB/U_DCT1S/row_cnt"
set stage2_start_path "/DCT1S_TB/U_DCT1S/stage2_start"

## get a string rapresentation of:
set databuf [get_value -radix unsigned $databuf_path]
set tb_data_gen_cnt [get_value -radix unsigned $gen_cnt_path]
set row_cnt [get_value -radix unsigned $row_cnt_path]

set num_of_cycles [expr {($tb_data_gen_cnt-10)/8}]
set restart_val_gen_cnt [expr {$num_of_cycles*8+ 10}]

run 15 us
add_force -cancel_after 4us /DCT1S_TB/rst 1 
run 4 us

set databuf_list [split $databuf ,]
set databuf_list_len [llength $databuf_list] 
for {set i 0} {$i < $databuf_list_len} {incr i } {
  set value [lindex $databuf_list $i] 
  set_value -radix unsigned "$databuf_path\[[expr {$databuf_list_len - 1 - $i}]\]" $value 
}
set_value -radix unsigned $gen_cnt_path $restart_val_gen_cnt
set_value -radix unsigned $row_cnt_path $row_cnt
##run 0.5 us
set_value -radix unsigned $stage2_start_path 1

run 20 us
remove_forces -all