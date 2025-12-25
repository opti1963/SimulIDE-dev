# SimulIDE 1.1.0 - Debug-Button Ablaufanalyse

## Übersicht

Diese Analyse zeigt den kompletten Ablauf, wenn der **"Debug"**-Button im Hauptfenster von SimulIDE gedrückt wird.

---

## 1. Button-Definition und Signal-Verbindung

### Datei: `src/gui/editorwidget/editorwidget.cpp` (Zeile 797-800)

```cpp
debugAct = new QAction(QIcon(":/debug.svg"), tr("Debug"), this);
debugAct->setStatusTip(tr("Start Debugger"));
debugAct->setEnabled(false);
connect(debugAct, SIGNAL(triggered()), this, SLOT(debug()), Qt::UniqueConnection);
```

**Details:**
- **Icon**: `:/debug.svg` (Debug-Symbol)
- **Tooltip**: "Start Debugger"
- **Initial State**: Deaktiviert (wird erst nach erfolgreicher Kompilierung aktiviert)
- **Signal-Slot-Verbindung**: `triggered()` → `debug()` Slot

### Button in Toolbar einfügen (Zeile 849)

```cpp
m_compileToolBar->addAction(debugAct);
```

Der Debug-Button wird zur Compile-Toolbar hinzugefügt, zusammen mit "Compile" und "Upload"-Buttons.

---

## 2. Virtual Method Definition

### Basis-Klasse: `EditorWidget` (editorwidget.h, Zeile 94)

```cpp
virtual void debug(){;}  // Leere Implementierung (Basis-Klasse)
```

### Override in: `EditorWindow` (editorwindow.h, Zeile 60)

```cpp
virtual void debug() override;
```

**Vererbungshierarchie:**
```
EditorWidget (Basis)
    ↓
EditorWindow (Override mit tatsächlicher Implementierung)
```

---

## 3. Haupt-Debug-Funktion

### Datei: `src/gui/editorwidget/editorwindow.cpp` (Zeile 96-101)

```cpp
void EditorWindow::debug()
{
    m_outPane.appendLine( "-------------------------------------------------------\n" );
    m_outPane.appendLine( tr("Starting Debbuger...")+"\n" );
    initDebbuger();
}
```

**Ablauf:**
1. **Log-Ausgabe**: Trennlinie im Output-Panel
2. **Status-Meldung**: "Starting Debugger..."
3. **Initialisierung**: Aufruf von `initDebbuger()`

---

## 4. Debugger-Initialisierung

### Datei: `editorwindow.cpp` (Zeile 155-187)

```cpp
void EditorWindow::initDebbuger()
{
    m_debugDoc = nullptr;
    m_debugger = nullptr;
    m_state = DBG_STOPPED;

    // Schritt 1: Firmware hochladen mit Debug-Flag
    bool ok = uploadFirmware( true );

    if( ok )  // OK: Start Debugging
    {
        // Schritt 2: Code-Editor und Compiler/Debugger referenzieren
        m_debugDoc  = getCodeEditor();
        m_debugFile = m_debugDoc->getFile();
        m_debugger  = m_debugDoc->getCompiler();
        
        // Schritt 3: Debug-Modus im Editor aktivieren
        m_debugDoc->startDebug();

        // Schritt 4: UI konfigurieren
        stepOverAct->setVisible( true );
        eMcu::self()->setDebugging( true );
        reset();

        // Schritt 5: Log-Ausgabe
        m_outPane.appendLine("\n"+tr("Debugger Started")+"\n");
        
        // Schritt 6: Toolbars umschalten
        m_editorToolBar->setVisible( false );
        m_compileToolBar->setVisible( false );
        m_debuggerToolBar->setVisible( true );

        // Schritt 7: Debug-Aktionen aktivieren
        runAct->setEnabled( true );
        stepAct->setEnabled( true );
        stepOverAct->setEnabled( true );
        resetAct->setEnabled( true );
        pauseAct->setEnabled( false );

        // Schritt 8: Update-Liste registrieren
        Simulator::self()->addToUpdateList( this );
    }
    else{
        m_outPane.appendLine( "\n"+tr("Error Starting Debugger")+"\n" );
        stopDebbuger();
    }
}
```

### Detaillierte Schritte:

#### Schritt 1: Firmware hochladen (`uploadFirmware(true)`)

**Zeile 88-94:**
```cpp
bool EditorWindow::uploadFirmware( bool debug )
{
    CodeEditor* ce = getCodeEditor();
    if( !ce ) return false;

    bool ok = ce->compile( debug );  // Kompilierung mit Debug-Flag!
    if( ok ) ok = ce->getCompiler()->upload();

    return ok;
}
```

**Wichtig:** 
- `debug=true` wird an `compile()` übergeben
- Dies generiert Debug-Informationen (z.B. `.lst` Listing-Dateien)
- Upload lädt die kompilierte Firmware in den MCU

#### Schritt 2: Referenzen speichern

```cpp
m_debugDoc  = getCodeEditor();      // Aktueller Code-Editor
m_debugFile = m_debugDoc->getFile(); // Dateiname
m_debugger  = m_debugDoc->getCompiler(); // Compiler/Debugger-Instanz
```

#### Schritt 3: Debug-Modus aktivieren

**Datei: `codeeditor.cpp` (Zeile 583-594)**
```cpp
void CodeEditor::startDebug()
{
    m_debugging = true;
    m_debugLine = 1;
    updateScreen();
    
    QTextCursor cursor = textCursor();
    cursor.movePosition( QTextCursor::Start );
    setTextCursor( cursor );
    centerCursor();
    
    m_varList->show();  // Variable-List-Panel anzeigen
}
```

**Effekt:**
- Editor wechselt in Debug-Modus
- Cursor springt an Anfang
- Variablen-Panel wird sichtbar

#### Schritt 4: MCU konfigurieren

```cpp
eMcu::self()->setDebugging( true );  // MCU in Debug-Modus
reset();                              // Reset-Sequenz
```

**Reset-Funktion (Zeile 140-149):**
```cpp
void EditorWindow::reset()
{
    m_lastCycle = 0;
    m_lastTime = 0;
    m_state = DBG_PAUSED;
    CircuitWidget::self()->powerCircDebug();  // Circuit Power-Cycle

    m_debugDoc->setDebugLine( 1 );
    m_debugDoc->updateScreen();
}
```

#### Schritt 5: UI-Umschaltung

**Toolbars:**
- Editor-Toolbar: **VERSTECKEN**
- Compile-Toolbar: **VERSTECKEN**
- Debugger-Toolbar: **ANZEIGEN** (Run, Step, Step Over, Pause, Reset, Stop)

**Debug-Aktionen:**
| Action | Status |
|--------|--------|
| Run | ✅ Enabled |
| Step | ✅ Enabled |
| Step Over | ✅ Enabled |
| Reset | ✅ Enabled |
| Pause | ❌ Disabled (erst nach Start) |

#### Schritt 6: Update-Loop registrieren

```cpp
Simulator::self()->addToUpdateList( this );
```

**Zweck:** `EditorWindow::updateStep()` wird nun bei jedem Simulator-Schritt aufgerufen.

---

## 5. Debugger-Typen und Erstellung

### Datei: `editorwindow.cpp` (Zeile 244-263)

```cpp
BaseDebugger* EditorWindow::createDebugger( QString name, CodeEditor* ce, QString code )
{
    BaseDebugger* debugger = nullptr;
    QString type = m_compilers.value( name ).type;
    QString file = m_compilers.value( name ).file;
    
    // Compiler-Typ bestimmen
    if( type.isEmpty() ) {
        type = m_assemblers.value( name ).type;
        file = m_assemblers.value( name ).file;
    }
    
    // Debugger-Instanz erzeugen basierend auf Compiler-Typ
    if     ( type == "arduino")  debugger = new InoDebugger   ( ce, &m_outPane );
    else if( type == "avrgcc" )  debugger = new AvrGccDebugger( ce, &m_outPane );
    else if( type == "xc8" )     debugger = new Xc8Debugger   ( ce, &m_outPane );
    else if( type == "sdcc" )    debugger = new SdccDebugger  ( ce, &m_outPane );
    else if( type == "gcbasic" ) debugger = new GcbDebugger   ( ce, &m_outPane );
    else if( type == "ascript" ) debugger = new asDebugger    ( ce, &m_outPane );
    else{
        debugger = new BaseDebugger( ce, &m_outPane );
        if( name != "None" ) code = type.right( 2 );
        debugger->setLstType( code.right( 1 ).toInt() );
        debugger->setLangLevel( code.left( 1 ).toInt() );
    }
    
    if( name != "None" ) debugger->loadCompiler( file );
    return debugger;
}
```

### Unterstützte Debugger-Typen:

| Typ | Klasse | Beschreibung |
|-----|--------|--------------|
| `arduino` | `InoDebugger` | Arduino IDE Compiler (.ino Dateien) |
| `avrgcc` | `AvrGccDebugger` | AVR-GCC Compiler (C/C++) |
| `xc8` | `Xc8Debugger` | Microchip XC8 Compiler (PIC) |
| `sdcc` | `SdccDebugger` | Small Device C Compiler |
| `gcbasic` | `GcbDebugger` | Great Cow BASIC |
| `ascript` | `asDebugger` | AngelScript |
| (default) | `BaseDebugger` | Generischer Assembler-Debugger |

---

## 6. BaseDebugger Upload-Prozess

### Datei: `basedebugger.cpp` (Zeile 29-62)

```cpp
bool BaseDebugger::upload()
{
    // Schritt 1: Hex-Datei prüfen
    if( !m_firmware.isEmpty() && !QFileInfo::exists( m_firmware ) ) {
        m_outPane->appendLine( "\n"+tr("Error: Hex file doesn't exist:")+"\n"+m_firmware );
        return false;
    }
    
    // Schritt 2: MCU prüfen
    if( !Mcu::self() ) {
        m_outPane->appendLine( "\n"+tr("Error: No Mcu in Simulator... ") );
        return false;
    }
    
    bool ok = true;
    
    // Schritt 3: Firmware in MCU laden
    if( !m_firmware.isEmpty() ) {
        ok = Mcu::self()->load( m_firmware );
        if( ok ) m_outPane->appendText( "\n"+tr("FirmWare Uploaded to ") );
        else     m_outPane->appendText( "\n"+tr("Error uploading firmware to ") );
        m_outPane->appendLine( Mcu::self()->idLabel()+"("+ Mcu::self()->device() +")" );
        m_outPane->appendLine( m_firmware+"\n" );
    }
    
    // Schritt 4: Post-Processing (Listing-Dateien parsen)
    if( ok ){
        m_debugStep = false;
        m_stepOver = false;
        m_running = false;
        eMcu::self()->setDebugger( this );
        if( m_fileExt != ".hex" ) ok = postProcess();
    }
    return ok;
}
```

---

## 7. Post-Processing: Flash-zu-Source Mapping

### Datei: `basedebugger.cpp` (Zeile 70-238)

**Zweck:** Erstellt eine Zuordnung zwischen Flash-Adressen und Source-Code-Zeilen.

```cpp
bool BaseDebugger::postProcess()
{
    m_flashToSource.clear();

    // Schritt 1: Listing-Datei laden
    QString lstFile = m_buildPath+m_fileName+".lst";
    if( !QFileInfo::exists( lstFile ) ) {
        m_outPane->appendLine( "\n"+tr("Warning: lst file doesn't exist:")+"\n"+lstFile );
        return false;
    }
    
    m_outPane->appendText( "\nMapping Flash to Source... " );
    
    QString srcFile = m_fileDir + m_fileName + m_fileExt;
    QStringList srcLines = fileToStringList( srcFile, "BaseDebugger::postProcess" );
    QStringList lstLines = fileToStringList( lstFile, "BaseDebugger::postProcess" );

    // Schritt 2: High-Level vs. Assembler unterscheiden
    if( m_langLevel ) {  // High-Level (C/C++/Arduino)
        // Parse Listing für C/C++ Code
        // Suche nach Zeilen wie: "    123:  file.c:42"
        // Extrahiert Flash-Adresse und Source-Zeile
    }
    else {  // Assembler
        // Parse Listing für ASM Code
        // Findet Funktionen (CALL-Anweisungen)
        // Matched Source-Zeilen mit Listing-Zeilen
    }
    
    m_outPane->appendLine( QString::number( m_flashToSource.size() )+" lines mapped" );
    return true;
}
```

**Ergebnis:**
- `m_flashToSource`: Map<int FlashAddr, codeLine_t>
- Ermöglicht: Flash-PC → Source-Zeile → Editor-Highlight

---

## 8. AVR-GCC spezifisch: Variable Extraktion

### Datei: `avrgccdebugger.cpp` (Zeile 27-44)

```cpp
bool AvrGccDebugger::postProcess()
{
    m_elfPath = m_buildPath+m_fileName+".elf";
    if( !QFileInfo::exists( m_elfPath ) ) {
        m_outPane->appendLine( "\n"+QObject::tr("Warning: elf file doesn't exist:")+"\n"+m_elfPath );
        return false;
    }
    m_elfPath = addQuotes( m_elfPath );

    bool ok = getVariables();  // Variablen aus ELF extrahieren
    if( !ok ) return false;
    
    ok = getFunctions();        // Funktionen aus ELF extrahieren
    if( !ok ) return false;

    m_flashToSource.clear();
    return mapFlashToSource();  // Flash-zu-Source Mapping
}
```

### Variable Extraction (Zeile 46-100)

```cpp
bool AvrGccDebugger::getVariables()
{
    QString objdump = m_toolPath+"avr/bin/avr-objdump";
    #ifndef Q_OS_UNIX
        objdump += ".exe";
    #endif

    m_outPane->appendText( "\nSearching for variables... " );
    objdump = addQuotes( objdump );

    // avr-objdump ausführen: .bss Sektion analysieren
    QProcess getBss( nullptr );
    QString command = objdump+" -t -j.bss "+m_elfPath;
    getBss.start( command );
    getBss.waitForFinished(-1);

    QString p_stdout = getBss.readAllStandardOutput();
    QStringList varNames = m_varTypes.keys();

    // Parse Output: "00800123 O symbol_name"
    for( QString line : p_stdout.split("\n") ) {
        if( line.isEmpty() ) continue;
        QStringList words = line.split(" ");
        if( words.size() < 9 ) continue;
        if( words.at(6) != "O" ) continue;  // Object-Symbol

        QString addr   = words.at(0);
        bool ok = false;
        int address = addr.toInt( &ok, 16 );
        if( !ok ) continue;

        QString symbol = words.at(8);
        QString type;

        if( varNames.contains( symbol ) ) 
            type = m_varTypes.value( symbol );
        else {
            QString size = words.at(7);
            size = size.split("\t").last();
            type = "u"+QString::number( size.toInt()*8 );
        }
        
        address -= 0x800000;  // AVR-spezifisch: 0x800000 Offset entfernen

        // Variable zur RAM-Tabelle hinzufügen
        eMcu::self()->getRamTable()->addVariable( symbol, address, type );
    }
}
```

**Ergebnis:**
- Alle globalen Variablen werden im MCU RAM-Monitor angezeigt
- Adressen und Typen werden korrekt gemappt

---

## 9. Debug-Zustands-Maschine

### Enum: `bebugState_t` (editorwindow.h, Zeile 12-16)

```cpp
enum bebugState_t{
    DBG_STOPPED = 0,  // Debugger nicht aktiv
    DBG_PAUSED,       // Pausiert (auf Breakpoint oder nach Step)
    DBG_STEPING,      // Führt einen Step aus
    DBG_RUNNING       // Läuft kontinuierlich
};
```

### Zustandsübergänge:

```
                  debug()
   [STOPPED] ──────────────→ [PAUSED]
                                │
                         run()  │  pause()
                                ↓
   [PAUSED] ←────────────── [RUNNING]
       ↑                         │
       │   step()/stepOver()     │
       │         ↓               │
       └────── [STEPING] ────────┘
                                │
                         stop() │
                                ↓
                           [STOPPED]
```

---

## 10. Update-Loop während Debugging

### Datei: `editorwindow.cpp` (Zeile 44-77)

```cpp
void EditorWindow::updateStep()
{
    if( !m_updateScreen ) return;
    m_updateScreen = false;

    QString debugFile = m_debugLine.file;
    int     debugLine = m_debugLine.lineNumber;

    // Zeitmessung
    uint64_t cycle = eMcu::self()->cycle();
    double time    = Simulator::self()->circTime()/1e6;

    // Log-Ausgabe
    QString lineStr = QString::number( debugLine );
    while( lineStr.length() < 6 ) lineStr.append(" ");

    QString cycleStr = QString::number( cycle-m_lastCycle );
    while( cycleStr.length() < 15 ) cycleStr.append(" ");

    m_outPane.appendLine( tr("Line ")+lineStr
                        + tr("Clock Cycles: ")+cycleStr
                        + tr("Time us: ")+QString::number( time-m_lastTime ));
    m_lastCycle = cycle;
    m_lastTime = time;

    // Editor-Update
    CodeEditor* ce = getCodeEditor();
    if( m_debugFile != debugFile ) {  // Datei gewechselt?
        m_debugFile = debugFile;
        loadFile( debugFile );
        ce->setDebugLine( 0 );
        ce = getCodeEditor();
    }

    ce->setDebugLine( debugLine );  // Highlight aktuelle Zeile
    ce->updateScreen();
}
```

**Wird aufgerufen bei:**
- Jedem Simulator-Schritt
- Zeigt aktuelle Zeile im Editor
- Gibt Performance-Daten aus (Cycles, Zeit)

---

## 11. Zusammenfassung: Kompletter Ablauf

### Flowchart:

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER: Klickt "Debug"-Button                                 │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. EditorWindow::debug()                                        │
│    - Log: "Starting Debugger..."                               │
│    - Ruft: initDebbuger()                                      │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. initDebbuger()                                               │
│    - State: DBG_STOPPED                                        │
│    - Ruft: uploadFirmware(debug=true)                          │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. uploadFirmware(true)                                         │
│    - CodeEditor::compile(debug=true)                           │
│    - Compiler::upload()                                        │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. Compiler::compile(debug=true)                                │
│    - Generiert .hex, .elf, .lst Dateien                        │
│    - Mit Debug-Informationen                                   │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. BaseDebugger::upload()                                       │
│    - Lädt Firmware in MCU                                      │
│    - Ruft: postProcess()                                       │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 7. postProcess()                                                │
│    - Parst .lst Datei                                          │
│    - Erstellt Flash-zu-Source Mapping                          │
│    - (AVR-GCC): Extrahiert Variablen mit avr-objdump          │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 8. initDebbuger() (Fortsetzung)                                │
│    - m_debugDoc->startDebug()                                  │
│    - eMcu::self()->setDebugging(true)                          │
│    - reset() - Circuit Power-Cycle                             │
│    - UI: Debugger-Toolbar anzeigen                             │
│    - State: DBG_PAUSED                                         │
│    - Simulator::addToUpdateList(this)                          │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 9. CodeEditor::startDebug()                                     │
│    - m_debugging = true                                        │
│    - Cursor an Anfang                                          │
│    - Variablen-Panel anzeigen                                  │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│ 10. READY: Debugger bereit                                     │
│     - State: DBG_PAUSED                                        │
│     - Aktionen verfügbar: Run, Step, Step Over, Reset         │
│     - Editor zeigt Zeile 1                                     │
│     - MCU am Reset-Punkt (PC=0)                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 12. Wichtige Datenstrukturen

### `m_flashToSource` - Flash-zu-Source Mapping

```cpp
QMap<int, codeLine_t> m_flashToSource;

struct codeLine_t {
    QString file;        // Quelldatei-Pfad
    int lineNumber;      // Zeilennummer
};
```

**Beispiel:**
```
Flash-Adresse → Source-Zeile
0x0000 → { "main.cpp", 10 }
0x0002 → { "main.cpp", 11 }
0x0008 → { "utils.cpp", 45 }
```

### `m_varTypes` - Variable-Typ Mapping

```cpp
QMap<QString, QString> m_varTypes;
```

**Beispiel:**
```
"counter" → "u8"   (unsigned 8-bit)
"timer"   → "u16"  (unsigned 16-bit)
"buffer"  → "u8"   (array)
```

---

## 13. Fehlerbehandlung

### Mögliche Fehler:

| Fehler | Ursache | Behandlung |
|--------|---------|-----------|
| "Hex file doesn't exist" | Kompilierung fehlgeschlagen | Upload abbrechen |
| "No Mcu in Simulator" | Kein MCU in der Schaltung | Upload abbrechen |
| "lst file doesn't exist" | Debug-Info nicht generiert | postProcess() fehlgeschlagen |
| "elf file doesn't exist" | AVR-GCC Kompilierung fehlgeschlagen | postProcess() fehlgeschlagen |
| "Error uploading firmware" | MCU-Load fehlgeschlagen | Debug abbrechen |

### Error Recovery:

```cpp
if( !ok ) {
    m_outPane->appendLine( "\n"+tr("Error Starting Debugger")+"\n" );
    stopDebbuger();
}
```

---

## 14. Compiler-Konfiguration

### Datei: `editorwindow.cpp` (Zeile 277-303)

```cpp
void EditorWindow::loadCompilers()
{
    // Eingebaute Compiler
    m_compilers.insert("Arduino", {":/arduino.xml", "arduino"} );
    m_compilers.insert("AScript", {":/angelscript.xml", "ascript"} );

    // Benutzer-Compiler
    QString compilsPath = MainWindow::self()->getUserFilePath("codeeditor/compilers");
    loadCompilerSet( compilsPath, &m_compilers );
    
    compilsPath = MainWindow::self()->getUserFilePath("codeeditor/compilers/compilers");
    loadCompilerSet( compilsPath, &m_compilers );
    
    compilsPath = MainWindow::self()->getUserFilePath("codeeditor/compilers/assemblers");
    loadCompilerSet( compilsPath, &m_assemblers );

    // Eingebettete Compiler-Daten
    compilsPath = MainWindow::self()->getConfigPath("data/codeeditor/compilers/compilers");
    loadCompilerSet( compilsPath, &m_compilers );
    
    compilsPath = MainWindow::self()->getConfigPath("data/codeeditor/compilers/assemblers");
    loadCompilerSet( compilsPath, &m_assemblers );
}
```

**Compiler-XML-Format:**
```xml
<compiler name="Arduino" type="arduino">
    <toolpath>/path/to/arduino-cli</toolpath>
    <buildpath>/tmp/build</buildpath>
    <!-- weitere Konfiguration -->
</compiler>
```

---

## 15. Key Takeaways

### Was passiert beim Drücken des Debug-Buttons:

1. ✅ **Kompilierung** mit Debug-Flags
2. ✅ **Firmware-Upload** in den simulierten MCU
3. ✅ **Listing-Datei** wird geparst
4. ✅ **Flash-zu-Source Mapping** wird erstellt
5. ✅ **Variablen** werden extrahiert (AVR-GCC)
6. ✅ **UI** wechselt in Debug-Modus
7. ✅ **MCU** wird zurückgesetzt
8. ✅ **Update-Loop** wird registriert
9. ✅ **Editor** zeigt Zeile 1
10. ✅ **State**: DBG_PAUSED - Bereit zum Debuggen

### Nach erfolgreicher Initialisierung:

- **Run-Button**: Startet kontinuierliche Ausführung
- **Step-Button**: Führt eine Zeile aus
- **Step Over-Button**: Überspringt Funktionsaufrufe
- **Pause-Button**: Hält Ausführung an
- **Reset-Button**: MCU zurücksetzen
- **Stop-Button**: Debugging beenden

### Wichtige Dateien:

| Datei | Verantwortung |
|-------|---------------|
| `editorwidget.cpp` | Button-Definition |
| `editorwindow.cpp` | Debug-Logik |
| `basedebugger.cpp` | Basis-Debugger-Funktionalität |
| `avrgccdebugger.cpp` | AVR-spezifische Features |
| `codeeditor.cpp` | Editor-Debug-Modus |
| `circuitwidget.cpp` | Circuit-Debug-Integration |

---

## 16. Code-Referenzen

### Wichtigste Funktionen:

```cpp
// Button-Callback
EditorWindow::debug()                    // editorwindow.cpp:96

// Initialisierung
EditorWindow::initDebbuger()             // editorwindow.cpp:155

// Upload
EditorWindow::uploadFirmware(bool)       // editorwindow.cpp:88
BaseDebugger::upload()                   // basedebugger.cpp:29

// Post-Processing
BaseDebugger::postProcess()              // basedebugger.cpp:70
AvrGccDebugger::postProcess()            // avrgccdebugger.cpp:27
AvrGccDebugger::getVariables()           // avrgccdebugger.cpp:46

// Editor
CodeEditor::startDebug()                 // codeeditor.cpp:583

// Update-Loop
EditorWindow::updateStep()               // editorwindow.cpp:44

// Zustandsverwaltung
EditorWindow::run()                      // editorwindow.cpp:103
EditorWindow::step()                     // editorwindow.cpp:110
EditorWindow::pause()                    // editorwindow.cpp:120
EditorWindow::reset()                    // editorwindow.cpp:140
EditorWindow::stop()                     // editorwindow.cpp:151
```

---

## Autor

Analyse erstellt für SimulIDE 1.1.0 Development Version.
Datum: 25. Dezember 2025
