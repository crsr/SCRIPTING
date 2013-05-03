@ECHO off 
ECHO Choose: 
ECHO [W] Enable Wireless Network Connection 
ECHO [L] Enable Local Area Connection
ECHO. 
:choice 
SET /P C=[W,L]? 
for %%? in (W) do if /I "%C%"=="%%?" goto W 
for %%? in (L) do if /I "%C%"=="%%?" goto L 
goto choice 
:W 
@ECHO OFF 
ECHO "Enable wireless network connection" 
netsh interface set interface "Local Area Connection" DISABLE
netsh interface set interface "Wireless Network Connection" ENABLE
ECHO Here are the new settings for %computername%: 
netsh int ip show config
pause 
goto end

:L 
@ECHO OFF 
ECHO "Enable local area connection" 
netsh interface set interface "Local Area Connection" ENABLE
netsh interface set interface "Wireless Network Connection" DISABLE
ECHO Here are the new settings for %computername%: 
netsh int ip show config
pause 
goto end 
:end