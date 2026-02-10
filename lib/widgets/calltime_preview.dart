import 'package:flutter/material.dart';

class CallTimePreview extends StatefulWidget {
  final VoidCallback onCancel;
  final void Function(Map<String, dynamic> data) onSend;

  const CallTimePreview({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<CallTimePreview> createState() => _CallTimePreviewState();
}

class _CallTimePreviewState extends State<CallTimePreview> {
  DateTime? _date;
  TimeOfDay? _time;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  String _formatMonth(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

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
                const Text(
                  "Call Time",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ---------- DATE + TIME ----------
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text(
                  _date == null || _time == null
                      ? "Select date & time"
                      : "${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}    "
                          "${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ---------- PICKERS ----------
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDate,
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text("Pick Date", style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickTime,
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text("Pick Time", style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ---------- NOTE ----------
            TextField(
              controller: _note,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: "Description (optional)",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 1,
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
                  onPressed: () {
                    if (_date == null || _time == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Select date & time")),
                      );
                      return;
                    }

                    final formattedDate =
                        "${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}";

                    final formattedTime =
                        "${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}";

                    widget.onSend({
                      "date": formattedDate,
                      "time": formattedTime,
                      "note": _note.text.trim(),
                    });
                  },
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