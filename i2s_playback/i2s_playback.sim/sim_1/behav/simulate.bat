@echo off
set xv_path=C:\\Xilinx\\Vivado\\2017.2\\bin
call %xv_path%/xsim Efecto_REVERBPARAM_tb_behav -key {Behavioral:sim_1:Functional:Efecto_REVERBPARAM_tb} -tclbatch Efecto_REVERBPARAM_tb.tcl -view C:/Vivado/i2s_playback/EfectoLOOPER_tb_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
