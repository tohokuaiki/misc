cscript -b day.vbs
if %errorlevel%==7 set WDAY=SAT
if %errorlevel%==6 set WDAY=FRI
if %errorlevel%==5 set WDAY=THU
if %errorlevel%==4 set WDAY=WED
if %errorlevel%==3 set WDAY=TUE
if %errorlevel%==2 set WDAY=MON
if %errorlevel%==1 set WDAY=SUN

xcopy C:\from_data C:\backup_dir\%WDAY%/S/E/I/H/Y

"\Program Files (x86)\PostgreSQL\8.4\bin\pg_dump.exe" -U username database > C:\backup_dir\%WDAY%\pg_dump.sql

