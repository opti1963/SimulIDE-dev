@echo off
REM ========================================================================
REM  SimulIDE Build Script
REM ========================================================================
REM  Dieses Script kompiliert SimulIDE 1.1.0 mit Qt 5.15.18 und MinGW
REM  
REM  Start-Verzeichnis: C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev
REM  
REM  Erstellt von: GitHub Copilot
REM  Datum: 25.12.2025
REM ========================================================================

echo.
echo ========================================================================
echo  SimulIDE Build Script
echo ========================================================================
echo.

REM PATH-Variable mit MSYS2-Tools erweitern
echo [1/5] Konfiguriere PATH-Variable...
set PATH=C:\msys64\mingw64\bin;C:\msys64\usr\bin;%PATH%

REM Versionen anzeigen
echo.
echo [2/5] Pruefe Build-Tools...
qmake --version
echo.
g++ --version | findstr "g++"
echo.
make --version | findstr "GNU Make"
echo.

REM Build-Verzeichnis erstellen
echo.
echo [3/5] Erstelle Build-Verzeichnis...
if not exist "build_mingw64" (
    mkdir build_mingw64
    echo Build-Verzeichnis erstellt: build_mingw64
) else (
    echo Build-Verzeichnis existiert bereits: build_mingw64
)

REM In Build-Verzeichnis wechseln
cd build_mingw64

REM qmake ausfuehren
echo.
echo [4/5] Fuehre qmake aus...
qmake ..\SimulIDE_1.1.0.pro
if errorlevel 1 (
    echo FEHLER: qmake ist fehlgeschlagen!
    cd ..
    pause
    exit /b 1
)

REM Kompilieren
echo.
echo [5/5] Kompiliere SimulIDE...
echo (Dies kann einige Minuten dauern...)
echo.
make -j4
if errorlevel 1 (
    echo.
    echo FEHLER: Kompilierung ist fehlgeschlagen!
    cd ..
    pause
    exit /b 1
)

REM Zurueck ins Hauptverzeichnis
cd ..

REM Erfolgsmeldung
echo.
echo ========================================================================
echo  Build erfolgreich abgeschlossen!
echo ========================================================================
echo.
echo Die fertige simulide.exe befindet sich in:
echo   build_mingw64\executables\SimulIDE_1.1.0\simulide.exe
echo.
echo Zum Starten der Anwendung:
echo   cd build_mingw64\executables\SimulIDE_1.1.0
echo   simulide.exe
echo.
echo ========================================================================

pause
