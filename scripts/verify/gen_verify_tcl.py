import os
import sys
import shutil

##-------------------------------------------------------------------- Functions
def cleanup ():
    operative_system = sys.platform
    if operative_system == "linux" :
        try:
            os.remove("./vivado.log")
            os.remove("./vivado.jou")
            shutil.rmtree("./.Xil")
        except FileNotFoundError:
            print("\t-> files to be deleted are not found, proceeding.... \n")
    else:
        try:
            os.remove(".\\vivado.log")
            os.remove(".\\vivado.jou")
            shutil.rmtree(".\\.Xil")
        except FileNotFoundError:
            print("\t-> files to be deleted are not found, proceeding.... \n")
##------------------------------------------------------------------------------

##------------------------------------------------------------ Config Parameters
if sys.platform == "linux":
    vivado_path =  "/tools/Xilinx/Vivado/2020.2/bin/vivado"
elif sys.platform == "win32":
    vivado_path = "C:\\Xilinx\\Vivado\\2020.2\\bin\\vivado.bat"
else:
    sys.exit("I don't know how to open vivado on your system")

project_file = "../../vivado/i-2DDCT.xpr"
results_file= "gen_verify_tcl_results.txt"
tcl_script_file_path = "./gen_verify.tcl"

vtrace_delay_start_value = 0
vtrace_delay_end_value= 64
delay_step =1
max_simulation_time_us = 22

##------------------------------------------------------------------------------

##----------------------------------------------------------- Simulation Factors 

delay_list = []
for val in range(vtrace_delay_start_value,vtrace_delay_end_value+delay_step,delay_step):
    delay_list.append(val)

##------------------------------------------------------------------------------

##------------------------------------------------- Creation of tcl batch script
    ##  Defaults
    ## to get description of these signals use the describe command see
    ## UG835 (v2020.1) June 3, 2020 www.xilinx.com Tcl Command Reference Guide page 479

vtrace_delay_signal_path = "/TOP_LEVEL_TB/c_start_input_send_wait_clk_d"


    ## Create script tcl script file (later removed)
tcl_script_file = open(tcl_script_file_path, 'w')

    ## get Stdout file descriptor
std_out = sys.stdout

    ## Redirect prints (stdout) to tcl_script_file
sys.stdout=tcl_script_file

    ## Increase usable threads in vivado
threads = os.cpu_count() 
if threads != None:
    print("set_param general.MaxThreads " + str(threads))

    ## Open projectt
print("open_project " + project_file)

    ## Update top level testbench
print("# Update top_level tesbench")
print("update_compile_order -fileset sources_1")



    ## Set simulation starting poit at 0
print("set_property -name {xsim.simulate.runtime} -value {0us} -objects [get_filesets TOP_LEVEL_sim]")

    ## Creates reults file
print("set fp [open " + results_file+ " w]")

    ## Launch simulation
print("launch_simulation -simset [get_filesets TOP_LEVEL_sim ]")

    ##--------------------------------------------helper functions
def printlnres(string):
    print("puts $fp \"" + string + "\"")
def printres(string):
    print("puts -nonewline $fp \"" + string + "\"")
    ##------------------------------------------------------------



    ## set a as the correct result of the simulation
print("set a \"234,-23,-12,-8,-1,1,-2,-3,-3,-18,-10,-3,-1,-1,-1,1,-14,-7,-2,0,1,1,-1,-4,-7,-4,1,1,1,-1,-2,-2,0,-3,0,1,-1,-1,0,2,-4,0,-2,-1,-1,1,1,1,-4,0,-1,-1,0,1,0,-1,-1,-2,-1,0,1,-2,-2,-1,376,22,0,27,0,40,0,115,60,73,0,-75,0,-32,0,-182,261,244,0,-40,0,103,0,108,82,31,0,-53,0,-34,0,-148,-384,-208,0,108,0,-14,0,162,424,-315,0,82,0,-102,0,-33,304,-76,0,45,0,1,0,79,-44,62,0,-32,0,4,0,-46,162,-83,-234,-24,-118,0,-58,-82,-124,-4,-52,-33,-59,-34,-66,93,52,130,-45,141,14,101,19,-29,-84,-8,6,-16,-31,-18,-36,23,13,25,20,5,19,17,4,13,131,-78,-165,-1,-20,62,54,-219,114,-71,-73,0,9,38,53,-176,-31,-2,31,-29,-8,-24,-7,45,-336,-20,-10,-5,-1,2,6,-5,53,19,10,-32,-3,-3,45,-55,-13,-6,0,0,-4,-2,0,3,51,37,22,-31,1,-7,58,-69,-4,-6,-4,-1,3,-1,1,-4,80,61,31,-49,-3,-14,87,-94,-5,-3,-6,-9,1,-2,7,-7,258,176,90,-142,1,-26,245,-286,234,-23,-12,-8,-1,1,-2,-3,-3,-18,-10,-3,-1,-1,-1,1,-14,-7,-2,0,1,1,-1,-4,-7,-4,1,1,1,-1,-2,-2,0,-3,0,1,-1,-1,0,2,-4,0,-2,-1,-1,1,1,1,-4,0,-1,-1,0,1,0,-1,-1,-2,-1,0,1,-2,-2,-1,376,22,0,27,0,40,0,115,60,73,0,-75,0,-32,0,-182,261,244,0,-40,0,103,0,108,82,31,0,-53,0,-34,0,-148,-384,-208,0,108,0,-14,0,162,424,-315,0,82,0,-102,0,-33,304,-76,0,45,0,1,0,79,-44,62,0,-32,0,4,0,-46,162,-83,-234,-24,-118,0,-58,-82,-124,-4,-52,-33,-59,-34,-66,93,52,130,-45,141,14,101,19,-29,-84,-8,6,-16,-31,-18,-36,23,13,25,20,5,19,17,4,13,131,-78,-165,-1,-20,62,54,-219,114,-71,-73,0,9,38,53,-176,-31,-2,31,-29,-8,-24,-7,45,-336,-20,-10,-5,-1,2,6,-5,53,19,10,-32,-3,-3,45,-55,-13,-6,0,0,-4,-2,0,3,51,37,22,-31,1,-7,58,-69,-4,-6,-4,-1,3,-1,1,-4,80,61,31,-49,-3,-14,87,-94,-5,-3,-6,-9,1,-2,7,-7,258,176,90,-142,1,-26,245,-286,-101010\"")

    ## Simulation Results, map of tcl commands to retrive them
sim_res_cmds= {
    "vtrace_delay"                  :"[get_value -radix unsigned " + vtrace_delay_signal_path + "]",
    "input_started_time"            :"[get_value -radix unsigned /TOP_LEVEL_TB/input_started_time]",
    "input_finished_time"           :"[get_value -radix unsigned /TOP_LEVEL_TB/input_finished_time]",
    "output_finished_time"          :"[get_value -radix unsigned /TOP_LEVEL_TB/output_finished_time]",
    "vtrace_rom_raddr"              :"[get_value -radix unsigned /TOP_LEVEL_TB/vtrace_rom_raddr]",
    "dct2d_cnt"                     :"[get_value -radix unsigned /TOP_LEVEL_TB/dct2d_cnt]",
    "halt_time"                     :"[get_value -radix unsigned /TOP_LEVEL_TB/halt_time]",
    "2ddct_correct"                 :"[string eq $a [get_value -radix dec /TOP_LEVEL_TB/dct2d_data]]",
    "2ddct_data"                    :"[get_value -radix dec /TOP_LEVEL_TB/dct2d_data]"
}
    ## outputs the keys of db_fix_tim_data in this format: key1;key2;key3;...;
printlnres( "".join(
        list(str(a)+";" for a in list(sim_res_cmds.keys()))
    )
)

print("# Simulation start")

for delay in delay_list:
    print("add_force -radix unsigned " + vtrace_delay_signal_path + " " + str(delay))
    print("run " +str(max_simulation_time_us)+ " us")

        ## print commands of the db_fixe_time_data as command1;command2;....commandN;
        ## this commands will be printed in the results file
    printlnres( "".join( 
            list(str(value)+";" for value in list(sim_res_cmds.values()))
        ) 
    )
    print("remove_forces -all")
    print("restart")

print("# Simulation end")

    ## Restore std out descriptor to its original value
sys.stdout=std_out

    ## Close generated script file
tcl_script_file.close()
##------------------------------------------------------------------------------

##-----------------------------------------------------------Remove vivado files
cleanup()
##------------------------------------------------------------------------------

################################################################################
########################## RUN GENERATED BATCH FIlE ############################
    ## parameters to pass to vivado
run_line = vivado_path + " -mode batch -source " + tcl_script_file_path

##run_line = "export LC_ALL=C \n" + run_line    ## <- eventually remove this
print("Executing: " + str(run_line))
os.system(run_line)
################################################################################
################################################################################

##-----------------------------------------------------------Remove vivado files
cleanup()
##------------------------------------------------------------------------------
