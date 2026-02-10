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

  String _formatMonth(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m - 1];
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------- HEADER ----------
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _date == null ? "--" : _formatMonth(_date!.month),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      Text(
                        _date == null ? "--" : _date!.day.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "New Event",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ---------- FIELDS ----------
            TextField(
              controller: _title,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                labelText: "Title",
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 14),
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    label: Text(
                      _date == null ? "Date" : "${_date!.day}.${_date!.month}.",
                      style: TextStyle(color: textColor, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 14),
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    label: Text(
                      _time == null ? "Time" : _time!.format(context),
                      style: TextStyle(color: textColor, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _location,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                labelText: "Location",
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _description,
              style: TextStyle(color: textColor, fontSize: 14),
              maxLines: 1,
              decoration: InputDecoration(
                labelText: "Description (optional)",
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),

            const SizedBox(height: 14),

            // ---------- BUTTONS ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text("Send"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}