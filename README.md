# NexxChat Setup Guide
---
## TODO in VSCODE - Extensions installieren
- Flutter - Identifier (dart-code.flutter)
- Dart - Identifier (dart-code.dart-code) 
---
## ENVIRONMENT Setup

### Flutter SDK installieren:
1. Lade das Flutter SDK herunter: 
https://docs.flutter.dev/install/manual
2. Entpacke es z. B. nach:
C:\src\flutter
3. Füge den Pfad zur Umgebungsvariable **PATH** hinzu: 
4. Android-licenses akzeptieren:
 
```flutter doctor --android-licenses```

5. Teste die Installation: 
In Command Prompt 

```flutter doctor```
Sollte ungefähr so aussehen: "[x] Visual Studio -develop Windows apps". Ist erstmal unwichtig. 
```
Visual Studio - develop Windows apps muss nicht abgehackt sein funktioniert auch ohne.(fürs erste)
C:\Users\JoelP>flutter doctor
Doctor summary (to see all details, run flutter doctor -v):
[√] Flutter (Channel stable, 3.35.7, on Microsoft Windows [Version 10.0.26100.6899], locale de-DE)
[√] Windows Version (11 Home 64-bit, 24H2, 2009)
[√] Android toolchain - develop for Android devices (Android SDK version 35.0.1)
[√] Chrome - develop for the web
[X] Visual Studio - develop Windows apps
    X Visual Studio not installed; this is necessary to develop Windows apps.
      Download at https://visualstudio.microsoft.com/downloads/.
      Please install the "Desktop development with C++" workload, including all of its default components
[√] Android Studio (version 2024.3)
[√] VS Code (version 1.105.1)
[√] Connected device (3 available)
[√] Network resources

! Doctor found issues in 1 category.
```
---

### TODO in Android Studio
Es wird ein Emulator benötigt. Ich habe bisher einen Android-Emulator verwenden. 

- Setup des SDKs(auch Android Studio):
- Oben die Navigationsleiste -> Tools -> SDK Manager,
- Bei "SDK Platforms","SDK Tools", "SDK Update Sites" soll SDK Tools ausgewählt werden.
- Unten rechts Aktiviere "Show Package Details",
- Suche "Android SDK Command-line Tools(latest)",
- Haken setzen -> Apply -> OK,
---

### TODO lade das Repository runter: 

```git clone https://gitlab.bht-berlin.de/anbe3574/nexchat.git```

--- 

### TODO Entwickler Modus in Windows Aktivieren
Einstellungen -> Datenschutz & Sicherheit -> Für Entwickler -> Entwicklermodus aktivieren 

---
## Ausführen vom Programm

### TODO Emulator bei Android Studio Starten
1. Device Manager -> Start (z.B Pixel 4)
2. Der Emulator sollte nun in Running Devices angezeigt werden und laufen. 
3. Optional kannst du im Command Prompt prüfen, ob Flutter den Emulator erkennt: 

```flutter devices  # zeigt alle von Flutter erkannten Geräte```

### TODO Flutter-Installation überprüfen 
Flutter Commands Im Projektverzeichnis ausführen."(C:\Users\.........\Workspaces\Projekt\nexchat>)"


```
flutter pub get       # Lädt alle Abhängigkeiten aus pubspec.yaml
flutter run
```