// ignore_for_file: unnecessary_underscores

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

enum ContentType { link, file, text }

class HWAwarenessUploadScreen extends StatefulWidget {
  const HWAwarenessUploadScreen({super.key});
  @override
  State<HWAwarenessUploadScreen> createState() =>
      _HWAwarenessUploadScreenState();
}

class _HWAwarenessUploadScreenState extends State<HWAwarenessUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _symptomCtrl = TextEditingController();
  final List<String> _symptoms = [];
  String? _selectedCategory;
  ContentType _contentType = ContentType.text;
  XFile? _pickedImage;
  PlatformFile? _pickedFile; // PDF/Word document
  bool _loading = false;
  bool _isEditMode = false;
  String? _docId;
  String? _existingImageUrl;
  String? _existingFileUrl;
  String? _existingFileName;

  @override
  void initState() {
    super.initState();
    // Check if we're in edit mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['editMode'] == true) {
        _isEditMode = true;
        _docId = args['docId'] as String?;
        final data = args['data'] as Map<String, dynamic>?;
        if (data != null) {
          _nameCtrl.text = (data['name'] ?? data['title'] ?? '').toString();
          _descriptionCtrl.text = (data['description'] ?? data['body'] ?? '').toString();
          _linkCtrl.text = (data['link'] ?? '').toString();
          _selectedCategory = data['category'] as String?;
          _existingImageUrl = data['imageUrl'] as String?;
          _existingFileUrl = data['fileUrl'] as String?;
          _existingFileName = data['fileName'] as String?;
          
          // Determine content type
          if (_existingFileUrl != null && _existingFileUrl!.isNotEmpty) {
            _contentType = ContentType.file;
          } else if (_linkCtrl.text.trim().isNotEmpty) {
            _contentType = ContentType.link;
          } else {
            _contentType = ContentType.text;
          }
          
          if (data['symptoms'] != null) {
            _symptoms.addAll((data['symptoms'] as List).map((e) => e.toString()).toList());
          }
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _linkCtrl.dispose();
    _symptomCtrl.dispose();
    super.dispose();
  }

  void _addSymptom() {
    final symptom = _symptomCtrl.text.trim();
    if (symptom.isNotEmpty && !_symptoms.contains(symptom)) {
      setState(() {
        _symptoms.add(symptom);
        _symptomCtrl.clear();
      });
    }
  }

  void _removeSymptom(String symptom) {
    setState(() {
      _symptoms.remove(symptom);
    });
  }

  Future<void> _pickImage() async {
    final p = ImagePicker();
    final file = await p.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _pickedFile = result.files.single;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage(XFile file) async {
    final ref = FirebaseStorage.instance.ref().child(
      'awareness_images/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );
    final task = await ref.putFile(File(file.path));
    return await ref.getDownloadURL();
  }

  Future<String?> _uploadFile(PlatformFile file) async {
    if (file.path == null) return null;
    final extension = file.extension ?? 'pdf';
    final ref = FirebaseStorage.instance.ref().child(
      'awareness_files/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );
    final task = await ref.putFile(File(file.path!));
    return await ref.getDownloadURL();
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate based on content type
    if (_contentType == ContentType.link && !_isValidUrl(_linkCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL (starting with http:// or https://)')),
      );
      return;
    }
    
    if (_contentType == ContentType.file && _pickedFile == null && _existingFileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a file (PDF or Word document)')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      String imageUrl = '';
      if (_pickedImage != null) {
        imageUrl = (await _uploadImage(_pickedImage!)) ?? '';
      } else {
        imageUrl = _existingImageUrl ?? '';
      }

      String? fileUrl;
      String? fileName;
      
      if (_contentType == ContentType.file) {
        if (_pickedFile != null) {
          fileUrl = await _uploadFile(_pickedFile!);
          fileName = _pickedFile!.name;
        } else {
          fileUrl = _existingFileUrl;
          fileName = _existingFileName;
        }
      }

      final user = context.read<UserProvider>();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      final awarenessData = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'title': _nameCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'body': _descriptionCtrl.text.trim(),
        'imageUrl': imageUrl,
        'link': _contentType == ContentType.link ? _linkCtrl.text.trim() : '',
        'fileUrl': _contentType == ContentType.file ? (fileUrl ?? '') : '',
        'fileName': _contentType == ContentType.file ? (fileName ?? '') : '',
        'contentType': _contentType.name,
        'symptoms': _symptoms,
        'category': _selectedCategory,
        'authorId': uid,
        'authorName': user.username,
        'dateUpdated': FieldValue.serverTimestamp(),
      };
      
      if (_isEditMode && _docId != null) {
        await FirebaseFirestore.instance.collection('awareness').doc(_docId).update(awarenessData);
      } else {
        awarenessData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('awareness').add(awarenessData);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Awareness Post' : 'Create Awareness Content'),
        backgroundColor: Colors.grey.shade100,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AppBrand.compact(logoSize: 28),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Chlamydia Prevention Guide',
                    helperText: 'Enter a clear, descriptive title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe the STD, its causes, symptoms, and prevention',
                    helperText: 'Provide detailed information',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 6,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Content Type Selection
                const Text(
                  'Content Type *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.text_fields, size: 18),
                            SizedBox(width: 4),
                            Text('Text'),
                          ],
                        ),
                        selected: _contentType == ContentType.text,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _contentType = ContentType.text;
                              _linkCtrl.clear();
                              _pickedFile = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.link, size: 18),
                            SizedBox(width: 4),
                            Text('Link'),
                          ],
                        ),
                        selected: _contentType == ContentType.link,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _contentType = ContentType.link;
                              _pickedFile = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.insert_drive_file, size: 18),
                            SizedBox(width: 4),
                            Text('File'),
                          ],
                        ),
                        selected: _contentType == ContentType.file,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _contentType = ContentType.file;
                              _linkCtrl.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Content-specific fields
                if (_contentType == ContentType.link) ...[
                  TextFormField(
                    controller: _linkCtrl,
                    decoration: InputDecoration(
                      labelText: 'Content URL *',
                      hintText: 'https://example.com/awareness-content',
                      helperText: 'Enter a valid URL that displays your awareness content',
                      prefixIcon: const Icon(Icons.link),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      final url = (v ?? '').trim();
                      if (url.isEmpty) {
                        return 'URL is required for link content type';
                      }
                      if (!_isValidUrl(url)) {
                        return 'Please enter a valid URL (must start with http:// or https://)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (_contentType == ContentType.file) ...[
                  Card(
                    color: Colors.grey.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Upload PDF or Word document (DOC, DOCX)',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_pickedFile != null || (_existingFileUrl != null && _existingFileUrl!.isNotEmpty)) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.insert_drive_file,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _pickedFile?.name ?? _existingFileName ?? 'File',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (_pickedFile != null)
                                          Text(
                                            '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _pickedFile = null;
                                        _existingFileUrl = null;
                                        _existingFileName = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Select PDF or Word Document'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Category Selection
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Bacterial', 'Viral', 'Parasitic', 'Fungal'].map((category) {
                    return ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Symptoms section
                const Text(
                  'Symptoms',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _symptomCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Add symptom',
                          hintText: 'e.g., Pain during urination',
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _addSymptom(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addSymptom,
                      child: const Text('Add'),
                    ),
                  ],
                ),
                if (_symptoms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _symptoms.map((symptom) {
                      return Chip(
                        label: Text(symptom),
                        onDeleted: () => _removeSymptom(symptom),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                
                // Image upload
                if (_pickedImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_pickedImage!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _existingImageUrl != null
                              ? Image.network(
                                  _existingImageUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                )
                              : const SizedBox(),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _pickedImage = null;
                              _existingImageUrl = null;
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(_pickedImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                      ? 'Change Cover Image'
                      : 'Add Cover Image (optional)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Submit button
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEditMode ? 'Update Content' : 'Publish Content',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
