import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _anBrown     = Color(0xFF7B4A1E);
const Color _anCream     = Color(0xFFF9F3E8);
const Color _anTextDark  = Color(0xFF3B2005);
const Color _anTextMuted = Color(0xFF9B8165);

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)   return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  bool _isToday(Timestamp? ts) {
    if (ts == null) return false;
    final now = DateTime.now();
    final d   = ts.toDate();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'new_order':       return Icons.receipt_long_outlined;
      case 'order_completed': return Icons.check_circle_outline_rounded;
      case 'stock_warning':   return Icons.warning_amber_rounded;
      default:                return Icons.notifications_none_rounded;
    }
  }

  Color _colorFor(String type) {
    if (type == 'stock_warning') return const Color(0xFFB05C00);
    return _anBrown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 18, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: _anTextDark, size: 22),
                    splashRadius: 22,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  const Text('Activity',
                      style: TextStyle(
                          color: _anTextDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('adminNotifications')
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _anBrown));
                  }

                  final docs = snap.data?.docs ?? [];

                  // Sort client-side so null timestamps don't exclude new docs
                  docs.sort((a, b) {
                    final aT = (a.data() as Map)['createdAt'] as Timestamp?;
                    final bT = (b.data() as Map)['createdAt'] as Timestamp?;
                    if (aT == null && bT == null) return 0;
                    if (aT == null) return -1;
                    if (bT == null) return 1;
                    return bT.compareTo(aT);
                  });

                  if (docs.isEmpty) {
                    return const Center(
                        child: Text('No activity yet.',
                            style: TextStyle(
                                color: _anTextMuted, fontSize: 14)));
                  }

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
                        ...today.map((d) => _ActivityTile(
                              doc:      d,
                              timeAgo:  _timeAgo,
                              iconFor:  _iconFor,
                              colorFor: _colorFor,
                            )),
                      ],
                      if (earlier.isNotEmpty) ...[
                        _sectionLabel('Earlier'),
                        ...earlier.map((d) => _ActivityTile(
                              doc:      d,
                              timeAgo:  _timeAgo,
                              iconFor:  _iconFor,
                              colorFor: _colorFor,
                            )),
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
        padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
        child: Text(text,
            style: const TextStyle(
                color: _anTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      );
}

class _ActivityTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String Function(Timestamp?)  timeAgo;
  final IconData Function(String)    iconFor;
  final Color Function(String)       colorFor;

  const _ActivityTile({
    required this.doc,
    required this.timeAgo,
    required this.iconFor,
    required this.colorFor,
  });

  @override
  Widget build(BuildContext context) {
    final data    = doc.data() as Map<String, dynamic>;
    final message = (data['message'] as String?) ?? '';
    final type    = (data['type']    as String?) ?? '';
    final ts      = data['createdAt'] as Timestamp?;

    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color:        _anCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D5BC), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(iconFor(type), color: colorFor(type), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: const TextStyle(
                        color: _anTextDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35)),
                const SizedBox(height: 3),
                Text(timeAgo(ts),
                    style: const TextStyle(
                        color: _anTextMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}