import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_life_care_app/widgets/hw_top_actions.dart';

class HWChatDetailScreen extends StatefulWidget {
  final String requestId;
  const HWChatDetailScreen({super.key, required this.requestId});

  @override
  State<HWChatDetailScreen> createState() => _HWChatDetailScreenState();
}

class _HWChatDetailScreenState extends State<HWChatDetailScreen> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _processing = false;

  Future<void> _updateStatus(String status, String currentStatus) async {
    if (currentStatus != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request already processed')),
      );
      return;
    }

    setState(() => _processing = true);
    try {
      final uid = _auth.currentUser?.uid;
      await _fs.collection('requests').doc(widget.requestId).update({
        'status': status,
        if (uid != null) 'assignedTo': uid,
        'respondedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request $status')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating request: $e')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requestId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Request Detail'),
          actions: [const HWTopActions()],
        ),
        body: const Center(child: Text('Invalid request identifier')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Detail'),
        actions: [const HWTopActions()],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _fs.collection('requests').doc(widget.requestId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error loading request: ${snap.error}'));
          }
          final doc = snap.data;
          if (doc == null || !doc.exists) {
            return const Center(
              child: Text('Request not found or was removed'),
            );
          }
          final data =
              (doc.data() ?? <String, dynamic>{}) as Map<String, dynamic>;
          final currentStatus = (data['status'] ?? 'pending').toString();
          final studentName = (data['studentName'] ?? 'Student').toString();
          final message = (data['message'] ?? '').toString();
          final assignedTo = (data['assignedTo'] ?? '').toString();

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                if (assignedTo.isNotEmpty) ...[
                  Text(
                    'Assigned to: $assignedTo',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_processing || currentStatus != 'pending')
                            ? null
                            : () => _updateStatus('accepted', currentStatus),
                        child: _processing
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (_processing || currentStatus != 'pending')
                            ? null
                            : () => _updateStatus('declined', currentStatus),
                        child: const Text('Decline'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
