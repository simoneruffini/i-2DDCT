# launch this script on DCT2S_TB in GUI with:
# source ./path/to/script
restart
run 53.5 us

set databuf_path "/I_DCT2S_TB/U_IDCT2S/dbuf"
set ram_row_path "/I_DCT2S_TB/U_IDCT2S/ram_row"
set ram_row2_path "/I_DCT2S_TB/U_IDCT2S/ram_row2"
set stage2_en_path "/I_DCT2S_TB/U_IDCT2S/stage2_en"

## get a string rapresentation of:
set databuf [get_value -radix unsigned $databuf_path]
set ram_row [get_value -radix unsigned $ram_row_path]
# set ram_row2 [get_value -radix unsigned $ram_row2_path]

run 15 us
add_force -cancel_after 4us /I_DCT2S_TB/rst 1 
run 4 us

set databuf_list [split $databuf ,]
set databuf_list_len [llength $databuf_list] 
for {set i 0} {$i < $databuf_list_len} {incr i } {
  set value [lindex $databuf_list $i] 
  set_value -radix unsigned "$databuf_path\[[expr {$databuf_list_len - 1 - $i}]\]" $value 
}
set_value -radix unsigned $ram_row_path $ram_row
set_value -radix unsigned $ram_row2_path $ram_row
##run 0.5 us
set_value -radix unsigned $stage2_en_path 1

run 20 us
remove_forces -all
