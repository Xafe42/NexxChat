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

```git clone -b Firebase --single-branch https://gitlab.bht-berlin.de/anbe3574/nexchat.git```

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

---
# 🚀 Features

Unsere App bietet eine umfassende Kommunikationsplattform, die klassisches Messaging mit modernen KI-Funktionen und interaktiven Mini-Apps verbindet.

### 💬 Kommunikation & Chat
Erlebe flüssige Echtzeit-Kommunikation mit intuitiven Funktionen.
* **Privatnachrichten:** Starte private Chats direkt über den „+“ Button.
* **Rich Media Support:** Versende Texte und teile Bilder direkt aus deiner Galerie oder nimm sie live mit der Kamera auf.
* **Reactions:** Reagiere auf Nachrichten mit Emojis, ändere deine Meinung oder entferne Reaktionen – alles in Echtzeit.
* **Live-Status:** Sehe dank **Typing-Indikatoren**, wann dein Gesprächspartner schreibt.
* **Smart UX:** Nutze den „Scroll-to-Bottom“ Button, um in langen Chats sofort wieder zum Geschehen zu springen.

### 👥 Gruppen & Kollaboration
Verbinde dich mit mehreren Personen gleichzeitig.
* **Gruppenchats:** Erstelle neue Gruppen und füge Mitglieder hinzu. Die Gruppe synchronisiert sich sofort bei allen Teilnehmern.
* **Event-Planung:** Nutze den `/event` Befehl, um Veranstaltungen zu planen. Mitglieder können direkt via Reactions zu- oder absagen.

### 🎮 Mini-Apps & Entertainment
Mehr als nur Text – interaktive Features direkt im Chat-Fenster.
* **In-Chat Gaming:** Spiele eine Runde **Tetris** und teile deinen Highscore direkt in der Gruppe, um Freunde herauszufordern.
* **Bot-Integration:** Teste die Konnektivität mit der `/hello` Mini-App.

### 🤖 KI-Integration
Nutze die Macht künstlicher Intelligenz für kreative Inhalte.
* **KI-Bildgenerierung:** Erstelle einzigartige Bilder per Prompt und sende sie direkt in den Chat.
* **Interaktion:** Auch KI-generierte Inhalte unterstützen volle Reaction-Funktionalität.

### 🎨 Design & Personalisierung
Eine Oberfläche, die sich dir anpasst.
* **Dark & Light Mode:** Schalte nahtlos zwischen hellen und dunklen Designs um.
* **Personalisierung:** Passe den Chat an deine visuellen Vorlieben an.

### 📹 Videocalls
* **Videoanrufe:** Führe direkte Videogespräche für eine noch persönlichere Verbindung.

---
# Tech Stack 


| Komponente                      | Technologie                                                                         | Anmerkung                                                                       |
| :------------------------------ | :---------------------------------------------------------------------------------- | :------------------------------------------------------------------------------ |
| **Frontend (Mobile/Web)**       | **Flutter**                                                                         | Single-Codebase für Android, iOS und Web; hohe Performance und konsistentes UI. |
| **Programmiersprache**          | **Dart**                                                                            | Moderne, performante Sprache, optimal für Flutter.                              |
| **Backend (Logik)**             | **Kein dediziertes Backend** – Logik erfolgt **clientseitig** in Flutter + Firebase | Keine Serververwaltung; niedriger Wartungsaufwand.                              |
| **Datenbank & Realtime**        | **Firebase Firestore**                                                              | Dokumentenbasierte NoSQL-Datenbank mit nativer Realtime-Synchronisation.        |
| **Realtime-Layer**              | **Firebase SDK Listener** (Firestore / Realtime DB)                                 | Direkt im Client implementiert; ersetzt WebSockets vollständig.                 |
| **Authentifizierung**           | **Firebase Authentication**                                                         | E-Mail/Passwort, Google, Apple, anonyme Sessions u. a.                          |
| **Medien-Speicher**             | **Firebase Storage**                                                                | Speicherung von Bildern, generierten Dateien, Uploads usw.                      |
| **KI: Bildgenerierung**         | **Pollination AI**                                                                  | Für Avatare, Sticker, Bildgenerierung innerhalb der App.                        |
| **KI: Support Bot / Assistant** | **Google Gemini API**                                                               | Intelligente Antworten, Chatbot, Moderation, Wissenssuche.                      |
| **Versionsverwaltung**          | **GitLab** (Hochschule)                                                             | Code-Verwaltung, CI/CD Pipelines, Boards.                                       |
| **Entwicklungsumgebung**        | **Visual Studio Code**                                      | Primäre Entwicklungsumgebungen für Flutter.                                     |
| **Emulation / Debugging**       | **Android Studio Emulator**                                                         | Zum Testen, Profilen und Debuggen.                                              |
