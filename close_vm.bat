

VBoxManage controlvm carconv_devbox_24_08_2021 acpipowerbutton

:loop
echo checking if carconv_devbox is still alive
timeout 5 > nul
ping -n 1 10.1.1.254 2>&1 > nul && goto :loop || goto :stop

:stop
echo carconv_devbox is stopped

net use U: /delete

pause


exit