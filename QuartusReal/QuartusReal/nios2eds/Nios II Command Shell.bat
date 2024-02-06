@ REM ###################################################
@ REM #                                                 #
@ REM # Nios2 Software Build Tools (SBT) Command Shell  #
@ REM #                                                 #
@ REM # Execute this script to setup an environment for #
@ REM # using the Nios2eds Software Build Tools (SBT)   #
@ REM #                                                 #
@ REM # This shell uses nios2-elf-gcc version 4.1.2     #
@ REM #                                                 #
@ REM #                                                 #
@ REM # Copyright (c) 2010, 2012 Altera Corporation     #
@ REM # All Rights Reserved.                            #
@ REM #                                                 #
@ REM ###################################################

@ REM ######################################
@ REM # Variable to ignore <CR> in DOS
@ REM # line endings
@ set SHELLOPTS=igncr

@ REM ######################################
@ REM # Variable to ignore mixed paths
@ REM # i.e. G:/$SOPC_KIT_NIOS2/bin
@ set CYGWIN=nodosfilewarning


@ REM ######################################
@ REM # Discover the root nios2eds directory

@ set _NIOS2EDS_ROOT=%~dp0
@ set _NIOS2EDS_ROOT="%_NIOS2EDS_ROOT:\=/%"

@ REM ######################################

@ REM ######################################
@ REM # set root quartus directory to
@ REM # QUARTUS_ROOTDIR_OVERRIDE if the
@ REM # env var is set

@ if "%QUARTUS_ROOTDIR_OVERRIDE%"=="" goto set_default_quartus_root
@ set _QUARTUS_ROOT=%QUARTUS_ROOTDIR_OVERRIDE%
@ goto set_default_quartus_bin

@ REM ######################################


@ REM ######################################
@ REM # Discover the root quartus directory
@ REM # when QUARTUS_ROOTDIR_OVERRIDE is not
@ REM # set

:set_default_quartus_root
@ set _QUARTUS_ROOT=%~dp0..\quartus
@ goto set_default_quartus_bin

@ REM ######################################


@ REM ######################################
@ REM # Discover the quartus bin directory

:set_default_quartus_bin
@ set _QUARTUS_BIN=%_QUARTUS_ROOT%\bin64
@ goto run_qreg

@ REM ######################################


@ REM ######################################
@ REM # Run qreg (if it exists) to setup
@ REM # cygwin and jtag services

:run_qreg
@ if not exist "%_QUARTUS_BIN%\qreg.exe" goto run_nios2_command_shell

@ if "%SKIP_ACDS_QREG%"=="1" goto run_nios2_command_shell

@ "%_QUARTUS_BIN%\qreg.exe"

@ if "%SKIP_ACDS_QREG_JTAG%"=="1" goto run_nios2_command_shell
@ "%_QUARTUS_BIN%\qreg.exe" --jtag

@ REM ######################################
@ REM # Launch cygwin nios2eds command shell

:run_nios2_command_shell
@ "%_QUARTUS_BIN%\cygwin\bin\bash.exe" -c '%_NIOS2EDS_ROOT%nios2_command_shell.sh %*'
