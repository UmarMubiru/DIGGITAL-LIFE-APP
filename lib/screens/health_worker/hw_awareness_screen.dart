import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_life_care_app/widgets/hw_top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HWAwarenessScreen extends StatefulWidget {
  const HWAwarenessScreen({super.key});

  @override
  State<HWAwarenessScreen> createState() => _HWAwarenessScreenState();
}

class _HWAwarenessScreenState extends State<HWAwarenessScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AppBrand.compact(logoSize: 28),
        ),
        title: const Text('Awareness Content'),
        actions: const [HWTopActions()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/hw/awareness/upload'),
        icon: const Icon(Icons.add),
        label: const Text('Add New'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: 'All',
                        isSelected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Bacterial',
                        isSelected: _selectedCategory == 'Bacterial',
                        onTap: () => setState(() => _selectedCategory = 'Bacterial'),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Viral',
                        isSelected: _selectedCategory == 'Viral',
                        onTap: () => setState(() => _selectedCategory = 'Viral'),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Parasitic',
                        isSelected: _selectedCategory == 'Parasitic',
                        onTap: () => setState(() => _selectedCategory = 'Parasitic'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Awareness List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error loading awareness: ${snap.error}'),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                
                // Filter by search query and category
                final filteredDocs = docs.where((doc) {
                  final data = (doc.data() ?? <String, dynamic>{}) as Map<String, dynamic>;
                  final name = (data['name'] ?? data['title'] ?? '').toString().toLowerCase();
                  final category = data['category'] as String?;
                  
                  // Search filter
                  final matchesSearch = _searchQuery.isEmpty || 
                      name.contains(_searchQuery.toLowerCase());
                  
                  // Category filter
                  final matchesCategory = _selectedCategory == null || 
                      (category != null && category == _selectedCategory);
                  
                  return matchesSearch && matchesCategory;
                }).toList();
                
                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCategory != null
                              ? 'No results found'
                              : 'No awareness posts yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_searchQuery.isEmpty && _selectedCategory == null)
                          Text(
                            'Tap the + button to add your first awareness post',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (c, i) {
                    final d = filteredDocs[i];
                    final data =
                        (d.data() ?? <String, dynamic>{}) as Map<String, dynamic>;
                    final title = (data['title'] ?? data['name'] ?? '').toString();
                    final description = (data['description'] ?? data['body'] ?? '').toString();
                    final imageUrl = (data['imageUrl'] ?? '').toString();
                    final author = (data['authorName'] ?? 'Health Worker').toString();
                    final authorId = (data['authorId'] ?? '').toString();
                    final createdAt = data['createdAt'] ?? data['dateUpdated'];
                    final link = (data['link'] ?? '').toString();
                    final category = data['category'] as String?;
                    final symptoms = (data['symptoms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                    
                    DateTime? time;
                    if (createdAt is Timestamp) {
                      time = createdAt.toDate();
                    } else if (createdAt != null) {
                      try {
                        time = (createdAt as Timestamp).toDate();
                      } catch (_) {}
                    }
                    
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                    final canEdit = authorId == currentUserId;

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
                            '/hw/awareness/detail',
                            arguments: <String, dynamic>{
                              'id': d.id,
                              'title': title,
                              'description': description,
                              'imageUrl': imageUrl,
                              'link': link,
                              'symptoms': symptoms,
                              'category': category,
                              'author': author,
                              'createdAt': time,
                              'canEdit': canEdit,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category badge
                            if (category != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                                child: Chip(
                                  label: Text(
                                    category,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  padding: EdgeInsets.zero,
                                  backgroundColor: _getCategoryColor(category),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            if (imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: category != null ? const Radius.circular(0) : const Radius.circular(12),
                                  bottom: const Radius.circular(0),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 160,
                                  // ignore: unnecessary_underscores
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
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      // Edit/Delete buttons for authors
                                      if (canEdit)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20),
                                              onPressed: () => _editPost(context, d.id, data),
                                              tooltip: 'Edit',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                              onPressed: () => _deletePost(context, d.id, title),
                                              tooltip: 'Delete',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    description.isNotEmpty 
                                        ? (description.length > 150 
                                            ? '${description.substring(0, 150)}...' 
                                            : description)
                                        : 'No description available',
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
                                      if (time != null)
                                        Text(
                                          DateFormat('MMM d, y').format(time),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bacterial':
        return Colors.blue.shade100;
      case 'Viral':
        return Colors.red.shade100;
      case 'Parasitic':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Future<void> _editPost(BuildContext context, String docId, Map<String, dynamic> data) async {
    Navigator.pushNamed(
      context,
      '/hw/awareness/upload',
      arguments: {
        'editMode': true,
        'docId': docId,
        'data': data,
      },
    );
  }

  Future<void> _deletePost(BuildContext context, String docId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Awareness Post'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseFirestore.instance.collection('awareness').doc(docId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting post: $e')),
          );
        }
      }
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      // ignore: deprecated_member_use
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}
