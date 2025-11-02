// ignore_for_file: unnecessary_underscores, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/widgets/top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AwarenessHomeScreen extends StatefulWidget {
  const AwarenessHomeScreen({super.key});

  @override
  State<AwarenessHomeScreen> createState() => _AwarenessHomeScreenState();
}

class _AwarenessHomeScreenState extends State<AwarenessHomeScreen> {
  final PageController _carouselController = PageController();
  int _currentCarouselIndex = 0;
  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    // Auto-advance carousel
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _autoAdvanceCarousel();
      }
    });
  }

  void _autoAdvanceCarousel() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || !_carouselController.hasClients) {
        _autoAdvanceCarousel();
        return;
      }
      try {
        final maxIndex = _carouselController.position.maxScrollExtent ~/ 
            _carouselController.position.viewportDimension;
        if (_currentCarouselIndex < maxIndex) {
          _currentCarouselIndex++;
          _carouselController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _currentCarouselIndex = 0;
          _carouselController.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      } catch (_) {
        // Handle errors silently
      }
      _autoAdvanceCarousel();
    });
  }

  Future<void> _loadBookmarks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookmarks')
          .where('userId', isEqualTo: uid)
          .where('type', isEqualTo: 'awareness')
          .get();

      if (mounted) {
        setState(() {
          _bookmarkedIds.clear();
          _bookmarkedIds.addAll(
            snapshot.docs.map((doc) => doc.data()['itemId'] as String),
          );
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleBookmark(String awarenessId, String title) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final isBookmarked = _bookmarkedIds.contains(awarenessId);

    try {
      if (isBookmarked) {
        // Remove bookmark
        final snapshot = await FirebaseFirestore.instance
            .collection('bookmarks')
            .where('userId', isEqualTo: uid)
            .where('itemId', isEqualTo: awarenessId)
            .where('type', isEqualTo: 'awareness')
            .limit(1)
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        setState(() => _bookmarkedIds.remove(awarenessId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from bookmarks')),
          );
        }
      } else {
        // Add bookmark
        await FirebaseFirestore.instance.collection('bookmarks').add({
          'userId': uid,
          'itemId': awarenessId,
          'type': 'awareness',
          'title': title,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() => _bookmarkedIds.add(awarenessId));
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

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AppBrand.compact(logoSize: 28),
        ),
        title: const Text('Awareness'),
        actions: [TopActions()],
      ),
      floatingActionButton: user.role == 'health_worker'
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/hw/awareness/upload'),
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('awareness')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error loading awareness: ${snap.error}'),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No awareness posts yet.'));
          }

          // Get recent posts for carousel
          final recentPosts = docs.take(5).toList();

          return Column(
            children: [
              // "Did You Know?" Carousel
              if (recentPosts.isNotEmpty)
                Container(
                  height: 200,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _carouselController,
                          onPageChanged: (index) {
                            setState(() => _currentCarouselIndex = index);
                          },
                          itemCount: recentPosts.length,
                          itemBuilder: (context, index) {
                            final doc = recentPosts[index];
                            final data = (doc.data() ?? <String, dynamic>{}) as Map<String, dynamic>;
                            final title = (data['name'] ?? data['title'] ?? 'Awareness').toString();
                            final description = (data['description'] ?? data['body'] ?? '').toString();
                            final imageUrl = data['imageUrl'] as String?;
                            
                            return Container(
                              decoration: BoxDecoration(
                                gradient: imageUrl == null || imageUrl.isEmpty
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                        ],
                                      )
                                    : null,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (imageUrl != null && imageUrl.isNotEmpty)
                                    Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox(),
                                    ),
                                  if (imageUrl != null && imageUrl.isNotEmpty)
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.5),
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(  // FIXED: This Row was missing its closing parenthesis
                                          children: [
                                            Icon(
                                              Icons.lightbulb_outline,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Did You Know?',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),  // ADDED: Missing closing parenthesis for Row
                                        const SizedBox(height: 12),
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          description.isNotEmpty
                                              ? (description.length > 80
                                                  ? '${description.substring(0, 80)}...'
                                                  : description)
                                              : 'Learn more about health awareness',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Carousel indicators
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              recentPosts.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentCarouselIndex == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Awareness List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final d = docs[i];
                    final data =
                        (d.data() ?? <String, dynamic>{}) as Map<String, dynamic>;
                    final title = (data['title'] ?? data['name'] ?? '').toString();
                    final body = (data['body'] ?? data['description'] ?? '').toString();
                    final imageUrl = (data['imageUrl'] ?? '').toString();
                    final author = (data['authorName'] ?? 'Health Worker').toString();
                    final createdAt = data['createdAt'] as Timestamp?;
                    final link = data['link'] as String?;
                    final symptoms = (data['symptoms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                    final time = createdAt != null
                        ? (createdAt.toDate())
                        : DateTime.now();
                    final isBookmarked = _bookmarkedIds.contains(d.id);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/awareness/detail',
                            arguments: <String, dynamic>{
                              'id': d.id,
                              'title': title,
                              'name': title,
                              'description': body,
                              'body': body,
                              'imageUrl': imageUrl,
                              'link': link,
                              'symptoms': symptoms,
                              'author': author,
                              'createdAt': time,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 160,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(height: 0),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ),
                                      // Bookmark button
                                      IconButton(
                                        icon: Icon(
                                          isBookmarked
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          color: isBookmarked
                                              ? Theme.of(context).colorScheme.primary
                                              : null,
                                        ),
                                        onPressed: () => _toggleBookmark(d.id, title),
                                        tooltip: isBookmarked
                                            ? 'Remove bookmark'
                                            : 'Add bookmark',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    body,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (symptoms.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      children: symptoms.take(3).map((symptom) {
                                        return Chip(
                                          label: Text(
                                            symptom,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'by $author',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        TimeOfDay.fromDateTime(time).format(context),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}