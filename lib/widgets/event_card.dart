import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventCard extends StatefulWidget {
  final String title;
  final DateTime? datetime;
  final String location;
  final String description;
  final String messageId;
  final String currentUser;
  final Map<String, dynamic> votes;

  const EventCard({
    super.key,
    required this.title,
    required this.datetime,
    required this.location,
    required this.description,
    required this.messageId,
    required this.currentUser,
    required this.votes,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late List<String> yesList;
  late List<String> maybeList;
  late List<String> noList;

  @override
  void initState() {
    super.initState();
    // Listen aus dem votes-Map initialisieren
    yesList = List<String>.from(widget.votes['yes'] ?? []);
    maybeList = List<String>.from(widget.votes['maybe'] ?? []);
    noList = List<String>.from(widget.votes['no'] ?? []);
  }

  // Zeigt eine Liste der Personen an, die abgestimmt haben (BottomSheet)
  void _showVoters(String title, List<String> voters) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Divider(),
            if (voters.isEmpty) 
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text("Noch keine Teilnehmer eingetragen."),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: voters.length,
                itemBuilder: (context, i) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, size: 20, color: Colors.blue),
                  ),
                  title: Text(voters[i], style: const TextStyle(fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update Firestore + local UI state
  Future<void> _vote(String type) async {
    final user = widget.currentUser;
    setState(() {
      yesList.remove(user);
      maybeList.remove(user);
      noList.remove(user);
      if (type == 'yes') yesList.add(user);
      if (type == 'maybe') maybeList.add(user);
      if (type == 'no') noList.add(user);
    });

    final ref = FirebaseFirestore.instance.collection('events').doc(widget.messageId);
    await ref.update({
      "payload.data.votes": {
        "yes": yesList,
        "maybe": maybeList,
        "no": noList,
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final already = yesList.contains(widget.currentUser) 
        ? "yes" 
        : maybeList.contains(widget.currentUser) 
            ? "maybe" 
            : noList.contains(widget.currentUser) ? "no" : "";

    final dt = widget.datetime;
    final dateStr = dt != null ? "${dt.day}.${dt.month}.${dt.year}" : "--";
    final timeStr = dt != null ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}" : "--:--";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header: Blaues Banner mit Datum und Titel
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  _calendarBadge(dt),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("PLANUNG", 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue, letterSpacing: 1.5)),
                        Text(widget.title, 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor), 
                          overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body: Details und Voting
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.access_time_rounded, "$dateStr • $timeStr", textColor),
                  if (widget.location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _infoRow(Icons.location_on_rounded, widget.location, Colors.redAccent),
                  ],
                  if (widget.description.trim().isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    Text(widget.description, 
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[700], height: 1.5)),
                  ],
                  const SizedBox(height: 20),
                  // Vote-Buttons
                  Row(
                    children: [
                      _voteBtn("Zusage", Colors.green, already == "yes", () => _vote("yes")),
                      const SizedBox(width: 8),
                      _voteBtn("Vielleicht", Colors.orange, already == "maybe", () => _vote("maybe")),
                      const SizedBox(width: 8),
                      _voteBtn("Absage", Colors.red, already == "no", () => _vote("no")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Counter-Sektion (Klickbar!)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _counter(yesList.length, Colors.green, "Dabei", () => _showVoters("Zusagen", yesList)),
                      _counter(maybeList.length, Colors.orange, "Unsicher", () => _showVoters("Vielleicht", maybeList)),
                      _counter(noList.length, Colors.red, "Nicht dabei", () => _showVoters("Absagen", noList)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Zeile für Infos (Zeit, Ort)
  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Einheitlicher Abstimmungs-Button
  Widget _voteBtn(String label, Color color, bool active, VoidCallback tap) {
    return Expanded(
      child: InkWell(
        onTap: tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label, 
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : color)),
          ),
        ),
      ),
    );
  }

  // Klickbarer Counter für die Teilnehmerliste
  Widget _counter(int count, Color color, String label, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Column(
        children: [
          Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Kleines Kalender-Icon im Header
  Widget _calendarBadge(DateTime? dt) {
    final day = dt?.day.toString() ?? "--";
    final months = ["", "JAN", "FEB", "MÄR", "APR", "MAI", "JUN", "JUL", "AUG", "SEP", "OKT", "NOV", "DEZ"];
    final month = dt != null ? months[dt.month] : "---";
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(month, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
          Text(day, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}