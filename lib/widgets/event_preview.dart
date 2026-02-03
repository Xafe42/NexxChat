import 'package:flutter/material.dart';

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

  // Event abschicken → Daten werden an onSend des Screens gereicht
  void _submit() {
    final dt = _composeDateTime();

    // Validierung: Titel und Datum/Uhrzeit müssen gesetzt sein
    if (_title.text.trim().isEmpty || dt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Titel, Datum und Uhrzeit ausfüllen')),
      );
      return;
    }

    // Event-Daten sammeln und an den Screen zurückgeben
    final data = {
      'title': _title.text.trim(),
      'location': _location.text.trim(),
      'description': _description.text.trim(),
      'datetime': dt,
    };

    widget.onSend(data);
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Reagiert auf Dark Mode Personalisierung
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black;

    // Labels für Datum und Uhrzeit
    final dateLabel = _date == null
        ? 'Datum wählen'
        : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';

    final timeLabel = _time == null
        ? 'Uhrzeit wählen'
        : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Nimmt nur so viel Platz wie nötig
        children: [
          // Kopfzeile „Event Preview“
          Row(
            children: [
              const Icon(Icons.event, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(
                'Event Preview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Titel-Eingabe
          TextField(
            controller: _title,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Titel',
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              border: const OutlineInputBorder(),
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
                  label: Text(dateLabel, style: TextStyle(color: textColor)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(timeLabel, style: TextStyle(color: textColor)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Ort
          TextField(
            controller: _location,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Ort',
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          // Beschreibung
          TextField(
            controller: _description,
            maxLines: 3,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Beschreibung (optional)',
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              border: const OutlineInputBorder(),
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