# Qt 5.15.x Installation via MSYS2 - Für SimulIDE

## Problem
Qt 5.15.x ist nicht im Online Installer verfügbar.

## Lösung: MSYS2 Installation

### Schritt 1: MSYS2 installieren

1. **Download MSYS2:**
   https://www.msys2.org/
   
2. **Installieren:**
   - Datei: `msys2-x86_64-XXXXXXXX.exe`
   - Standard-Pfad: `C:\msys64`
   - Installation durchführen

3. **MSYS2 starten:**
   - Start-Menü → "MSYS2 MINGW64" öffnen

---

### Schritt 2: Qt 5.15 mit MinGW installieren

In MSYS2 MINGW64 Terminal:

```bash
# System aktualisieren
pacman -Syu

# Bei Nachfrage: Terminal schließen und neu öffnen
# Dann erneut:
pacman -Syu

# Qt 5 + Tools installieren
pacman -S mingw-w64-x86_64-qt5 mingw-w64-x86_64-toolchain

# Zusätzliche Module für SimulIDE
pacman -S mingw-w64-x86_64-qt5-multimedia
pacman -S mingw-w64-x86_64-qt5-serialport
pacman -S mingw-w64-x86_64-qt5-svg

# qmake und Make-Tools
pacman -S mingw-w64-x86_64-cmake
pacman -S make
```

**Installation dauert:** 10-15 Minuten
**Größe:** ~2 GB

---

### Schritt 3: PATH-Variable konfigurieren

#### Option A: Temporär (in PowerShell)

```powershell
$env:PATH = "C:\msys64\mingw64\bin;" + $env:PATH

# Testen:
qmake --version
g++ --version
```

#### Option B: Permanent (System)

1. Windows-Taste → "Umgebungsvariablen"
2. Bei "Path" → "Bearbeiten"
3. "Neu" hinzufügen:
   ```
   C:\msys64\mingw64\bin
   ```
4. OK → OK → PowerShell neu starten

---

### Schritt 4: SimulIDE kompilieren

```powershell
# In PowerShell (mit PATH gesetzt)
cd C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev\build_XX

# qmake ausführen
qmake SimulIDE_Build.pro

# Kompilieren
make -j4
```

**Hinweis:** Bei MSYS2 heißt das Kommando `make` (nicht `mingw32-make`)!

---

### Schritt 5: Fertige EXE finden

```
build_XX\executables\SimulIDE_2.0.0-\simulide.exe
```

---

## Vorteile MSYS2:

✅ **Immer aktuelle Qt-Versionen**
✅ **Einfaches Update:** `pacman -Syu`
✅ **Kleine Installation** (~2 GB vs. 3+ GB Qt Installer)
✅ **Mehr Kontrolle** über installierte Pakete
✅ **Open Source** - keine Account-Erstellung
✅ **Integriert mit Windows** (kein Linux-Subsystem)

---

## Nach Installation - Tools testen:

```powershell
# In PowerShell
qmake --version
# Sollte zeigen: QMake version 3.1, Using Qt version 5.15.x

g++ --version
# Sollte zeigen: g++ (Rev...) 13.x.x oder neuer

make --version
# Sollte zeigen: GNU Make 4.x
```

---

## Troubleshooting:

### "qmake not found"
```powershell
# PATH prüfen
$env:PATH -split ';' | Select-String msys

# Falls leer, PATH setzen:
$env:PATH = "C:\msys64\mingw64\bin;" + $env:PATH
```

### "Cannot find -lQt5Core"
```bash
# In MSYS2 MINGW64:
pacman -S mingw-w64-x86_64-qt5
```

### Make-Kommando nicht gefunden
- Bei MSYS2: `make` (nicht `mingw32-make`)
- Alternativ installieren: `pacman -S make`

---

## Deinstallation (falls nötig):

```bash
# In MSYS2:
pacman -R mingw-w64-x86_64-qt5
pacman -R mingw-w64-x86_64-toolchain
```

Oder komplett: MSYS2-Verzeichnis löschen (`C:\msys64`)

---

## Alternative: vcpkg (Microsoft)

Falls MSYS2 nicht funktioniert:

```powershell
# vcpkg installieren
git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg
cd C:\vcpkg
.\bootstrap-vcpkg.bat

# Qt 5 installieren
.\vcpkg install qt5-base:x64-windows
.\vcpkg install qt5-multimedia:x64-windows
.\vcpkg install qt5-serialport:x64-windows
.\vcpkg integrate install
```

---

## Vergleich der Optionen:

| Methode | Größe | Komplexität | Empfehlung |
|---------|-------|-------------|------------|
| **Qt Offline Installer** | 3 GB | Mittel | ⭐⭐⭐ |
| **MSYS2** | 2 GB | Einfach | ⭐⭐⭐⭐⭐ |
| **vcpkg** | 2 GB | Komplex | ⭐⭐ |
| **Chocolatey** | 2 GB | Einfach | ⭐⭐⭐ |

**Meine Empfehlung: MSYS2** (am einfachsten und aktuellsten)

---

## Schnellstart-Skript

Speichern als `install_qt_msys2.ps1`:

```powershell
# Qt 5 über MSYS2 installieren (automatisch)

# Prüfe ob MSYS2 installiert ist
if (-not (Test-Path "C:\msys64\msys2_shell.cmd")) {
    Write-Host "❌ MSYS2 nicht gefunden!" -ForegroundColor Red
    Write-Host "Bitte installieren von: https://www.msys2.org/" -ForegroundColor Yellow
    exit 1
}

# MSYS2 Befehle ausführen
$msys2Commands = @"
pacman -Syu --noconfirm
pacman -S --noconfirm mingw-w64-x86_64-qt5
pacman -S --noconfirm mingw-w64-x86_64-toolchain
pacman -S --noconfirm mingw-w64-x86_64-qt5-multimedia
pacman -S --noconfirm mingw-w64-x86_64-qt5-serialport
pacman -S --noconfirm mingw-w64-x86_64-qt5-svg
pacman -S --noconfirm make
"@

# Ausführen
C:\msys64\msys2_shell.cmd -mingw64 -defterm -no-start -c $msys2Commands

Write-Host "✅ Qt 5 Installation abgeschlossen!" -ForegroundColor Green
Write-Host "`nPATH hinzufügen:" -ForegroundColor Yellow
Write-Host '$env:PATH = "C:\msys64\mingw64\bin;" + $env:PATH' -ForegroundColor Cyan
```
