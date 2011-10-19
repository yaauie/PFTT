@echo off


set PHP_CMD_SHELL=1
set PHP_SDK=%SYSTEMDRIVE%\php-sdk
set PHPT_BRANCH=%PHP_SDK%\svn\branches
set PHP_BIN=%PHP_SDK%\bin
set PHP_BUILDS=%PHP_SDK%\builds
set PFTT_HOME=%PHP_SDK%\PFTT
REM TODO TEMP use regular PFTT_HOME
set PFTT_HOME=C:\Users\v-mafick\Desktop\sf\workspace\PFTT
set PFTT_RESULTS=%PHP_SDK%\PFTT-Results
set PFTT_SCRIPTS=%PHP_SDK%\PFTT-Scripts
set PFTT_PHPS=%PHP_SDK%\PFTT-PHPs
set PHP_DEPS=%PHP_SDK%\deps
set PHP_DEP_LIBS=%PHP_DEPS\libs
set PHP_DEP_INCLUDES=%PHP_DEPS\includes

REM configure git (for pftt devs/encourge pftt users to become devs)
CALL %PFTT_HOME%\config\git_conf.cmd

IF NOT EXIST %PHP_SDK% MKDIR %PHP_SDK%
IF NOT EXIST %PHPT_BRANCH% MKDIR %PHPT_BRANCH%
IF NOT EXIST %PHP_BUILDS% MKDIR %PHP_BUILDS%
IF NOT EXIST %PFTT_RESULTS% MKDIR %PFTT_RESULTS%
IF NOT EXIST %PFTT_SCRIPTS% MKDIR %PFTT_SCRIPTS%
IF NOT EXIST %PFTT_PHPS% MKDIR %PFTT_PHPS%

set PATH=%PFTT_HOME%;%PFTT_HOME%\Scripts\SDK4Win\;%PATH%

REM "%ProgramFiles%\Microsoft SDKs\Windows\v7.0\Bin\SetEnv.cmd" /xp /x86 /release

REM %PHP_BIN%\phpsdk_setvars.bat

cd %PHP_SDK%


welcome
