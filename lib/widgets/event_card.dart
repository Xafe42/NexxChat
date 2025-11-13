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

    yesList = List<String>.from(widget.votes['yes'] ?? []);
    maybeList = List<String>.from(widget.votes['maybe'] ?? []);
    noList = List<String>.from(widget.votes['no'] ?? []);
  }

  //   Update Firestore + local UI state
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

    final ref = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.messageId);

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
    final already = yesList.contains(widget.currentUser)
        ? "yes"
        : maybeList.contains(widget.currentUser)
            ? "maybe"
            : noList.contains(widget.currentUser)
                ? "no"
                : "";

    final dt = widget.datetime;
    final date = dt != null ? "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}" : "--";
    final time = dt != null ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}" : "--:--";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(children: [
              _calendarBadge(dt),
              const SizedBox(width: 12),
              const Text("Event",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
            ]),

            const SizedBox(height: 14),

            Text(widget.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87)),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.schedule, size: 20, color: Colors.grey),
                const SizedBox(width: 6),
                Text("$date   $time",
                    style: const TextStyle(fontSize: 15, color: Colors.black87)),
              ],
            ),

            const SizedBox(height: 6),

            if (widget.location.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(widget.location,
                        style: const TextStyle(fontSize: 15, color: Colors.black87)),
                  )
                ],
              ),

            const SizedBox(height: 12),

            if (widget.description.trim().isNotEmpty)
              Text(widget.description,
                  style: TextStyle(fontSize: 15, height: 1.35, color: Colors.grey[800])),

            const SizedBox(height: 20),

            // VOTE BUTTONS
            Row(
              children: [
                _eventButton("I'm in", Colors.green, Icons.check, already == "yes",
                    () => _vote("yes")),
                _eventButton("Maybe", Colors.orange, Icons.help_outline,
                    already == "maybe", () => _vote("maybe")),
                _eventButton("No", Colors.red, Icons.close, already == "no",
                    () => _vote("no")),
              ],
            ),

            const SizedBox(height: 18),

            // COUNTERS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _voteCount(yesList.length, Colors.green),
                _voteCount(maybeList.length, Colors.orange),
                _voteCount(noList.length, Colors.red),
              ],
            )
          ],
        ),
      ),
    );
  }

  // UI helpers
  
  Widget _calendarBadge(DateTime? dt) {
    final day = dt?.day.toString().padLeft(2, '0') ?? "--";
    final month = dt != null ? _monthName(dt.month) : "";

    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14), color: Colors.blue[700]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(month,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          Text(day,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _eventButton(
      String text, Color color, IconData icon, bool selected, VoidCallback tap) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: selected ? color : color.withOpacity(0.4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: tap,
          icon: Icon(icon, size: 18, color: Colors.white),
          label: Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _voteCount(int count, Color color) {
    return Row(
      children: [
        Icon(Icons.person, size: 18, color: color),
        const SizedBox(width: 4),
        Text(count.toString(),
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  String _monthName(int m) {
    const months = [
      "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m];
  }
}




