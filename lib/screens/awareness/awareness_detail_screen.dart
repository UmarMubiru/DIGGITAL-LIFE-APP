// ignore_for_file: unnecessary_underscores

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_life_care_app/providers/awareness_provider.dart';
import 'package:digital_life_care_app/widgets/top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AwarenessDetailScreen extends StatefulWidget {
  const AwarenessDetailScreen({super.key});

  @override
  State<AwarenessDetailScreen> createState() => _AwarenessDetailScreenState();
}

class _AwarenessDetailScreenState extends State<AwarenessDetailScreen> {
  int _score = 0;
  bool _isBookmarked = false;
  String? _awarenessId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _awarenessId = args['id'] as String?;
        _loadBookmarkStatus();
      }
    });
  }

  Future<void> _loadBookmarkStatus() async {
    if (_awarenessId == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookmarks')
          .where('userId', isEqualTo: uid)
          .where('itemId', isEqualTo: _awarenessId)
          .where('type', isEqualTo: 'awareness')
          .limit(1)
          .get();

      if (mounted) {
        setState(() => _isBookmarked = snapshot.docs.isNotEmpty);
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmark(String title) async {
    if (_awarenessId == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      if (_isBookmarked) {
        final snapshot = await FirebaseFirestore.instance
            .collection('bookmarks')
            .where('userId', isEqualTo: uid)
            .where('itemId', isEqualTo: _awarenessId)
            .where('type', isEqualTo: 'awareness')
            .limit(1)
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        setState(() => _isBookmarked = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from bookmarks')),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('bookmarks').add({
          'userId': uid,
          'itemId': _awarenessId,
          'type': 'awareness',
          'title': title,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() => _isBookmarked = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to bookmarks')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    
    // Support both old AwarenessTopic and new Map format
    if (args is Map<String, dynamic>) {
      final title = args['title'] ?? args['name'] ?? 'Awareness';
      final description = args['description'] ?? args['body'] ?? '';
      final symptoms = (args['symptoms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final link = args['link'] as String?;
      final imageUrl = args['imageUrl'] as String?;
      
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey.shade100,
          leadingWidth: 56,
          leading: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: AppBrand.compact(logoSize: 28),
          ),
          title: Text(title.toString()),
          actions: [
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: () => _toggleBookmark(title.toString()),
              tooltip: _isBookmarked ? 'Remove bookmark' : 'Add bookmark',
            ),
            const TopActions(),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 0),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toString(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description.toString(),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (symptoms.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Symptoms:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...symptoms.map((symptom) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    symptom,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    if (link != null && link.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openLink(link),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Learn More'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback to old AwarenessTopic format (for backward compatibility)
    final topic = args as AwarenessTopic?;
    if (topic == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey.shade100,
          leadingWidth: 56,
          leading: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: AppBrand.compact(logoSize: 28),
          ),
          title: const Text('Awareness'),
        ),
        body: const Center(child: Text('No awareness data available')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AppBrand.compact(logoSize: 28),
        ),
        title: Text(topic.title),
        actions: const [TopActions()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(topic.content),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Symptoms'),
              children: topic.symptoms
                  .map((e) => ListTile(title: Text(e)))
                  .toList(),
            ),
            ExpansionTile(
              title: const Text('Common Myths'),
              children: topic.myths
                  .map((e) => ListTile(title: Text(e)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await showDialog<int>(
                  context: context,
                  builder: (ctx) {
                    int localScore = 0;
                    int? selected;
                    return StatefulBuilder(
                      builder: (ctx, setState) {
                        return AlertDialog(
                          title: const Text('Quick Quiz'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'HIV can be transmitted through casual contact?',
                              ),
                              const SizedBox(height: 12),
                              SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment<int>(value: 0, label: Text('True'), icon: Icon(Icons.check_circle_outline)),
                                  ButtonSegment<int>(value: 1, label: Text('False'), icon: Icon(Icons.cancel_outlined)),
                                ],
                                selected: selected == null ? <int>{} : {selected!},
                                onSelectionChanged: (s) => setState(() => selected = s.isEmpty ? null : s.first),
                                multiSelectionEnabled: false,
                                showSelectedIcon: true,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: selected == null
                                  ? null
                                  : () {
                                      if (selected == 1) {
                                        localScore = 1; // correct
                                      }
                                      Navigator.pop(ctx, localScore);
                                    },
                              child: const Text('Submit'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
                if (result != null) {
                  if (!context.mounted) return;
                  setState(() => _score = result);
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Score: $_score/1')),
                  );
                }
              },
              child: const Text('Take Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
