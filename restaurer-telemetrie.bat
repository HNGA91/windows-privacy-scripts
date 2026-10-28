@echo off
setlocal
title Restaurer telemetrie Windows
:: ==================================================================
::  restaurer-telemetrie.bat
::  Annule stop-telemetrie.bat et remet les valeurs par defaut.
::  - A lancer en administrateur, depuis le meme compte.
::  - Recall n'est PAS reinstalle (a faire a la main si besoin).
:: ==================================================================

net session >nul 2>&1 || (echo Lance ce script en administrateur. & pause & exit /b 1)

echo.
echo === [1/5] Telemetrie ===
:: Supprimer une strategie = revenir au comportement par defaut
set "DC=HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
call :del "%DC%" AllowTelemetry
call :del "%DC%" DoNotShowFeedbackNotifications
call :del "%DC%" LimitDiagnosticLogCollection
call :del "%DC%" LimitDumpCollection
call :del "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" CEIPEnable
call :del "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" AITEnable
call :del "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" DisableInventory
call :del "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" Disabled

echo.
echo === [2/5] Confidentialite ===
set "SYS=HKLM\SOFTWARE\Policies\Microsoft\Windows\System"
call :del "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" DisabledByGroupPolicy
call :del "%SYS%" EnableActivityFeed
call :del "%SYS%" PublishUserActivities
call :del "%SYS%" UploadUserActivities
call :del "%SYS%" AllowCrossDeviceClipboard
call :del "HKCU\Software\Policies\Microsoft\Windows\CloudContent" DisableTailoredExperiencesWithDiagnosticData
call :del "HKCU\Software\Policies\Microsoft\Windows\Explorer" DisableSearchBoxSuggestions
call :del "HKLM\SOFTWARE\Policies\Microsoft\Dsh" AllowNewsAndInterests

echo.
echo === [3/5] Recall (strategies uniquement) ===
call :del "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" AllowRecallEnablement
call :del "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" DisableAIDataAnalysis
call :del "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" DisableAIDataAnalysis

echo.
echo === [4/5] Traces locales (valeurs par defaut = 1) ===
set "ADV=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
call :setdw "%ADV%" Start_TrackDocs 1
call :setdw "%ADV%" Start_TrackProgs 1
call :setdw "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" ShowRecent 1
call :setdw "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" ShowFrequent 1

echo.
echo === [5/5] Services et taches planifiees ===
:: Types de demarrage par defaut : DiagTrack = automatique, dmwappushservice = manuel
sc config DiagTrack start= auto >nul 2>&1 && echo   OK  DiagTrack automatique || echo   ERR DiagTrack
sc start DiagTrack >nul 2>&1
sc config dmwappushservice start= demand >nul 2>&1 && echo   OK  dmwappushservice manuel || echo   ERR dmwappushservice

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
  schtasks /change /tn %%T /enable >nul 2>&1 && echo   OK  %%~T || echo   --  %%~T ^(absente^)
)

echo.
echo Termine. Un redemarrage est necessaire pour tout appliquer.
choice /c ON /m "Redemarrer maintenant"
if errorlevel 2 goto :fin
shutdown /r /t 10 /c "Redemarrage apres restaurer-telemetrie"
:fin
pause
exit /b 0

:: ------------------------------------------------------------------
:: Sous-routines
:: ------------------------------------------------------------------
:del
reg delete %1 /v %2 /f >nul 2>&1 && echo   OK  %~2 supprimee || echo   --  %~2 ^(deja absente^)
exit /b

:setdw
reg add %1 /v %2 /t REG_DWORD /d %3 /f >nul 2>&1 && echo   OK  %~2 = %3 || echo   ERR %~2
exit /b
