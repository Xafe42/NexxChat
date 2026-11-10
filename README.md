# NexxChat 💬

> **Unsere App ist ein mobiler Chat-Messenger (Android), der Chats durch eingebettete Mini-Apps interaktiv macht.**  
> Nutzer können Events planen, Tetris spielen, KI-Bilder generieren oder Chat-Commands nutzen – alles direkt im Chat, ohne App-Wechsel.

---

### ✨ Core-Funktionen
* **Echtzeit-Chat:** Nachrichten, Bilder, Reactions, Typing-Indikator, Gruppen, Dark/Light Mode und Chat-Personalisierung.
* **Integrierte Mini-Apps:** Mini-App-Erlebnisse direkt im Chatverlauf (Events, Tetris, Bildgenerierung etc.).
* **Ziel:** Chats lebendig, spielerisch und produktiv machen, mit Mini-Apps als Haupt-Alleinstellungsmerkmal.

### 🛠️ Technologien
* **Frontend:** Flutter / Dart
* **Backend & Cloud:** Firebase (Auth, Firestore, Storage, Cloud Functions)
* **Deployment:** Google Play
* **Versionskontrolle:** GitHub

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
   *(Visual Studio für Windows Desktop muss nicht zwingend installiert sein; Android reicht für die App).*

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
3. Abhängigkeiten laden und starten:
   ```bash
   flutter pub get
   flutter run
   ```
