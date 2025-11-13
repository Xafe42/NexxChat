import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../apps/event_app.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventPreview extends StatefulWidget {
  final VoidCallback onCancel;
  final void Function(Map<String, dynamic> data) onSend;

  const EventPreview({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<EventPreview> createState() => _EventPreviewState();
}

class _EventPreviewState extends State<EventPreview> {
  // Text-Controller für die Eingabefelder
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();

  // Ausgewähltes Datum & Uhrzeit
  DateTime? _date;
  TimeOfDay? _time;

  @override
  void dispose() {
    // Controller korrekt freigeben
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  // Datumsauswahl (DatePicker öffnen)
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d != null) setState(() => _date = d);
  }

  // Uhrzeitauswahl (TimePicker öffnen)
  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _time = t);
  }

  // Datum + Uhrzeit zu einem einzigen DateTime kombinieren
  DateTime? _composeDateTime() {
    if (_date == null || _time == null) return null;
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
  }

  // Event abschicken → wird in Firestore gespeichert + als Message referenziert
  void _submit() async {
    final dt = _composeDateTime();

    // Validierung: Titel und Datum/Uhrzeit müssen gesetzt sein
    if (_title.text.trim().isEmpty || dt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Titel, Datum und Uhrzeit ausfüllen')),
      );
      return;
    }

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    // Event-Daten sammeln
    final data = {
      'title': _title.text.trim(),
      'location': _location.text.trim(),
      'description': _description.text.trim(),
      'datetime': dt,
    };

    // Payload für Firestore generieren
    final payload = EventApp.buildPayload(data);

    // 1️⃣ Event in der "events"-Collection speichern
    final eventDoc = await FirebaseFirestore.instance.collection("events").add({
      ...payload,
      'creator': user?.email,
    });

    // 2️⃣ Eine Message im Chat speichern, die auf das Event verweist
    await FirebaseFirestore.instance.collection("messages").add({
      'type': 'event_ref',
      'eventId': eventDoc.id,
      'sender': user?.email,
      'time': FieldValue.serverTimestamp(),
    });

    // UI schließen
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    // Labels für Datum und Uhrzeit
    final dateLabel = _date == null
        ? 'Datum wählen'
        : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';

    final timeLabel = _time == null
        ? 'Uhrzeit wählen'
        : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Kopfzeile „Event Preview“
          Row(
            children: const [
              Icon(Icons.event, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text(
                'Event Preview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Titel-Eingabe
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Titel',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          // Datum + Uhrzeit
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(dateLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(timeLabel),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Ort
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Ort',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          // Beschreibung
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Beschreibung (optional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          // Buttons „Cancel“ und „Send“
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Abbrechen'),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Senden'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}