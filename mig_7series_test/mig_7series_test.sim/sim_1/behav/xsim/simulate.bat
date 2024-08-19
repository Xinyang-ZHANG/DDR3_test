@echo off
REM ****************************************************************************
REM Vivado (TM) v2019.1 (64-bit)
REM
REM Filename    : simulate.bat
REM Simulator   : Xilinx Vivado Simulator
REM Description : Script for simulating the design by launching the simulator
REM
REM Generated by Vivado on Fri Aug 16 22:26:32 +0800 2024
REM SW Build 2552052 on Fri May 24 14:49:42 MDT 2019
REM
REM Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
REM
REM usage: simulate.bat
REM
REM ****************************************************************************
echo "xsim sim_tb_top_behav -key {Behavioral:sim_1:Functional:sim_tb_top} -tclbatch sim_tb_top.tcl -view D:/self_learning/hulang/hulang001_plus/2_projects/mig_7series_test/sim_tb_top_behav.wcfg -log simulate.log"
call xsim  sim_tb_top_behav -key {Behavioral:sim_1:Functional:sim_tb_top} -tclbatch sim_tb_top.tcl -view D:/self_learning/hulang/hulang001_plus/2_projects/mig_7series_test/sim_tb_top_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
