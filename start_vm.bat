@echo off
VBoxManage startvm carconv_devbox_01_06_2022 --type headless

::start clear_case
start cmd.exe /c "C:\Program Files (x86)\IBM\RationalSDLC\ClearCase\bin\cc_start.bat"


:loop
echo trying to ping carconv_devbox
timeout 5 > nul
ping -n 1 10.1.1.254 2>&1 > nul && goto :alive || goto :loop

:alive
echo carconv_devbox is alive
timeout 5 > nul

for /f %%i in ('hostname') do set PC_NAME=%%i
net use U: \\10.1.1.254\dev dev /USER:%PC_NAME%\dev
%SystemRoot%\explorer.exe U:\

::ssh dev@127.0.0.1 -p 2222
::msys2_shell.cmd -msys -c "ssh -X -Y dev@127.0.0.1 -p 2222"
start mobaxterm -bookmark "dev_box"
msys2_shell.cmd -msys -c "ssh -Y dev@127.0.0.1 -p 2222"


exit