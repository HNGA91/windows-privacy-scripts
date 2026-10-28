@echo off
setlocal
title Stop telemetrie Windows
:: ==================================================================
::  stop-telemetrie.bat
::  Reduit la telemetrie et le pistage de Windows 10 / 11.
::  - A lancer en administrateur, depuis ton propre compte (admin),
::    sinon les reglages HKCU s'appliquent a un autre compte.
::  - Annulation : restaurer-telemetrie.bat
::  - Fichier volontairement sans accents (affichage de cmd).
:: ==================================================================

net session >nul 2>&1 || (echo Lance ce script en administrateur. & pause & exit /b 1)

echo.
echo === [0/5] Point de restauration ===
powershell -NoProfile -Command "try { Checkpoint-Computer -Description 'Avant stop-telemetrie' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop; Write-Host '  OK  Point de restauration demande' } catch { Write-Host ('  !!  Point de restauration NON cree : ' + $_.Exception.Message) }"
choice /c ON /m "Continuer"
if errorlevel 2 exit /b 1

echo.
echo === [1/5] Telemetrie ===
set "DC=HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
:: Niveau minimal (0 est traite comme 1 sur Famille/Pro, mais verrouille le reglage)
call :setdw "%DC%" AllowTelemetry 0
call :setdw "%DC%" DoNotShowFeedbackNotifications 1
call :setdw "%DC%" LimitDiagnosticLogCollection 1
call :setdw "%DC%" LimitDumpCollection 1
:: Programme d'amelioration de l'experience utilisateur (CEIP)
call :setdw "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" CEIPEnable 0
:: Telemetrie de compatibilite des applications + inventaire
call :setdw "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" AITEnable 0
call :setdw "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" DisableInventory 1
:: Rapports d'erreurs Windows
call :setdw "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" Disabled 1

echo.
echo === [2/5] Confidentialite ===
set "SYS=HKLM\SOFTWARE\Policies\Microsoft\Windows\System"
:: ID de publicite
call :setdw "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" DisabledByGroupPolicy 1
:: Historique d'activite
call :setdw "%SYS%" EnableActivityFeed 0
call :setdw "%SYS%" PublishUserActivities 0
call :setdw "%SYS%" UploadUserActivities 0
:: Presse-papiers cloud (l'historique local reste possible)
call :setdw "%SYS%" AllowCrossDeviceClipboard 0
:: Experiences personnalisees (compte courant)
call :setdw "HKCU\Software\Policies\Microsoft\Windows\CloudContent" DisableTailoredExperiencesWithDiagnosticData 1
:: Recherche Bing dans Demarrer (compte courant)
call :setdw "HKCU\Software\Policies\Microsoft\Windows\Explorer" DisableSearchBoxSuggestions 1
:: Widgets
call :setdw "HKLM\SOFTWARE\Policies\Microsoft\Dsh" AllowNewsAndInterests 0

echo.
echo === [3/5] Recall ===
:: Strategies : interdit l'activation de Recall et l'enregistrement d'instantanes
call :setdw "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" AllowRecallEnablement 0
call :setdw "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" DisableAIDataAnalysis 1
call :setdw "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" DisableAIDataAnalysis 1
:: Fonctionnalite : n'existe que sur les PC Copilot+
dism /online /get-featureinfo /featurename:Recall >nul 2>&1
if errorlevel 1 (
  echo   --  Recall absent sur ce PC, rien a desinstaller
  goto :apres_recall
)
dism /online /disable-feature /featurename:Recall /norestart /quiet >nul 2>&1
if %errorlevel%==0 (echo   OK  Recall desactive) else if %errorlevel%==3010 (echo   OK  Recall desactive, redemarrage requis) else (echo   ERR Recall, code %errorlevel%)
:apres_recall

echo.
echo === [4/5] Traces locales (compte courant) ===
set "ADV=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
:: Ne plus suivre les documents recents ni les programmes lances
call :setdw "%ADV%" Start_TrackDocs 0
call :setdw "%ADV%" Start_TrackProgs 0
:: Acces rapide : ne plus afficher les fichiers et dossiers recents/frequents
call :setdw "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" ShowRecent 0
call :setdw "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" ShowFrequent 0

echo.
echo === [5/5] Services et taches planifiees ===
:: DiagTrack = collecte et envoi de la telemetrie
sc stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1 && echo   OK  DiagTrack desactive || echo   ERR DiagTrack
:: Routage des messages push WAP, utilise par la telemetrie
sc stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1 && echo   OK  dmwappushservice desactive || echo   ERR dmwappushservice

for %%T in (
  "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
  "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
  "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
  "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
  "\Microsoft\Windows\Autochk\Proxy"
  "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
  "\Microsoft\Windows\Feedback\Siuf\DmClient"
  "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
) do (
  schtasks /change /tn %%T /disable >nul 2>&1 && echo   OK  %%~T || echo   --  %%~T ^(absente^)
)

echo.
echo Termine. Un redemarrage est necessaire pour tout appliquer.
choice /c ON /m "Redemarrer maintenant"
if errorlevel 2 goto :fin
shutdown /r /t 10 /c "Redemarrage apres stop-telemetrie"
:fin
pause
exit /b 0

:: ------------------------------------------------------------------
:: Sous-routine : ecrit une valeur DWORD et affiche le resultat
::   %1 = cle (entre guillemets)  %2 = nom  %3 = valeur
:: ------------------------------------------------------------------
:setdw
reg add %1 /v %2 /t REG_DWORD /d %3 /f >nul 2>&1 && echo   OK  %~2 = %3 || echo   ERR %~2
exit /b
