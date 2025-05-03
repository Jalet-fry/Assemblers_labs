@echo off
echo Turbo Assembler Build Script
echo --------------------------

:: Check if filename was provided
if "%1"=="" goto usage

:: Remove .asm extension if present
set filename=%1
echo We are "%filename:~-4%"
echo Now is %filename:~0,-4%
if "%filename:~-4%"==".ASM" set filename=%filename:~0,-4%

:: Assemble with debug info
echo Assembling %filename%.asm...
tasm /zi %filename%.asm
if errorlevel 1 goto asm_error

:: Link with debug info
echo Linking %filename%.obj...
tlink /v  %filename%.obj
del %filename%.obj
del %filename%.map
copy TDC2.TD TDCONFIG.TD
if errorlevel 1 goto link_error

:: Run the program
:::echo Running %filename%.exe...
:::echo --------------------------
:::%filename%.exe
goto end

:asm_error
echo Assembly failed! Cheаck your code.
goto end

:link_error
echo Linking failed! Check for missing symbols.
goto end

:usage
echo Usage: build filename[.asm]
echo Example: build hello
echo          or
echo          build hello.asm

:end
echo.