@echo off

rem .zshrc
rem    bat --color=always {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -500

rem profile.ps1
rem    c:\temp\blah.cmd {} | head -500

bat --color=always %1 2>NUL
if not errorlevel 1 exit
type %1 2>NUL
if not errorlevel 1 exit
tree /a /f %1 2>NUL
