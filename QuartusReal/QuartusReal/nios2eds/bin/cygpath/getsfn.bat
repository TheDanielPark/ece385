@ REM #########################################################
@ REM #                                                       #
@ REM # getsfn.bat:                                           #
@ REM #   echo the first parameter as a                       #
@ REM #   Short File Name                                     #
@ REM #                                                       #
@ REM # This file is essential to proper operation of         #
@ REM # The Nios II product.  It is not intended to be called #
@ REM # directly.                                             #
@ REM # When this script is called, the first parameter must  #
@ REM # be quoted if there are spaces in the parameter.       #
@ REM #                                                       #
@ REM # Copyright (c) 2012 Altera Corporation                 #
@ REM # All Rights Reserved.                                  #
@ REM #                                                       #
@ REM #########################################################

@ REM #########################################################
@ REM # This first output echoed by this script s/b either    #
@ REM # the short file name of parameter 1, or a descriptive  #
@ REM # ---ERROR--- string                                    #
@ REM #########################################################

@ REM #########################################################
@ REM Check for a parameter
@ if [%1%]==[] goto __NoParm__

@ REM #########################################################
@ REM Check that the path exists
@ if not exist %1% goto __NoFile__

@ REM #########################################################
@ REM Grab the short file name version of the parameter
@ set __sfn__=%~s1%

@ REM #########################################################
@ REM Echo the short file name
@ echo %__sfn__%

@ set __sfn__=
@ exit /b 0
@ goto __end__

:__NoParm__
@ echo ---NO_PARM_ERROR--- No parameter was passed
@ echo %0% is not intended to be called directly
@ echo Usage: %0 path
@ exit /b 1
@ goto __end__

:__NoFile__
@ echo ---NO_FILE_ERROR--- The file %1% does not exist
@ exit /b 1
@ goto __end__

:__end__
