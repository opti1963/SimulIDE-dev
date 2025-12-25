# SimulIDE Build-Anleitung - Nur EXE neu erstellen

## Übersicht

Nach Änderungen am Quellcode in VSCode können Sie nur die `simulide.exe` neu kompilieren und in Ihre bestehende Installation kopieren. Die Verzeichnisse `data/` und `examples/` bleiben unverändert.

---

## Voraussetzungen

### 1. Qt5 Development Tools installieren

**Option A: Qt Online Installer (Empfohlen)**
- Download: https://www.qt.io/download-qt-installer
- Installieren Sie: **Qt 5.15.2** (oder neueste 5.x Version)
- Komponenten auswählen:
  - ✅ MinGW 8.1.0 64-bit (oder neuere Version)
  - ✅ Qt 5.15.2 → MinGW 64-bit
  - ✅ Qt Creator (optional, aber hilfreich)

**Option B: MSYS2 (Für fortgeschrittene Benutzer)**
```powershell
# In PowerShell als Administrator
choco install msys2
# Dann in MSYS2:
pacman -S mingw-w64-x86_64-qt5
```

### 2. PATH-Variable prüfen

Nach Qt-Installation muss der Qt-Pfad in der PATH-Variable sein:

```powershell
# PowerShell - Pfad prüfen
$env:PATH -split ';' | Select-String Qt

# Typischer Pfad:
# C:\Qt\5.15.2\mingw81_64\bin
# C:\Qt\Tools\mingw810_64\bin
```

**Falls nicht vorhanden, hinzufügen:**
```powershell
# Temporär (nur aktuelle Session)
$env:PATH += ";C:\Qt\5.15.2\mingw81_64\bin;C:\Qt\Tools\mingw810_64\bin"

# Permanent (Systemeinstellungen → Umgebungsvariablen)
```

### 3. Tools überprüfen

```powershell
# Testen ob qmake verfügbar ist
qmake --version
# Sollte zeigen: QMake version 3.1, Using Qt version 5.15.x

# MinGW GCC prüfen
g++ --version
# Sollte MinGW GCC Version zeigen

# Make-Tool prüfen
mingw32-make --version
```

---

## Build-Prozess

### Schritt 1: Terminal im Build-Verzeichnis öffnen

```powershell
# In VSCode: Terminal öffnen (Strg + Ö)
cd "c:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev\build_XX"
```

### Schritt 2: Build-System generieren (nur beim ersten Mal)

```powershell
# Makefile generieren
qmake SimulIDE_Build.pro
```

**Was passiert:**
- `qmake` liest `SimulIDE_Build.pro` und `SimulIDE.pri`
- Erstellt `Makefile` für MinGW
- Konfiguriert alle Compiler-Einstellungen
- Definiert Output-Verzeichnis

**Ausgabe sollte ähnlich sein:**
```
-----------------------------------
    
    SimulIDE_2.0.0- for Windows
    
    Host:      Windows
    Date:      25-12-25
    Qt version: 5.15.2
    
    Destination Folder:
C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev\build_XX\executables\SimulIDE_2.0.0-
-----------------------------------
```

### Schritt 3: Kompilieren

**Vollständiger Build (alle Dateien):**
```powershell
mingw32-make -j4
```

**Oder nur geänderte Dateien (schneller):**
```powershell
mingw32-make
```

**Parameter:**
- `-j4`: Nutzt 4 CPU-Kerne parallel (passen Sie an Ihren PC an)
- Ohne `-j`: Serieller Build (langsamer, aber stabiler)

**Build-Dauer:**
- Erstmaliger Build: 10-30 Minuten (je nach PC)
- Inkrementeller Build (nur Änderungen): 1-5 Minuten

### Schritt 4: Build-Output finden

Die kompilierte `simulide.exe` befindet sich in:
```
build_XX\executables\SimulIDE_2.0.0-\simulide.exe
```

---

## Installation der neuen EXE

### Option 1: Direktes Überschreiben (Einfach)

```powershell
# SimulIDE muss GESCHLOSSEN sein!

# Beispiel: Installation in C:\SimulIDE
$InstallDir = "C:\SimulIDE"
$BuildExe = "build_XX\executables\SimulIDE_2.0.0-\simulide.exe"

# Alte EXE sichern (optional)
Copy-Item "$InstallDir\simulide.exe" "$InstallDir\simulide_backup.exe" -Force

# Neue EXE kopieren
Copy-Item $BuildExe "$InstallDir\simulide.exe" -Force

Write-Host "✅ simulide.exe erfolgreich aktualisiert!" -ForegroundColor Green
```

### Option 2: Mit Datums-Backup

```powershell
# Backup mit Zeitstempel
$InstallDir = "C:\SimulIDE"
$BuildExe = "build_XX\executables\SimulIDE_2.0.0-\simulide.exe"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$BackupName = "simulide_backup_$Timestamp.exe"

Copy-Item "$InstallDir\simulide.exe" "$InstallDir\$BackupName" -Force
Copy-Item $BuildExe "$InstallDir\simulide.exe" -Force

Write-Host "✅ Backup erstellt: $BackupName" -ForegroundColor Cyan
Write-Host "✅ simulide.exe aktualisiert!" -ForegroundColor Green
```

### Option 3: Vollständiges Test-Setup

Falls Sie die neue Version erst testen wollen:

```powershell
# Kopiere kompletten Build-Output in Test-Ordner
$TestDir = "C:\SimulIDE_Test"
$BuildDir = "build_XX\executables\SimulIDE_2.0.0-"
$OriginalInstall = "C:\SimulIDE"

# Test-Verzeichnis erstellen
New-Item -ItemType Directory -Force -Path $TestDir

# EXE kopieren
Copy-Item "$BuildDir\simulide.exe" "$TestDir\" -Force

# data und examples aus Original-Installation kopieren
Copy-Item "$OriginalInstall\data" "$TestDir\data" -Recurse -Force
Copy-Item "$OriginalInstall\examples" "$TestDir\examples" -Recurse -Force

Write-Host "✅ Test-Installation erstellt in: $TestDir" -ForegroundColor Green
Write-Host "   Starten Sie: $TestDir\simulide.exe" -ForegroundColor Cyan
```

---

## Schnell-Workflow für Entwicklung

### Einmalige Vorbereitung

1. **Qt installieren** (siehe oben)
2. **PATH konfigurieren**
3. **Einmalig qmake ausführen**

### Bei jeder Code-Änderung

**PowerShell-Skript erstellen:** `build_and_deploy.ps1`

```powershell
# build_and_deploy.ps1
# Speichern in: SimulIDE-dev\build_and_deploy.ps1

param(
    [string]$InstallDir = "C:\SimulIDE"
)

$ErrorActionPreference = "Stop"

Write-Host "🔨 Starte Build..." -ForegroundColor Yellow

# Zum Build-Verzeichnis wechseln
Set-Location "$PSScriptRoot\build_XX"

# Kompilieren (nur geänderte Dateien)
mingw32-make -j4

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build erfolgreich!" -ForegroundColor Green
    
    # EXE-Pfade
    $BuildExe = "executables\SimulIDE_2.0.0-\simulide.exe"
    $TargetExe = "$InstallDir\simulide.exe"
    
    # Backup erstellen
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $BackupExe = "$InstallDir\backups\simulide_$Timestamp.exe"
    New-Item -ItemType Directory -Force -Path "$InstallDir\backups" | Out-Null
    Copy-Item $TargetExe $BackupExe -Force -ErrorAction SilentlyContinue
    
    # Neue EXE kopieren
    Copy-Item $BuildExe $TargetExe -Force
    
    Write-Host "✅ simulide.exe aktualisiert!" -ForegroundColor Green
    Write-Host "📁 Backup: $BackupExe" -ForegroundColor Cyan
    
    # Optional: SimulIDE automatisch starten
    # Start-Process $TargetExe
} else {
    Write-Host "❌ Build fehlgeschlagen!" -ForegroundColor Red
    exit 1
}
```

**Verwendung:**

```powershell
# Aus SimulIDE-dev Verzeichnis
.\build_and_deploy.ps1

# Mit anderem Installations-Pfad
.\build_and_deploy.ps1 -InstallDir "D:\Programme\SimulIDE"
```

---

## Build-Konfiguration anpassen

### Debug-Build vs. Release-Build

**Release-Build (Standard):**
```powershell
qmake CONFIG+=release SimulIDE_Build.pro
mingw32-make
```

**Debug-Build (für Debugging mit GDB):**
```powershell
qmake CONFIG+=debug SimulIDE_Build.pro
mingw32-make
```

**Release-Build Vorteile:**
- Kleiner (keine Debug-Symbole)
- Schneller (optimiert)
- Für Endanwender

**Debug-Build Vorteile:**
- Mit Debug-Symbolen
- Debuggen mit GDB möglich
- Für Entwicklung

### Build-Verzeichnis bereinigen

```powershell
# Alle kompilierten Dateien löschen
mingw32-make clean

# Makefile und Build-Konfiguration löschen (für Neustart)
mingw32-make distclean
Remove-Item Makefile -Force

# Dann neu generieren
qmake SimulIDE_Build.pro
```

---

## Häufige Probleme und Lösungen

### Problem 1: "qmake: command not found"

**Lösung:** Qt bin-Verzeichnis zur PATH hinzufügen
```powershell
$env:PATH += ";C:\Qt\5.15.2\mingw81_64\bin"
```

### Problem 2: "g++: command not found"

**Lösung:** MinGW bin-Verzeichnis zur PATH hinzufügen
```powershell
$env:PATH += ";C:\Qt\Tools\mingw810_64\bin"
```

### Problem 3: "cannot find -lQt5Core"

**Lösung:** Qt-Libraries nicht gefunden
```powershell
# Prüfen Sie QTDIR Umgebungsvariable
$env:QTDIR = "C:\Qt\5.15.2\mingw81_64"
qmake SimulIDE_Build.pro
```

### Problem 4: Build-Fehler "undefined reference"

**Lösung:** Clean Build durchführen
```powershell
mingw32-make distclean
qmake SimulIDE_Build.pro
mingw32-make -j4
```

### Problem 5: "simulide.exe funktioniert nicht"

**Mögliche Ursachen:**
1. **Qt5-DLLs fehlen** - müssen im gleichen Verzeichnis sein
2. **Falsche Qt-Version** - 64-bit EXE braucht 64-bit Qt-DLLs

**Lösung:** Qt-DLLs kopieren
```powershell
# Von Qt-Installation nach SimulIDE-Verzeichnis
$QtBin = "C:\Qt\5.15.2\mingw81_64\bin"
$InstallDir = "C:\SimulIDE"

# Wichtigste DLLs
Copy-Item "$QtBin\Qt5Core.dll" $InstallDir
Copy-Item "$QtBin\Qt5Gui.dll" $InstallDir
Copy-Item "$QtBin\Qt5Widgets.dll" $InstallDir
Copy-Item "$QtBin\Qt5Svg.dll" $InstallDir
Copy-Item "$QtBin\Qt5Xml.dll" $InstallDir
Copy-Item "$QtBin\Qt5Multimedia.dll" $InstallDir
Copy-Item "$QtBin\Qt5Network.dll" $InstallDir
Copy-Item "$QtBin\Qt5SerialPort.dll" $InstallDir

# MinGW-Laufzeitbibliotheken
$MinGW = "C:\Qt\Tools\mingw810_64\bin"
Copy-Item "$MinGW\libgcc_s_seh-1.dll" $InstallDir
Copy-Item "$MinGW\libstdc++-6.dll" $InstallDir
Copy-Item "$MinGW\libwinpthread-1.dll" $InstallDir
```

### Problem 6: "LNK1181: cannot open input file"

**Lösung:** Objekt-Dateien inkonsistent
```powershell
Remove-Item -Recurse -Force build\
qmake SimulIDE_Build.pro
mingw32-make -j4
```

---

## VSCode Integration (Optional)

### tasks.json erstellen

Erstellen Sie `.vscode/tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build SimulIDE",
            "type": "shell",
            "command": "mingw32-make",
            "args": ["-j4"],
            "options": {
                "cwd": "${workspaceFolder}/build_XX"
            },
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": ["$gcc"],
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        },
        {
            "label": "Clean Build",
            "type": "shell",
            "command": "mingw32-make",
            "args": ["clean"],
            "options": {
                "cwd": "${workspaceFolder}/build_XX"
            },
            "problemMatcher": []
        },
        {
            "label": "Rebuild (Clean + Build)",
            "dependsOn": ["Clean Build", "Build SimulIDE"],
            "dependsOrder": "sequence",
            "problemMatcher": []
        },
        {
            "label": "Deploy to Installation",
            "type": "shell",
            "command": "Copy-Item",
            "args": [
                "build_XX/executables/SimulIDE_2.0.0-/simulide.exe",
                "C:/SimulIDE/simulide.exe",
                "-Force"
            ],
            "problemMatcher": [],
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        }
    ]
}
```

**Verwendung in VSCode:**
- `Strg + Shift + B` → "Build SimulIDE"
- `Strg + Shift + P` → "Tasks: Run Task" → Task auswählen

---

## Performance-Tipps

### Schnellerer Build

1. **Mehr Cores nutzen:**
   ```powershell
   # Anzahl CPU-Kerne ermitteln
   $cores = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
   mingw32-make -j$cores
   ```

2. **RAM-Disk für Build verwenden** (für SSDs weniger wichtig):
   ```powershell
   # ImDisk installieren, dann:
   imdisk -a -s 4G -m B: -p "/fs:ntfs /q /y"
   # Build-Verzeichnis nach B:\ kopieren
   ```

3. **ccache nutzen** (für wiederholte Builds):
   ```bash
   # In MSYS2
   pacman -S ccache
   # Dann in qmake konfigurieren
   ```

---

## Zusammenfassung: Schnellster Workflow

### Einmalig einrichten:
```powershell
# 1. Qt installieren
# 2. PATH konfigurieren
# 3. Build-System generieren
cd build_XX
qmake SimulIDE_Build.pro
```

### Bei jeder Änderung:
```powershell
# 1. Code in VSCode ändern
# 2. Build
cd build_XX
mingw32-make -j4

# 3. EXE kopieren
Copy-Item "executables\SimulIDE_2.0.0-\simulide.exe" "C:\SimulIDE\simulide.exe" -Force

# 4. Testen
C:\SimulIDE\simulide.exe
```

**Oder mit Skript:**
```powershell
.\build_and_deploy.ps1
```

---

## Verzeichnis-Struktur nach Build

```
SimulIDE-dev\
├── src\                          # Quellcode (Ihre Änderungen hier)
├── build_XX\
│   ├── SimulIDE_Build.pro       # Qt-Projekt-Datei
│   ├── Makefile                 # Generiert von qmake
│   ├── build\                   # Temporäre Build-Dateien
│   │   ├── objects\             # .o Objekt-Dateien
│   │   └── moc\                 # Qt Meta-Object-Compiler Dateien
│   └── executables\
│       └── SimulIDE_2.0.0-\
│           └── simulide.exe     # ✅ FERTIGE EXE
└── resources\

Ihre Installation (C:\SimulIDE\):
├── simulide.exe                 # ⬅️ HIERHIN KOPIEREN
├── data\                        # Bleibt unverändert
└── examples\                    # Bleibt unverändert
```

---

## Checkliste: Erster Build

- [ ] Qt 5.15.x installiert
- [ ] MinGW installiert (kommt mit Qt)
- [ ] PATH-Variable konfiguriert
- [ ] `qmake --version` funktioniert
- [ ] `g++ --version` funktioniert
- [ ] `cd build_XX` ausgeführt
- [ ] `qmake SimulIDE_Build.pro` erfolgreich
- [ ] `mingw32-make -j4` erfolgreich
- [ ] `simulide.exe` gefunden in `executables\SimulIDE_2.0.0-\`
- [ ] EXE nach Installation kopiert
- [ ] SimulIDE startet und funktioniert

---

## Weitere Ressourcen

- **Qt Dokumentation:** https://doc.qt.io/qt-5/
- **qmake Manual:** https://doc.qt.io/qt-5/qmake-manual.html
- **SimulIDE Forum:** https://simulide.forumotion.com/

---

**Viel Erfolg beim Entwickeln! 🚀**
