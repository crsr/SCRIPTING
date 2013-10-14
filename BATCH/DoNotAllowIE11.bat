@echo off
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\Setup\11.0" /V "DoNotAllowIE11" /D 1 /T REG_DWORD /F
