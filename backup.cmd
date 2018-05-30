@echo off
Setlocal EnableDelayedExpansion 


:: setting constants ::
set VERSION=2
set BUILD=2
set AUTHOR=ButterOnYourBread

set ARG_MODE=M
set ARG_BACKUPNAME=N
set ARG_ATTRUBUTESKIP=A
set ARG_UNATTENDED=U
set ARG_VERBOSE=V
set ARG_LOG=L
set ARG_JOB=J

set MODE_DIFF=diff
set MODE_FULL=full

set PATH_TMP=%~dp0%tmp
set PATH_CONFIG=%~dp0%config
set PATH_JOBS=%PATH_CONFIG%\jobs
set PATH_DESTINATIONS=%PATH_CONFIG%\destinations
set PATH_SOURCES=%PATH_CONFIG%\sources
set PATH_EXCLUDES=%PATH_CONFIG%\excludes


:: variable init :
set scriptTitle=Volles Backup

set time_f=%time%
set time_f=%time_f: =0%
set time_f=%time_f::=%
set time_f=%time_f:,=%
set TIMESTAMP_F=%date:~-4%_%date:~3,2%_%date:~0,2%__%time_f:~-8,2%%time_f:~-6,2%%time_f:~-4,2%

set hosts=%PATH_TMP%\%TIMESTAMP_F%_job
set destinations=%PATH_TMP%\%TIMESTAMP_F%_destinations
set sources=%PATH_TMP%\%TIMESTAMP_F%_sources

set errortext=

set mode=%MODE_FULL%
set job=
set backupname=%mode%
set skipAttrib=1
set unattended=0
set verbose=0
set pathSource=
set pathDestination=
set log=0

set maxParam=9
set pathSourceParsed=0

set /A countParam=0
set /A countHosts=0
set /A countBackupRun=0


:: parameter & argument parsing ::
for %%x in (%*) do (
	set /a countParam+=1
	set arg=%%x
	
	::parse arguments
	if "!arg:~,1!"=="/" (
	
		if "!arg:~1,1!"=="%ARG_MODE%" (
			::parse value of argument
			if "!arg:~2,1!"==":" (
				if not "!arg:~3!"=="" (
					set mode=!arg:~3!
					set backupname=!mode!
					if not !mode!==%MODE_DIFF% if not !mode!==%MODE_FULL% (
						set "errortext=unbekannter Modus"
						goto :errorParam
					) 	
				) else (
					set "errortext=Modus nicht angegeben"
					goto :errorParam
				)
			) else (
				set "errortext=Modus nicht angegeben"
				goto :errorParam
			)
		)
		
		if "!arg:~1!"=="%ARG_ATTRUBUTESKIP%" (
			set skipAttrib=0
		)
		
		if "!arg:~1!"=="%ARG_UNATTENDED%" (
			set unattended=1
		)
		
		if "!arg:~1!"=="%ARG_VERBOSE%" (
			set verbose=1
		)
		
		if "!arg:~1!"=="%ARG_LOG%" (
			set log=1
		)
		
		if "!arg:~1,1!"=="%ARG_JOB%" (
			::parse value of argument
			if "!arg:~2,1!"==":" (
				if not "!arg:~3!"=="" (
					set job=!arg:~3!
					set maxParam=7
					
					if not exist %PATH_JOBS%\!job! ( 
						set "errortext=Job nicht gefunden"
						goto :error
					)					
				) else (
					set "errortext=Job nicht angegeben"
					goto :errorParam
				)
			) else (
				set "errortext=Job nicht angegeben"
				goto :errorParam
			)
		)
	) 
)

for %%x in (%*) do (
	set arg=%%x

	::parse arguments
	if "!arg:~,1!"=="/" (
		if "!arg:~1,1!"=="%ARG_BACKUPNAME%" if !mode!==%MODE_FULL% (
			::parse value of argument
			if "!arg:~2,1!"==":" (
				if not "!arg:~3!"=="" (
					set backupname=!arg:~3!
				) else (
					set "errortext=Backupname nicht angegeben"
					goto :errorParam
				)
			) else (
				set "errortext=Backupname nicht angegeben"
				goto :errorParam
			)
		) else (
			set "errortext=Backupname in diesem Modus nicht moeglich"
			goto :errorParam
		)
	) else (
	
		:: parse parameters
		if "%job%"=="" (
			if !pathSourceParsed!==0 (
				set pathSource=%%x
				set pathSourceParsed=1
			) else (
				set pathDestination=%%x
			)
		)
	)
)

if "%~1"=="/?" goto :usage
if %countParam%==0 (
	set "errortext=erwartete Parameter fehlen"
	goto :errorParam
)
if %countParam% GTR %maxParam% (
	set "errortext=nicht erwartete Parameter angegeben"
	goto :errorParam
)

if "%job%"=="" (
	if "%pathSource%"=="" (
		set "errortext=Quellpfad nicht angegeben"
		goto :errorParam
	)
	
	if "%pathDestination%"=="" (
		set "errortext=Zielpfad nicht angegeben"
		goto :errorParam
	)
)

:: parameter & argument based variable init :
if /i %mode%==%MODE_DIFF% (
	set scriptTitle=Differentielles Backup
) else (
	if /i %mode% NEQ %MODE_FULL% (
		set scriptTitle=Manuelles volles Backup: %backupname%
	)
)

if exist %PATH_TMP% (
	rd /s /q %PATH_TMP% >nul
)

if not "%job%"=="" (
	set hosts=%PATH_JOBS%\%job%
) else (
	md %PATH_TMP% >nul
	
	for /f %%i in ('hostname') do set "hostname=%%i"
	echo !hostname!>%hosts%
	echo %pathDestination%>%destinations%
	echo %pathSource%>%sources%
)


::Graphical Ouptut of Header
title %scriptTitle%
call :header
if "%unattended%"=="0" (
	echo.
	:loop
	echo Soll der Backupjob nun verarbeitet werden (J/N^)^?
	set /p input=
	
	if "!input!"=="J" goto :break
	if "!input!"=="j" goto :break
	if "!input!"=="N" goto :exit
	if "!input!"=="n" goto :exit
	
	call :header
	
	echo Nur "J" oder "N" zulaessig
	goto :loop
)
:break

::Check Destinations
for /f "eol=; tokens=1,2* usebackq delims=" %%h in (%hosts%) do (
	set /a countHosts+=1

	if not "%job%"=="" (
		set destinations=%PATH_DESTINATIONS%\%%h
	)
	
	for /f "eol=; tokens=1,2* usebackq delims=" %%t in (!destinations!) do ( 
		call :loopCheckFolder %%t Ziel
	)
)

::check sources if manual mode
if "%job%"=="" (
	for /f "eol=; tokens=1,2* usebackq delims=" %%t in (%sources%) do ( 
		call :loopCheckFolder %%t Quelle
	)
)

::backup section
call :header

for /f "eol=; tokens=1,2* usebackq delims=" %%h in (%hosts%) do (
	set /a countBackupRun+=1

	if not "%job%"=="" (
		echo Beginne mit Sicherung der Quellen von "%%h":
		set destinations=%PATH_DESTINATIONS%\%%h
		set sources=%PATH_SOURCES%\%%h
	)
	
	if /i %mode%==%MODE_FULL% (
		for /f "eol=; tokens=1,2* usebackq delims=" %%l in (!destinations!) do ( 
			set "destPathDiff=%%l\%%h\%MODE_DIFF%"
			if exist !destPathDiff! (
				set pathDelTemp=%%l\%%h\DelTemp

				echo.
				echo     [!time:~0,2!:!time:~3,2!:!time:~6,2!] Entferne alte differentielle Backups:
				if "%verbose%"=="1" (
					for /f %%i in ('dir !destPathDiff! /B /A:D') do (
						echo         -^> %%i
					)
				)
				
				mkdir "!pathDelTemp!" >nul
				robocopy "!pathDelTemp!" "!destPathDiff!" /PURGE /ETA /NC /NDL /NFL /NJH /NJS /NS /NP >nul
				rmdir "!pathDelTemp!" >nul
				rmdir "!destPathDiff!" >nul
			)
		)
	)  
	
	for /f "eol=; tokens=1,2* usebackq delims=" %%s in (!sources!) do ( 
		for /f "eol=; tokens=1,2* usebackq delims=" %%d in (!destinations!) do ( 
			set destPath=%%d\%%h\%backupname%\
			if /i %mode%==%MODE_DIFF% (
				set destPath=%%d\%%h\%MODE_DIFF%\%TIMESTAMP_F%\
			)
			
			for /f "delims=" %%p in ("%%s") do (
				if /i 0%%~np==0 (
					set destPath=!destPath!%%s
				) else (
					set destPath=!destPath!%%~np
				)
				
				set destPath=!destPath::\.=!
				echo     [!time:~0,2!:!time:~3,2!:!time:~6,2!] Kopiere %%s nach !destPath!
				
				set excludes=
				if not "%job%"=="" (
					if exist %PATH_EXCLUDES%\%%h (
						for /f "eol=; tokens=1,2* usebackq delims=" %%x in (%PATH_EXCLUDES%\%%h) do ( 
							set excludes=!excludes! "%%x" 
						)
					)
				)
				
				if not exist !destPath! (
					mkdir !destPath! >nul
				)
				
				set copymode=/MIR
				if /i %mode%==%MODE_DIFF% (
					set copymode=/E /A
				)
				
				if /i %log%==1 (
					robocopy "%%s" "!destPath!" !copymode! /COPY:DAT /DCOPY:DAT /SL /MT:8 /XA:ST /XJ /XJD /XJF /R:0 /W:0 /ETA /NC /NDL /NFL /NJH /NJS /NS /NP /Log:"!destPath!.log" /XD !excludes!
				) else (
					robocopy "%%s" "!destPath!" !copymode! /COPY:DAT /DCOPY:DAT /SL /MT:8 /XA:ST /XJ /XJD /XJF /R:0 /W:0 /ETA /NC /NDL /NFL /NJH /NJS /NS /NP /XD !excludes! >nul
				)

				if /i %log%==1 (
					echo.
					echo.
				)
				
				if /i %mode%==%MODE_FULL% (
					echo     [!time:~0,2!:!time:~3,2!:!time:~6,2!] Setze Archivbit zurueck
					attrib -a /S /D "%%s\*.*" >nul
				)
				
				if /i %skipAttrib%==0 (
					echo     [!time:~0,2!:!time:~3,2!:!time:~6,2!] Korrigiere Attribute
					attrib -S -H /S /D "!destPath!" >nul
				)
				echo.
			)
		)
	)
	
	if not "%countHosts%"=="!countBackupRun!" (
        echo --------------------------------------------------------------------------------
		echo.
	)
)

goto :exit
:: #################################### END OF PROGRAM :: ####################################



:: labels & subroutines
:loopCheckFolder %1 %2
if exist %1 (
	goto :eof
) else (
	call :header

	echo %2 %1 existiert nicht - Bitte bereitstellen
	
	:loopCheckFolder_yesno
	echo Neuer Versuch (J/N^)? 
	set /p input=
	echo.
	if "!input!"=="J" goto :break_loopCheckFolder_yesno
	if "!input!"=="j" goto :break_loopCheckFolder_yesno
	if "!input!"=="N" goto :exit
	if "!input!"=="n" goto :exit
	
	call :header
	echo Nur "J" oder "N" zulaessig
	goto :loopCheckFolder_yesno
	
	:break_loopCheckFolder_yesno
	call :loopCheckFolder %1 %2
	goto :eof
)


:header
cls
echo ________________________________________________________________________________
echo                        ______            _                
echo                        ^| ___ \          ^| ^|               
echo                        ^| ^|_/ / __ _  ___^| ^| ___   _ _ __  
echo                        ^| ___ \/ _` ^|/ __^| ^|/ / ^| ^| ^| '_ \ 
echo                        ^| ^|_/ / (_^| ^| (__^|   ^<^| ^|_^| ^| ^|_) ^|
echo                        \____/ \__,_^|\___^|_^|\_\\__,_^| .__/ 
echo                                                    ^| ^|    
echo                                                    ^|_^|
echo.
echo                                                                      Version %VERSION%.%BUILD%
echo                                                            (C) %AUTHOR%
echo --------------------------------------------------------------------------------
echo Modus: %scriptTitle%
if not "%job%"=="" (
	echo Job:   %job%
	if "%verbose%"=="1" (
		for /f "eol=; tokens=1,2* usebackq delims=" %%h in (%hosts%) do (
			echo            -^> %%h
		)
	)
)
echo ________________________________________________________________________________
echo. 
echo.
goto :eof

:error
echo Fehler: %errortext%
goto :eof


:errorParam
call :error
goto :usage


:usage
echo.
echo Script zum Sichern von Dateistrukturen in Zielordner mittels Robocopy. Es werden unterschiedliche Modis bereit-
echo gestellt, um volle oder differentielle Sicherungen zu erstellen.
echo Alle Quellen und Ziele werden aus den Config-Dateien gezogen. Ausser im manuellen Modus. Hier kann das Ziel per
echo Parameter bestimmt werden.
echo. 
echo BACKUP [/M[[:]Modus]] [/N[[:]Backupname]] [/J[:]Job]] [/A] [/U] [/V] [Quelllaufwerk:[Quellpfad]] [Ziellaufwerk:[Zielpfad]]
echo. 
echo /M     Modus des Backups [Std.: full]
echo Modis   full  vollstaendige Spiegelung
echo         diff  differentielle Sicherung (alle seit der letzten vollen Sicherung veraenderten Dateien werden 
echo               gespiegelt)
echo /N     Name des Backups (Nur in Kombination mit /M:full!) [Std.: entspricht dem Modus]  	
echo /J     Name des Jobs - wird dieses Argument gesetzt, dann wird der Job - falls vorhanden - aus der Jobkonfi-
echo        guration geladen. Manuelle Pfadangaben sind dann ungueltig.
echo /A     Attribute werden korrigiert (versteckt und system wird entfernt)
echo /U     Es werden keine Sicherheitsrückfragen gestellt
echo /V     ausführliche Ausgaben
echo.
echo.
echo Bsp. fuer eine manuelle Sicherung auf eine Festplatte:	
echo     BACKUP E:\Dateien F:
echo Bsp. fuer ein volles Backup anhand eines vorkonfigurierten Jobs: 
echo     BACKUP /J:monatssicherung /A /U
echo Bsp. fuer ein differentielles Backup: 
echo     BACKUP /M:diff /J:monatssicherung /A
echo.
goto :eof


:exit
if exist %PATH_TMP%  (
	rd %PATH_TMP% /s /q >nul
)
exit
