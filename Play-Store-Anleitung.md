# 🚀 Google Play Store Veröffentlichungs-Checkliste
## Uni-Projekt: Chat-App (Flutter, Dart, Firebase)

| **STATUS** | **VERANTWORTLICH** | **ZIEL-DATUM** |
| :---: | :---: | :---: |
| [ ] | [Name eintragen] | [Datum des Ausfüllens eintragen, z.B. 2025-12-02] |

---

## 1. 📜 A. RECHTLICHE & DATENSCHUTZ-ANFORDERUNGEN

* **A.1 GOOGLE ENTWICKLERKONTO:**
    * * [ x ] Konto eingerichtet und Gebühr bezahlt.
    * * [ x ] Konto-Inhaber ist: **[Andrijan Berton]**

* **A.2 DATENSCHUTZERKLÄRUNG (PRIVACY POLICY):**
    * * [ x ] Öffentliche, aktive **URL** zur Datenschutzerklärung erstellt.
    * * [ x ] Erklärung listet alle erfassten Daten (E-Mail, Chat-Inhalte, Gerätekennungen) auf.
    * * [ x ] Datennutzung und die Rolle von Drittanbietern (**Firebase**) ist transparent erklärt.
    * * [ ] Link zur Datenschutzerklärung in der **Play Console** hinterlegt.
    * * [ x ] Link zur Datenschutzerklärung in der **App selbst** leicht auffindbar (z.B. im Einstellungsmenü).

* **A.3 DATENSICHERHEIT (DATA SAFETY SECTION in Play Console):**
    * * [ x ] Formular in der Play Console wahrheitsgemäß ausgefüllt.
    * * [ x ] Angabe, dass Daten **verschlüsselt** übertragen werden (Standard bei Firebase/HTTPS).

* **A.4 BERECHTIGUNGEN:**
    * * [ x ] Nur absolut notwendige Berechtigungen (z.B. `INTERNET`, ggf. `CAMERA` für Bilder) angefordert.

---

## 2. 🛠️ B. TECHNISCHE VORBEREITUNG (FLUTTER & DART)

* **B.1 TARGET API LEVEL:**
    * * [ x ] API Level in `'android/app/build.gradle'` auf das aktuelle Minimum (**z.B. 34**) gesetzt.

* **B.2 RELEASE BUILD ERSTELLEN:**
    * * [ x ] Build-Nummer (`versionCode`) und Version (`versionName`) in `'pubspec.yaml'` erhöht.
    * * [ x  ] **Android App Bundle (`.aab`)** erstellt mit: `flutter build appbundle --release`

* **B.3 SIGNIERUNG:**
    * * [ x ] Keystore (**Upload-Schlüssel**) für die Signierung erstellt/gesichert.
    * * [ x ] **Google Play App Signing** in der Play Console aktiviert (empfohlen).
    * * [ ] Upload-Schlüssel sicher archiviert.

* **B.4 FIREBASE-KONFIGURATION:**
    * * [ x ] Firebase-Projekt-ID stimmt mit der in der App verwendeten überein.
    * * [ x ] **Paketname (Application ID)** im Android-Manifest und in der Firebase Console identisch.

* **B.5 STABILITÄT & TESTING:**
    * * [ x ] App wurde auf realen Geräten (verschiedene Android-Versionen) getestet.

---

## 3. 🖼️ C. GOOGLE PLAY STORE EINTRAG

* **C.1 APP-GRAFIKEN:**
    * * [ ] Hochauflösendes **App-Icon** (alle erforderlichen Größen).
    * * [ ] Mindestens 5 **Screenshots** (Smartphone).
    * * [ ] **Feature-Graphic** (Banner-Bild).

* **C.2 METADATEN:**
    * * [ ] Eindeutiger **App-Titel** (max. 30 Zeichen).
    * * [ ] Aussagekräftige **Kurzbeschreibung** (max. 80 Zeichen).
    * * [ ] Ausführliche **Langbeschreibung**.

* **C.3 KLASSIFIZIERUNG:**
    * * [ ] **Altersfreigabe-Fragebogen** ausgefüllt (wichtig für Chat-Apps mit UGC).
    * * [ ] Korrekte **Kategorie** (z.B. Kommunikation) ausgewählt.

* **C.4 AUSROLLUNG:**
    * * [ x ] App Bundle in die Play Console hochgeladen (z.B. Interner Test).
    * * [ ] Ausrollen auf **Produktion** gestartet.
    * * [ ] **Genehmigung** durch Google Play abgewartet.

---