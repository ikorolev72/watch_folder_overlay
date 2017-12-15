@ECHO OFF
REM 20171214
REM 20171210
REM korolev-ia [at] yandex.ru
REM This script start processing video file in folder IN
REM 

set SCRIPTNAME=%~f0
for %%F in (%SCRIPTNAME%) do set DIRNAME=%%~dpF

set IMAGE=%DIRNAME%IMAGES\overlay.png

set IN=%DIRNAME%IN
set OUT=%DIRNAME%OUT
set BACKUP=%DIRNAME%BACKUP
set FFMPEG=%DIRNAME%FFMPEG\BIN\ffmpeg.exe
set WATCH_FOLDER=%DIRNAME%watch_folder_overlay.exe


REM Uncomment next line if you need infinity loop
REM goto INFINITY

"%WATCH_FOLDER%" --imageoverlay="%IMAGE%" --in="%IN%" --out="%OUT%" --backup="%BACKUP%" --ffmpeg="%FFMPEG%"

exit

:INFINITY
	"%WATCH_FOLDER%" --imageoverlay="%IMAGE%" --in="%IN%" --out="%OUT%" --backup="%BACKUP%" --ffmpeg="%FFMPEG%"
	ECHO sleep 20 sec and will watch folder %IN% again
	SLEEP 20
goto INFINITY


