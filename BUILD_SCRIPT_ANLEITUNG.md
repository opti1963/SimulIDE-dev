# SimulIDE Build-Anleitung (Kurzversion)

## Build-Script für SimulIDE 1.1.0

### Voraussetzungen
- MSYS2 installiert unter `C:\msys64`
- Qt 5.15.18 und MinGW in MSYS2
- SimulIDE Quellcode unter `C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev`

---

## Ausführung des Build-Scripts

### Script-Datei
```
C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev\build_simulide.bat
```

### Start-Verzeichnis
Das Script **muss** aus diesem Verzeichnis gestartet werden:
```
C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev
```

### Starten des Scripts

**Option 1 - PowerShell/CMD:**
```cmd
cd C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev
.\build_simulide.bat
```

**Option 2 - Windows Explorer:**
1. Navigiere zu `C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev`
2. Doppelklick auf `build_simulide.bat`

---

## Was das Script macht

Das Build-Script führt automatisch folgende Schritte aus:

### 1. PATH-Konfiguration
Erweitert die PATH-Variable temporär mit MSYS2-Tools:
- `C:\msys64\mingw64\bin`
- `C:\msys64\usr\bin`

### 2. Tool-Prüfung
Zeigt die Versionen der Build-Tools an:
- **qmake** 3.1 (Qt 5.15.18)
- **g++** 15.2.0
- **make** 4.4.1

### 3. Build-Verzeichnis
Erstellt das Verzeichnis `build_mingw64` (falls nicht vorhanden)

### 4. qmake-Konfiguration
Führt aus: `qmake ..\SimulIDE_1.1.0.pro`
- Erstellt Makefiles für den Build-Prozess

### 5. Kompilierung
Führt aus: `make -j4`
- Kompiliert mit 4 parallelen Jobs
- Dauer: ca. 5-15 Minuten (abhängig vom System)

---

## Ausgabe nach erfolgreichem Build

Die fertige **simulide.exe** befindet sich in:
```
C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev\build_mingw64\executables\SimulIDE_1.1.0\simulide.exe
```

### SimulIDE starten

**Aus dem Build-Verzeichnis:**
```cmd
cd build_mingw64\executables\SimulIDE_1.1.0
simulide.exe
```

**Oder direkt mit vollständigem Pfad:**
```cmd
C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev\build_mingw64\executables\SimulIDE_1.1.0\simulide.exe
```

---

## Fehlerbehandlung

### Fehler bei qmake
```
FEHLER: qmake ist fehlgeschlagen!
```
**Lösung:**
- Prüfe, ob `SimulIDE_1.1.0.pro` im Hauptverzeichnis existiert
- Stelle sicher, dass Qt 5.15.x in MSYS2 installiert ist

### Fehler bei make
```
FEHLER: Kompilierung ist fehlgeschlagen!
```
**Lösung:**
- Prüfe die Fehlermeldungen im Terminal
- Stelle sicher, dass alle Qt-Module installiert sind:
  ```bash
  pacman -S mingw-w64-x86_64-qt5-multimedia
  pacman -S mingw-w64-x86_64-qt5-serialport
  pacman -S mingw-w64-x86_64-qt5-svg
  ```

### PATH-Probleme
Falls Tools nicht gefunden werden:
```cmd
set PATH=C:\msys64\mingw64\bin;C:\msys64\usr\bin;%PATH%
```

---

## Manuelle Build-Schritte (ohne Script)

Falls du den Build manuell durchführen möchtest:

```cmd
REM 1. PATH setzen
set PATH=C:\msys64\mingw64\bin;C:\msys64\usr\bin;%PATH%

REM 2. Build-Verzeichnis erstellen
cd C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev
mkdir build_mingw64
cd build_mingw64

REM 3. qmake ausführen
qmake ..\SimulIDE_1.1.0.pro

REM 4. Kompilieren
make -j4
```

---

## Wichtige Hinweise

### ⚠️ Temporäre PATH-Änderung
Die PATH-Änderung durch das Script gilt **nur** für die aktuelle CMD/PowerShell-Sitzung.

Für **permanente** PATH-Änderung:
1. Systemsteuerung → System → Erweiterte Systemeinstellungen
2. Umgebungsvariablen → Systemvariablen → PATH bearbeiten
3. Neu hinzufügen:
   - `C:\msys64\mingw64\bin`
   - `C:\msys64\usr\bin`

### 📦 Build-Artefakte
Nach dem Build enthält `build_mingw64`:
- **Makefiles** (von qmake generiert)
- **Objektdateien** (.o)
- **Bibliotheken** (.a, .dll)
- **Ausführbare Datei** (simulide.exe)

### 🧹 Clean Build
Um einen sauberen Neuaufbau zu erzwingen:
```cmd
cd build_mingw64
make clean
make -j4
```

Oder Build-Verzeichnis komplett löschen:
```cmd
rmdir /s /q build_mingw64
.\build_simulide.bat
```

---

## Weitere Informationen

Für detaillierte Informationen siehe:
- **BUILD_ANLEITUNG.md** - Ausführliche Build-Anleitung
- **Qt5_Installation_MSYS2.md** - MSYS2 und Qt5-Installation
- **Debug-Button-Ablauf.md** - Debug-Funktionalität in SimulIDE

---

*Erstellt am: 25.12.2025*  
*SimulIDE Version: 1.1.0*  
*Qt Version: 5.15.18 (MSYS2)*
