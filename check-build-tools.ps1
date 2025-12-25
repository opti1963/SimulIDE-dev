# SimulIDE Build-Tools Check
# Überprüft ob alle notwendigen Tools installiert sind

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  SimulIDE Build-Tools Diagnose" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$allOK = $true

# Funktion: Tool prüfen
function Test-Tool {
    param(
        [string]$Name,
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "[$Name] " -NoNewline
    
    try {
        $result = & where.exe $Command 2>$null
        if ($result) {
            Write-Host "✅ GEFUNDEN" -ForegroundColor Green
            Write-Host "   Pfad: $result" -ForegroundColor Gray
            
            # Version anzeigen
            try {
                $version = & $Command --version 2>&1 | Select-Object -First 3
                Write-Host "   $version" -ForegroundColor Gray
            } catch {}
            
            return $true
        } else {
            Write-Host "❌ NICHT GEFUNDEN" -ForegroundColor Red
            Write-Host "   Benötigt für: $Description" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "❌ NICHT GEFUNDEN" -ForegroundColor Red
        Write-Host "   Benötigt für: $Description" -ForegroundColor Yellow
        return $false
    }
}

# Hauptprüfungen
Write-Host "Prüfe Build-Tools...`n" -ForegroundColor Yellow

$qmake = Test-Tool -Name "qmake" -Command "qmake" -Description "Qt Build-System Konfiguration"
$gcc = Test-Tool -Name "g++" -Command "g++" -Description "C++ Compiler"
$make = Test-Tool -Name "mingw32-make" -Command "mingw32-make" -Description "Build-Prozess"

Write-Host "`nPrüfe zusätzliche Tools...`n" -ForegroundColor Yellow

$windres = Test-Tool -Name "windres" -Command "windres" -Description "Windows Resource Compiler (optional)"

# Qt-Installation suchen
Write-Host "`n[Qt Installation] " -NoNewline

$qtPaths = @(
    "C:\Qt",
    "C:\Qt5",
    "C:\Program Files\Qt",
    "C:\Program Files (x86)\Qt",
    "D:\Qt",
    "$env:USERPROFILE\Qt"
)

$qtFound = $false
foreach ($path in $qtPaths) {
    if (Test-Path $path) {
        Write-Host "✅ GEFUNDEN" -ForegroundColor Green
        Write-Host "   Pfad: $path" -ForegroundColor Gray
        
        # Suche nach Qt-Versionen
        $versions = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue | 
                    Where-Object { $_.Name -match '^\d+\.\d+' } |
                    Select-Object -First 5
        
        if ($versions) {
            Write-Host "   Installierte Versionen:" -ForegroundColor Gray
            foreach ($ver in $versions) {
                Write-Host "     - $($ver.Name)" -ForegroundColor Gray
                
                # Suche nach MinGW
                $mingw = Get-ChildItem "$($ver.FullName)" -Directory -Filter "*mingw*" -ErrorAction SilentlyContinue
                if ($mingw) {
                    foreach ($m in $mingw) {
                        Write-Host "       └─ $($m.Name)" -ForegroundColor DarkGray
                    }
                }
            }
        }
        $qtFound = $true
        break
    }
}

if (-not $qtFound) {
    Write-Host "❌ NICHT GEFUNDEN" -ForegroundColor Red
    Write-Host "   Qt muss installiert werden!" -ForegroundColor Yellow
}

# PATH-Variable prüfen
Write-Host "`n[PATH-Variable] " -NoNewline

$pathQt = $env:PATH -split ';' | Where-Object { $_ -like '*Qt*' }
$pathMinGW = $env:PATH -split ';' | Where-Object { $_ -like '*mingw*' }

if ($pathQt -or $pathMinGW) {
    Write-Host "✅ Qt/MinGW in PATH" -ForegroundColor Green
    if ($pathQt) {
        foreach ($p in $pathQt) {
            Write-Host "   Qt: $p" -ForegroundColor Gray
        }
    }
    if ($pathMinGW) {
        foreach ($p in $pathMinGW) {
            Write-Host "   MinGW: $p" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "❌ Keine Qt/MinGW Einträge" -ForegroundColor Red
    Write-Host "   PATH muss konfiguriert werden!" -ForegroundColor Yellow
}

# SimulIDE Build-Verzeichnis prüfen
Write-Host "`n[SimulIDE Build-Verzeichnis] " -NoNewline

$buildDir = "C:\Users\rweissflog\Documents\GitHub\Python-Code\SimulIDE-dev\build_XX"
if (Test-Path $buildDir) {
    Write-Host "✅ GEFUNDEN" -ForegroundColor Green
    Write-Host "   Pfad: $buildDir" -ForegroundColor Gray
    
    # Prüfe ob Makefile existiert
    $makefile = Join-Path $buildDir "Makefile"
    if (Test-Path $makefile) {
        Write-Host "   ✅ Makefile vorhanden (Build-System konfiguriert)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Makefile fehlt (qmake muss ausgeführt werden)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ NICHT GEFUNDEN" -ForegroundColor Red
}

# Zusammenfassung
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ZUSAMMENFASSUNG" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$requiredTools = @{
    "qmake" = $qmake
    "g++" = $gcc
    "mingw32-make" = $make
}

$allOK = $true
foreach ($tool in $requiredTools.GetEnumerator()) {
    $status = if ($tool.Value) { "✅" } else { "❌"; $allOK = $false }
    Write-Host "$status $($tool.Key)" -ForegroundColor $(if ($tool.Value) { "Green" } else { "Red" })
}

Write-Host ""

if ($allOK) {
    Write-Host "✅ ALLE TOOLS INSTALLIERT!" -ForegroundColor Green
    Write-Host "`nSie können SimulIDE kompilieren mit:" -ForegroundColor Green
    Write-Host "  cd $buildDir" -ForegroundColor Cyan
    Write-Host "  qmake SimulIDE_Build.pro" -ForegroundColor Cyan
    Write-Host "  mingw32-make -j4`n" -ForegroundColor Cyan
} else {
    Write-Host "❌ FEHLENDE TOOLS - Installation erforderlich!`n" -ForegroundColor Red
    
    Write-Host "INSTALLATIONS-ANLEITUNG:" -ForegroundColor Yellow
    Write-Host "========================`n" -ForegroundColor Yellow
    
    if (-not $qmake -or -not $gcc -or -not $make) {
        Write-Host "1. Qt installieren:" -ForegroundColor Yellow
        Write-Host "   Download: https://www.qt.io/download-qt-installer" -ForegroundColor White
        Write-Host "   Wählen Sie:" -ForegroundColor White
        Write-Host "   - Qt 5.15.2 (oder neueste 5.x)" -ForegroundColor Gray
        Write-Host "   - MinGW 8.1.0 64-bit" -ForegroundColor Gray
        Write-Host "   - Qt Creator (optional)`n" -ForegroundColor Gray
        
        Write-Host "2. PATH-Variable konfigurieren:" -ForegroundColor Yellow
        Write-Host "   Fügen Sie diese Pfade hinzu:" -ForegroundColor White
        Write-Host "   - C:\Qt\5.15.2\mingw81_64\bin" -ForegroundColor Gray
        Write-Host "   - C:\Qt\Tools\mingw810_64\bin`n" -ForegroundColor Gray
        Write-Host "   PowerShell (temporär):" -ForegroundColor White
        Write-Host '   $env:PATH += ";C:\Qt\5.15.2\mingw81_64\bin;C:\Qt\Tools\mingw810_64\bin"' -ForegroundColor Cyan
        Write-Host ""
    }
    
    Write-Host "3. Nach Installation:" -ForegroundColor Yellow
    Write-Host "   Führen Sie dieses Skript erneut aus:`n" -ForegroundColor White
    Write-Host "   .\check-build-tools.ps1`n" -ForegroundColor Cyan
}

Write-Host "========================================`n" -ForegroundColor Cyan
