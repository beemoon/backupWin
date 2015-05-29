@echo off
cls

TITLE Sauvegarde

REM *****************************************
REM
REM Script de sauvegarde utilisant robocopy
REM  Pour le laboratoire GSCOP
REM  Sur le domaine gscop-prive
REM
REM   O.Brizard @2014
REM
REM *****************************************
:: Robocopy pour Windows XP
::   http://www.microsoft.com/en-us/download/confirmation.aspx?id=17657
::


::== Repertoire a sauvegarder ==

	:: On sauvegarde par defaut les Documents, le Bureau, et s'ils existent les profiles de Thunderbird et Firefox.
	set srcFolderDefault=%HOMEPATH%\Documents,%HOMEPATH%\Desktop
	if exist %HOMEPATH%\AppData\Roaming\Thunderbird set srcFolderDefault=%srcFolderDefault%,%HOMEPATH%\AppData\Roaming\Thunderbird
	if exist %HOMEPATH%\AppData\Roaming\Mozilla  set srcFolderDefault=%srcFolderDefault%,%HOMEPATH%\AppData\Roaming\Mozilla

	:: Repertoire(s) a sauvegarder, avec guillemets s'il y a des espaces et separe par une virgule
	set srcFolderPerso=
	
::===============================

:: Parametre utilisateur
set login=
set password=

:: Parametre serveur
set bkpCible=Sauvegarde
set serveur=195.83.78.175
set domaine=gscop-prive

:: Recupere le login si aucun specifie
if "%login%"=="" (
	for /f "tokens=1* delims=\" %%a in ('whoami') do set login=%%b
)

:: Connexion au serveur
ping -n 1 %serveur%>NUL
if %ERRORLEVEL% NEQ 0 goto error4
if "%domaine%"=="" set _user=%login%
if not "%domaine%"=="" set _user=%domaine%\%login%
net use \\%serveur%\%login% /USER:%_user% >NUL
if %errorlevel% neq 0 goto error
if not exist \\%serveur%\%login%\%bkpCible% mkdir \\%serveur%\%login%\%bkpCible%

echo *** le %date% > %~dp0\backup.log
echo **************************>> %~dp0\backup.log
echo. >> %~dp0\backup.log
echo. >> %~dp0\backup.log

cls

set check=0
set srcFolder=%srcFolderDefault%
if NOT "%srcFolderPerso%"=="" set srcFolder=%srcFolderDefault%,%srcFolderPerso%

for %%a in (%srcFolder%) do ( 
	rem  Controle de la source
	if exist %%a (
		set check=1
		rem Commandes de sauvegarde
		for %%i in (%%a) do (
			robocopy "%%a" "\\%serveur%\%login%\%bkpCible%\%%~na" /S /PURGE /MT:64 /DCOPY:T /Z /FFT /XO /XJ /XA:RSTE /XD *cache* "VirtualBox VMs" Tmp Temp Microsoft /XF *cache* usrclass.dat ntuser.dat *.ova *.vmdk *.vdi *.cab *.lnk *.log? *.lock *.iso .* *.tmp ~* /R:1 /W:5 /TEE /LOG+:"%~dp0backup.log" /NP /NDL
		)
	) else (
		call :error2 %%a
	)

)

:end
:: Deconnexion du serveur
rem @echo off
net use /delete /YES \\%serveur%\%login%>nul

if '%check%'=='0' goto error3

:: Programme la prochaine sauvegarde
if not exist %HOMEPATH%\%~nx0 copy %0 %HOMEPATH%\%~nx0 /Y >NUL
SchTasks /Create /F /SC DAILY /TN "Sauvegarde" /TR "%HOMEPATH%\%~nx0" /ST 12:30 >NUL

echo.
echo.
echo ***************************
echo *** Sauvegarde terminee.***
echo ***************************
echo.
ping -n 5 127.0.0.1>nul
goto :eof

:error
cls
echo.
echo  Probleme de connexion au serveur gscopfiles1
echo.
echo   - Verifier le login et/ou mot de passe
echo   - Gscopfiles1 est peut etre indisponible.
echo.
echo.

ping -n 7 127.0.0.1>nul
goto :eof

:error2
cls
echo.
echo. >>"%~dp0backup.log"
echo. >>"%~dp0backup.log"
echo  Le repertroire %1 a sauvegarder n'existe pas.
echo  Le repertroire %1 a sauvegarder n'existe pas.>>"%~dp0backup.log"
echo. >>"%~dp0backup.log"
echo. >>"%~dp0backup.log"
echo.
echo.

ping -n 2 127.0.0.1>nul
exit /b
goto :eof

:error3
cls
echo.
echo  Les repertroires sources a sauvegarder n'existent pas.
echo.
echo.

ping -n 5 127.0.0.1>nul
goto :eof

:error4
cls
echo.
echo. >"%~dp0backup.log"
echo. >>"%~dp0backup.log"
echo  Le serveur est injoingnable.>>"%~dp0backup.log"
echo. >>"%~dp0backup.log"
echo. >>"%~dp0backup.log"
echo.
echo.

ping -n 2 127.0.0.1>nul
goto :eof
