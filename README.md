# NexxChat 💬

> **Unsere App ist ein mobiler Chat-Messenger (Android), der Chats durch eingebettete Mini-Apps interaktiv macht.**  
> Nutzer können Events planen, Tetris spielen, KI-Bilder generieren oder Chat-Commands nutzen – alles direkt im Chat, ohne App-Wechsel.

---

## 🌟 Features & Highlights

### 💬 Kommunikation & Chat
* **Privatnachrichten:** Starte private Chats direkt über den „+“-Button.
* **Rich Media Support:** Versende Texte und teile Bilder direkt aus deiner Galerie oder nimm sie live mit der Kamera auf.
* **Reactions:** Reagiere auf Nachrichten mit Emojis, ändere deine Meinung oder entferne Reaktionen – alles in Echtzeit.
* **Live-Status:** Sieh dank **Typing-Indikatoren**, wann dein Gesprächspartner schreibt.
* **Smart UX:** Nutze den „Scroll-to-Bottom“-Button, um in langen Chats sofort wieder zum Geschehen zu springen.

### 👥 Gruppen & Kollaboration
* **Gruppenchats:** Erstelle neue Gruppen und füge Mitglieder hinzu. Die Gruppe synchronisiert sich sofort bei allen Teilnehmern.
* **Event-Planung:** Nutze den `/event` Befehl, um Veranstaltungen zu planen. Mitglieder können direkt via Reactions zu- oder absagen.

### 🎮 Mini-Apps & Entertainment
* **In-Chat Gaming:** Spiele eine Runde **Tetris** und teile deinen Highscore direkt in der Gruppe, um Freunde herauszufordern.
* **Bot-Integration:** Teste die Konnektivität mit der `/hello` Mini-App.

### 🤖 KI-Integration
* **KI-Bildgenerierung:** Erstelle einzigartige Bilder per Prompt und sende sie direkt in den Chat.
* **Interaktion:** Auch KI-generierte Inhalte unterstützen volle Reaction-Funktionalität.
* **KI-Support-Bot:** Integrierter Assistent auf Basis der Google Gemini API.

### 🎨 Design & Personalisierung
* **Dark & Light Mode:** Schalte nahtlos zwischen hellen und dunklen Designs um.
* **Personalisierung:** Passe den Chat an deine visuellen Vorlieben an.

### 📹 Audio- & Video-Calls
* **Audio- & Videoanrufe:** Führe direkte Video- und Sprachanrufe via WebRTC mit Mini-Overlay direkt in der App.

---

## 🛠️ Tech Stack 

| Komponente | Technologie | Anmerkung |
| :--- | :--- | :--- |
| **Frontend** | **Flutter / Dart** | Single-Codebase für Android, iOS und Web; hohe Performance und konsistentes UI. |
| **Backend & Cloud** | **Firebase** | Firestore, Authentication, Cloud Storage, Cloud Functions. |
| **Echtzeit-Synchronisation** | **Firestore Realtime Listeners** | Direkt im Client implementiert; ersetzt WebSockets vollständig. |
| **Calls & Medien** | **WebRTC** | Peer-to-Peer Audio- & Video-Calls. |
| **KI: Bildgenerierung** | **Hugging Face / Pollination AI** | Für Avatare, Sticker, Bildgenerierung innerhalb der App. |
| **KI: Support Assistant** | **Google Gemini API** | Intelligente Antworten, Chatbot, Moderation, Wissenssuche. |
| **Versionsverwaltung** | **GitHub** | Code-Verwaltung, Pull Requests, Issues, Wiki. |
| **IDE & Emulation** | **VS Code / Android Studio** | Entwicklungsumgebung und Android-Emulator. |

---

## 🚀 Setup & Entwickler-Guide

### 1. VS Code - Empfohlene Erweiterungen
- **Flutter** (`dart-code.flutter`)
- **Dart** (`dart-code.dart-code`)

---

### 2. Environment Setup

#### Flutter SDK installieren:
1. Lade das Flutter SDK herunter: [https://docs.flutter.dev/install/manual](https://docs.flutter.dev/install/manual)
2. Entpacke es z. B. nach `C:\src\flutter`.
3. Füge den Pfad `C:\src\flutter\bin` zur Umgebungsvariable **PATH** hinzu.
4. Android-Lizenzen akzeptieren:
   ```bash
   flutter doctor --android-licenses
   ```
5. Teste die Installation in der Konsole:
   ```bash
   flutter doctor
   ```

---

### 3. Android Studio & Emulator Setup

Es wird ein Android-Emulator (oder physisches Testgerät) benötigt:
1. In Android Studio: **Tools -> SDK Manager**.
2. Unter **SDK Tools** unten rechts **"Show Package Details"** aktivieren.
3. **Android SDK Command-line Tools (latest)** anhaken -> **Apply -> OK**.
4. Über den **Device Manager** einen Emulator anlegen und starten (z. B. Pixel 7 / Pixel 4).

---

### 4. Repository klonen

```bash
git clone https://github.com/Xafe42/NexxChat.git
cd NexxChat
```

---

### 5. App starten

1. Emulator über Android Studio starten.
2. Prüfen, ob Flutter das Gerät erkennt:
   ```bash
   flutter devices
   ```
3. Abhängigkeiten laden und starten (mit automatischer `.env`-Einbindung):
   ```bash
   flutter pub get
   flutter run --dart-define-from-file=.env
   ```
