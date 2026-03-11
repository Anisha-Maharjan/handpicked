import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color _nBrown     = Color(0xFF834D1E);
const Color _nCream     = Color(0xFFF9F3E8);
const Color _nTextDark  = Color(0xFF1E1E1E);
const Color _nTextMuted = Color(0xFF9B8165);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Read uid once when the screen opens — guaranteed non-null at this point
  // because the user is already logged in to reach this screen.
  late final String _uid;
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // No orderBy — FieldValue.serverTimestamp() is null on the client until
    // the server resolves it, so orderBy silently drops newly written docs.
    // We sort client-side instead.
    _stream = FirebaseFirestore.instance
        .collection('userNotifications')
        .doc(_uid)
        .collection('items')
        .snapshots();
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return 'just now';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)   return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  bool _isToday(Timestamp? ts) {
    if (ts == null) return true; // treat pending-timestamp docs as today
    final now = DateTime.now();
    final d   = ts.toDate();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'order_placed':    return Icons.receipt_long_outlined;
      case 'order_started':   return Icons.coffee_maker_outlined;
      case 'order_ready':     return Icons.notifications_active_outlined;
      case 'order_completed': return Icons.check_circle_outline_rounded;
      default:                return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 18, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: _nTextDark, size: 22),
                    splashRadius: 22,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  const Text('Notification',
                      style: TextStyle(
                          color: _nTextDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Feed ──
            Expanded(
              child: _uid.isEmpty
                  ? const Center(
                      child: Text('Not logged in.',
                          style: TextStyle(color: _nTextMuted, fontSize: 14)))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _stream,
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(color: _nBrown));
                        }

                        final docs = List<QueryDocumentSnapshot>.from(
                            snap.data?.docs ?? []);

                        if (docs.isEmpty) {
                          return const Center(
                              child: Text('No notifications yet.',
                                  style: TextStyle(
                                      color: _nTextMuted, fontSize: 14)));
                        }

                        // Client-side sort: newest first, null timestamps
                        // (pending server resolve) treated as newest
                        docs.sort((a, b) {
                          final aT =
                              (a.data() as Map)['createdAt'] as Timestamp?;
                          final bT =
                              (b.data() as Map)['createdAt'] as Timestamp?;
                          if (aT == null && bT == null) return 0;
                          if (aT == null) return -1;
                          if (bT == null) return 1;
                          return bT.compareTo(aT);
                        });

                        final today = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return _isToday(data['createdAt'] as Timestamp?);
                        }).toList();

                        final earlier = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return !_isToday(data['createdAt'] as Timestamp?);
                        }).toList();

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                          children: [
                            if (today.isNotEmpty) ...[
                              _sectionLabel('Today'),
                              ...today.map((d) => _NotifTile(
                                  doc: d,
                                  timeAgo: _timeAgo,
                                  iconFor: _iconFor,
                                  uid: _uid)),
                            ],
                            if (earlier.isNotEmpty) ...[
                              _sectionLabel('Last 7 days'),
                              ...earlier.map((d) => _NotifTile(
                                  doc: d,
                                  timeAgo: _timeAgo,
                                  iconFor: _iconFor,
                                  uid: _uid)),
                            ],
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
        child: Text(text,
            style: const TextStyle(
                color: _nTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      );
}

class _NotifTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String Function(Timestamp?) timeAgo;
  final IconData Function(String) iconFor;
  final String uid;

  const _NotifTile({
    required this.doc,
    required this.timeAgo,
    required this.iconFor,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final data    = doc.data() as Map<String, dynamic>;
    final message = (data['message'] as String?) ?? '';
    final type    = (data['type']    as String?) ?? '';
    final ts      = data['createdAt'] as Timestamp?;

    // Mark as read silently
    if (!(data['read'] as bool? ?? true)) {
      FirebaseFirestore.instance
          .collection('userNotifications')
          .doc(uid)
          .collection('items')
          .doc(doc.id)
          .update({'read': true});
    }

    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color:        _nCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D5BC), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconFor(type), color: _nBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: const TextStyle(
                        color: _nTextDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
                const SizedBox(height: 3),
                Text(timeAgo(ts),
                    style: const TextStyle(
                        color: _nTextMuted, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}