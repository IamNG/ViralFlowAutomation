import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viralflow_automation/app/app_theme.dart';
import 'package:viralflow_automation/core/models/content_model.dart';
import 'package:viralflow_automation/core/providers/providers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum CreationMode { ai, manual }

class CreateContentPage extends ConsumerStatefulWidget {
  const CreateContentPage({super.key});

  @override
  ConsumerState<CreateContentPage> createState() => _CreateContentPageState();
}

class _CreateContentPageState extends ConsumerState<CreateContentPage> {
  CreationMode _creationMode = CreationMode.ai;
  PlatformFile? _selectedMedia;

  final _promptController = TextEditingController();
  final _captionController = TextEditingController();
  ContentType _selectedContentType = ContentType.post;
  final Set<Platform> _selectedPlatforms = {Platform.instagram};
  String _selectedTone = 'casual';
  String _selectedLanguage = 'hinglish';
  bool _isGenerating = false;
  bool _isGeneratingImage = false;
  String _generatedCaption = '';
  List<String> _generatedHashtags = [];
  String? _generatedImageUrl;

  final List<Map<String, dynamic>> _contentTypes = [
    {'type': ContentType.post, 'icon': Icons.article_rounded, 'label': 'Post'},
    {'type': ContentType.reel, 'icon': Icons.play_circle_rounded, 'label': 'Reel'},
    {'type': ContentType.story, 'icon': Icons.auto_stories_rounded, 'label': 'Story'},
    {'type': ContentType.thread, 'icon': Icons.forum_rounded, 'label': 'Thread'},
    {'type': ContentType.carousel, 'icon': Icons.view_carousel_rounded, 'label': 'Carousel'},
    {'type': ContentType.tweet, 'icon': Icons.tag_rounded, 'label': 'Tweet'},
    {'type': ContentType.youtubeShort, 'icon': Icons.smart_display_rounded, 'label': 'YT Short'},
    {'type': ContentType.blog, 'icon': Icons.edit_note_rounded, 'label': 'Blog'},
  ];

  final List<Map<String, dynamic>> _platforms = [
    {'platform': Platform.instagram, 'icon': Icons.camera_alt_rounded, 'label': 'Instagram', 'color': Color(0xFFE1306C)},
    {'platform': Platform.youtube, 'icon': Icons.smart_display_rounded, 'label': 'YouTube', 'color': Color(0xFFFF0000)},
    {'platform': Platform.twitter, 'icon': Icons.tag_rounded, 'label': 'Twitter', 'color': Color(0xFF1DA1F2)},
    {'platform': Platform.linkedin, 'icon': Icons.work_rounded, 'label': 'LinkedIn', 'color': Color(0xFF0077B5)},
    {'platform': Platform.facebook, 'icon': Icons.facebook_rounded, 'label': 'Facebook', 'color': Color(0xFF1877F2)},
    {'platform': Platform.tiktok, 'icon': Icons.music_note_rounded, 'label': 'TikTok', 'color': Color(0xFF000000)},
  ];

  final List<Map<String, String>> _tones = [
    {'value': 'casual', 'label': '😊 Casual'},
    {'value': 'professional', 'label': '💼 Professional'},
    {'value': 'humorous', 'label': '😂 Humorous'},
    {'value': 'inspirational', 'label': '✨ Inspirational'},
    {'value': 'educational', 'label': '📚 Educational'},
    {'value': 'controversial', 'label': '🔥 Controversial'},
  ];

  final List<Map<String, String>> _languages = [
    {'value': 'hinglish', 'label': '🇮🇳 Hinglish'},
    {'value': 'english', 'label': '🇺🇸 English'},
    {'value': 'hindi', 'label': '🇮🇳 Hindi'},
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _generateContent() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt first!')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final result = await ref.read(aiServiceProvider).generateContent(
            prompt: _promptController.text.trim(),
            contentType: _selectedContentType,
            platforms: _selectedPlatforms.toList(),
            tone: _selectedTone,
            language: _selectedLanguage,
          );

      setState(() {
        _generatedCaption = result.caption;
        _generatedHashtags = result.hashtags;
        _captionController.text = result.caption;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateImage() async {
    if (_promptController.text.trim().isEmpty) return;

    setState(() => _isGeneratingImage = true);

    try {
      final imageUrl = await ref.read(aiServiceProvider).generateImage(
            prompt: _promptController.text.trim(),
          );
      setState(() => _generatedImageUrl = imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
  }

  Future<void> _generateHashtags() async {
    if (_captionController.text.trim().isEmpty) return;

    try {
      final hashtags = await ref.read(aiServiceProvider).generateHashtags(
            content: _captionController.text.trim(),
            platform: _selectedPlatforms.first,
          );
      setState(() => _generatedHashtags = hashtags);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hashtag error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedMedia = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Content ✨')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _creationMode = CreationMode.ai),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _creationMode == CreationMode.ai ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _creationMode == CreationMode.ai ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                        ),
                        child: const Center(child: Text('✨ AI Autopilot', style: TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _creationMode = CreationMode.manual),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _creationMode == CreationMode.manual ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _creationMode == CreationMode.manual ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                        ),
                        child: const Center(child: Text('📤 Upload Media (BYOC)', style: TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step 1: Content Type
            _SectionTitle('1. Content Type', Icons.category_rounded),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _contentTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = _contentTypes[index];
                  final isSelected = _selectedContentType == item['type'];
                  return _TypeChip(
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedContentType = item['type']),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Step 2: Platform Selection
            _SectionTitle('2. Select Platforms', Icons.share_rounded),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _platforms.map((item) {
                final isSelected = _selectedPlatforms.contains(item['platform']);
                return FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPlatforms.add(item['platform'] as Platform);
                      } else {
                        _selectedPlatforms.remove(item['platform']);
                      }
                    });
                  },
                  avatar: Icon(item['icon'] as IconData, size: 16, color: item['color'] as Color),
                  label: Text(item['label'] as String),
                  selectedColor: (item['color'] as Color).withOpacity(0.2),
                  checkmarkColor: item['color'] as Color,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Step 3: Conditional based on Mode
            if (_creationMode == CreationMode.ai) ...[
              _SectionTitle('3. What do you want to create?', Icons.auto_awesome_rounded),
              const SizedBox(height: 12),
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'E.g., "Write a viral Instagram post about AI tools for students in Hinglish"',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tone & Language Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTone,
                            isExpanded: true,
                            items: _tones.map((t) => DropdownMenuItem(
                              value: t['value'],
                              child: Text(t['label']!, style: const TextStyle(fontSize: 13)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedTone = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Language', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            isExpanded: true,
                            items: _languages.map((l) => DropdownMenuItem(
                              value: l['value'],
                              child: Text(l['label']!, style: const TextStyle(fontSize: 13)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedLanguage = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateContent,
                icon: _isGenerating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_isGenerating ? 'Generating...' : 'Generate with AI ✨'),
              ),
            ),
            ] else ...[
              // MANUAL MODE UI
              _SectionTitle('3. Upload your Media', Icons.upload_file_rounded),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), style: BorderStyle.solid, width: 2), // Changed to solid for simplicity 
                  ),
                  child: Center(
                    child: _selectedMedia == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_rounded, size: 48, color: AppTheme.primaryColor.withOpacity(0.7)),
                              const SizedBox(height: 12),
                              const Text('Tap to upload Video or Image', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                              const SizedBox(height: 4),
                              Text('Supports MP4, MOV, JPG, PNG', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 48, color: AppTheme.successColor),
                              const SizedBox(height: 12),
                              Text(_selectedMedia!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1),
                              const SizedBox(height: 4),
                              Text('${(_selectedMedia!.size / 1024 / 1024).toStringAsFixed(2)} MB', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle('4. Write Caption', Icons.edit_note_rounded),
              const SizedBox(height: 12),
              TextField(
                controller: _captionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your caption or description here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _generateHashtags,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Auto-generate Hashtags from Caption'),
              ),
            ],
            const SizedBox(height: 24),

            // Generated Content Preview
            if (_generatedCaption.isNotEmpty || _isGenerating) ...[
              _SectionTitle('4. Generated Content', Icons.preview_rounded),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withOpacity(0.05), AppTheme.secondaryColor.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Caption', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          onPressed: () {
                            // Copy to clipboard
                          },
                          tooltip: 'Copy',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captionController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'AI-generated caption will appear here...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hashtags
                    if (_generatedHashtags.isNotEmpty) ...[
                      const Text('Hashtags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _generatedHashtags.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              labelStyle: const TextStyle(color: AppTheme.primaryColor),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            )).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _generateHashtags,
                            icon: const Icon(Icons.tag_rounded, size: 18),
                            label: const Text('Regenerate Tags'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isGeneratingImage ? null : _generateImage,
                            icon: _isGeneratingImage
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.image_rounded, size: 18),
                            label: const Text('Generate Image'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Generated Image Preview
              if (_generatedImageUrl != null) ...[
                _SectionTitle('5. Generated Image', Icons.image_rounded),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _generatedImageUrl!,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Save / Schedule Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveContent(ContentStatus.draft),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Draft'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveContent(ContentStatus.scheduled),
                      icon: const Icon(Icons.schedule_rounded),
                      label: const Text('Schedule'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveContent(ContentStatus status) async {
    if (_creationMode == CreationMode.manual && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image or video to upload!')),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing and Saving... ⏳')),
      );
    }

    try {
      String finalImageUrl = _generatedImageUrl ?? '';
      String finalVideoUrl = '';

      if (_creationMode == CreationMode.manual && _selectedMedia != null) {
        final uploadedUrl = await ref.read(contentServiceProvider).uploadMedia(_selectedMedia!);
        final ext = _selectedMedia!.extension?.toLowerCase() ?? '';
        if (ext == 'mp4' || ext == 'mov' || ext == 'avi') {
          finalVideoUrl = uploadedUrl;
        } else {
          finalImageUrl = uploadedUrl;
        }
      }

      String titleText = _creationMode == CreationMode.manual 
          ? (_captionController.text.isEmpty ? 'Uploaded Media Post' : _captionController.text) 
          : _promptController.text.trim();
          
      if (titleText.length > 50) titleText = titleText.substring(0, 50);

      await ref.read(contentServiceProvider).createContent(
            ContentModel(
              id: '',
              userId: '',
              title: titleText.isEmpty ? 'New Post' : titleText,
              caption: _captionController.text.trim(),
              hashtags: _generatedHashtags,
              imageUrl: finalImageUrl,
              videoUrl: finalVideoUrl, // Added dynamically
              aiPrompt: _creationMode == CreationMode.ai ? _promptController.text.trim() : '',
              contentType: _selectedContentType,
              status: status,
              platforms: _selectedPlatforms.toList(),
              createdAt: DateTime.now(),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == ContentStatus.draft ? 'Draft saved successfully! 📝' : 'Content scheduled successfully! 📅'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        setState(() {
          _selectedMedia = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}