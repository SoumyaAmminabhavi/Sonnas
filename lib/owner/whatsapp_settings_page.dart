import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/whatsapp_service.dart';

class WhatsAppSettingsPage extends StatefulWidget {
  final VoidCallback onClose;
  const WhatsAppSettingsPage({super.key, required this.onClose});

  @override
  State<WhatsAppSettingsPage> createState() => _WhatsAppSettingsPageState();
}

class _WhatsAppSettingsPageState extends State<WhatsAppSettingsPage> {
  Map<String, dynamic>? _selectedTemplate;
  List<Map<String, dynamic>> _selectedTemplateVersions = [];
  Map<String, dynamic>? _selectedVersionDetails;
  bool _isLoadingVersions = false;
  int _activeInspectorTab = 0; // 0 = Config, 1 = Preview

  // Simplified editing controllers
  final _bodyController = TextEditingController();
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  final _ctaButtonTitleController = TextEditingController();
  final _ctaButtonUrlController = TextEditingController();

  String _mediaType = 'NONE';
  String _interactiveType = 'NONE';
  bool _isSavingLive = false;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    // Update live simulator preview in-memory as text is changed
    _bodyController.addListener(() {
      if (_selectedVersionDetails != null && _selectedVersionDetails!['bodyText'] != _bodyController.text) {
        setState(() {
          _selectedVersionDetails!['bodyText'] = _bodyController.text;
        });
      }
    });
    _headerController.addListener(() {
      if (_selectedVersionDetails != null && _selectedVersionDetails!['headerText'] != _headerController.text) {
        setState(() {
          _selectedVersionDetails!['headerText'] = _headerController.text.isNotEmpty ? _headerController.text : null;
        });
      }
    });
    _footerController.addListener(() {
      if (_selectedVersionDetails != null && _selectedVersionDetails!['footerText'] != _footerController.text) {
        setState(() {
          _selectedVersionDetails!['footerText'] = _footerController.text.isNotEmpty ? _footerController.text : null;
        });
      }
    });
    _mediaUrlController.addListener(() {
      if (_selectedVersionDetails != null && _selectedVersionDetails!['mediaUrl'] != _mediaUrlController.text) {
        setState(() {
          _selectedVersionDetails!['mediaUrl'] = _mediaUrlController.text.isNotEmpty ? _mediaUrlController.text : null;
        });
      }
    });
    _ctaButtonTitleController.addListener(() {
      if (_selectedVersionDetails != null && _selectedVersionDetails!['ctaButtonTitle'] != _ctaButtonTitleController.text) {
        setState(() {
          _selectedVersionDetails!['ctaButtonTitle'] = _ctaButtonTitleController.text.isNotEmpty ? _ctaButtonTitleController.text : null;
        });
      }
    });
    _ctaButtonUrlController.addListener(() {
      if (_selectedVersionDetails != null && _selectedVersionDetails!['ctaButtonUrl'] != _ctaButtonUrlController.text) {
        setState(() {
          _selectedVersionDetails!['ctaButtonUrl'] = _ctaButtonUrlController.text.isNotEmpty ? _ctaButtonUrlController.text : null;
        });
      }
    });
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    _mediaUrlController.dispose();
    _ctaButtonTitleController.dispose();
    _ctaButtonUrlController.dispose();
    super.dispose();
  }

  Future<void> _uploadMediaFile() async {
    try {
      setState(() => _isUploadingMedia = true);
      
      // Determine allowed extensions based on media type
      List<String>? allowedExtensions;
      if (_mediaType == 'DOCUMENT') {
        allowedExtensions = ['pdf', 'doc', 'docx'];
      } else if (_mediaType == 'IMAGE') {
        allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
      } else if (_mediaType == 'VIDEO') {
        allowedExtensions = ['mp4', 'avi', 'mov', 'mkv'];
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isUploadingMedia = false);
        return;
      }

      final file = result.files.first;
      final supabase = Supabase.instance.client;
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_mediaType.toLowerCase()}_${timestamp}_${file.name}';
      final bucket = 'cakes'; // Using existing 'cakes' bucket

      // Upload to Supabase Storage
      await supabase.storage
          .from(bucket)
          .uploadBinary(fileName, file.bytes!);

      // Get public URL
      final publicUrl = supabase.storage
          .from(bucket)
          .getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          _mediaUrlController.text = publicUrl;
          _selectedVersionDetails?['mediaUrl'] = publicUrl;
          _isUploadingMedia = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error uploading file: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isUploadingMedia = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _loadTemplateVersions(String templateId) async {
    final currentTemplateId = _selectedTemplate?['id']?.toString();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoadingVersions = true;
      _selectedTemplateVersions = [];
      _selectedVersionDetails = null;
    });

    try {
      final rawVersions = await WhatsAppService.fetchTemplateVersions(templateId);
      
      // Stale response guard
      if (currentTemplateId != _selectedTemplate?['id']?.toString()) {
        return;
      }

      // Convert all version maps to modifiable maps
      final List<Map<String, dynamic>> versions = rawVersions.map((v) => Map<String, dynamic>.from(v)).toList();

      final activeVersionId = _selectedTemplate?['activeVersionId']?.toString();

      Map<String, dynamic>? activeVer;
      Map<String, dynamic>? selectedVer;

      if (versions.isNotEmpty) {
        if (activeVersionId != null) {
          activeVer = versions.firstWhere(
            (v) => v['id'] == activeVersionId,
            orElse: () => versions.first,
          );
        } else {
          activeVer = versions.first;
        }
        selectedVer = activeVer;
      }

      if (!mounted) return;
      setState(() {
        _selectedTemplateVersions = versions;
        _selectedVersionDetails = selectedVer;
        _isLoadingVersions = false;

        _bodyController.text = selectedVer?['bodyText']?.toString() ?? '';
        _headerController.text = selectedVer?['headerText']?.toString() ?? '';
        _footerController.text = selectedVer?['footerText']?.toString() ?? '';
        _mediaUrlController.text = selectedVer?['mediaUrl']?.toString() ?? '';
        _ctaButtonTitleController.text = selectedVer?['ctaButtonTitle']?.toString() ?? '';
        _ctaButtonUrlController.text = selectedVer?['ctaButtonUrl']?.toString() ?? '';
        _mediaType = selectedVer?['mediaType']?.toString() ?? 'NONE';
        _interactiveType = selectedVer?['interactiveType']?.toString() ?? 'NONE';
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading template versions: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Stale response guard
      if (currentTemplateId != _selectedTemplate?['id']?.toString()) {
        return;
      }

      if (!mounted) return;
      setState(() => _isLoadingVersions = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Error loading template versions: $e')),
      );
    }
  }

  void _showCreateTemplateDialog() {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final descController = TextEditingController();
    String category = 'GENERAL';
    String language = 'en';
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: !isSubmitting,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Text(
                  "New Notification Template",
                  style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: codeController,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            labelText: "Template Code",
                            hintText: "e.g., WELCOME_MESSAGE, CART_ALERT",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? "Code is required" : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: isSubmitting ? [
                            DropdownMenuItem(value: category, child: Text(category)),
                          ] : const [
                            DropdownMenuItem(value: 'GREETING', child: Text('Greeting / Welcome')),
                            DropdownMenuItem(value: 'MENU', child: Text('Menu Navigation')),
                            DropdownMenuItem(value: 'CATEGORY', child: Text('Category Browse')),
                            DropdownMenuItem(value: 'PRODUCT', child: Text('Product / Catalog')),
                            DropdownMenuItem(value: 'ORDER', child: Text('Order Status Update')),
                            DropdownMenuItem(value: 'PAYMENT', child: Text('Payment Request')),
                            DropdownMenuItem(value: 'DELIVERY', child: Text('Delivery Updates')),
                            DropdownMenuItem(value: 'ERROR', child: Text('Error / Fallback')),
                            DropdownMenuItem(value: 'GENERAL', child: Text('General Broadcast')),
                          ],
                          onChanged: isSubmitting ? null : (val) { if (val != null) category = val; },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: language,
                          decoration: InputDecoration(
                            labelText: "Language",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: isSubmitting ? [
                            DropdownMenuItem(value: language, child: Text(language)),
                          ] : const [
                            DropdownMenuItem(value: 'en', child: Text('English (en)')),
                            DropdownMenuItem(value: 'hi', child: Text('Hindi (hi)')),
                            DropdownMenuItem(value: 'mr', child: Text('Marathi (mr)')),
                          ],
                          onChanged: isSubmitting ? null : (val) { if (val != null) language = val; },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descController,
                          enabled: !isSubmitting,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: "Description",
                            hintText: "What is this message used for?",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: isSubmitting ? null : () async {
                      if (formKey.currentState?.validate() == true) {
                        setDialogState(() {
                          isSubmitting = true;
                        });
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final t = await WhatsAppService.createTemplate(
                            code: codeController.text,
                            category: category,
                            language: language,
                            description: descController.text,
                          );
                          if (!mounted) return;
                          navigator.pop();
                          setState(() {
                            _selectedTemplate = t;
                          });
                          await _loadTemplateVersions(t['id'] as String);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Template created successfully!')),
                          );
                        } catch (e, stackTrace) {
                          debugPrint('Error creating template: $e');
                          debugPrint('Stack trace: $stackTrace');
                          setDialogState(() {
                            isSubmitting = false;
                          });
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Error creating template')),
                          );
                        }
                      }
                    },
                    child: const Text("Create"),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      codeController.dispose();
      descController.dispose();
    });
  }

  // ignore: unused_element
  void _showCreateVersionDialog() {
    if (_selectedTemplate == null) return;

    final formKey = GlobalKey<FormState>();
    final bodyController = TextEditingController();
    final headerController = TextEditingController();
    final footerController = TextEditingController();
    final mediaUrlController = TextEditingController();
    final ctaTitleController = TextEditingController();
    final ctaUrlController = TextEditingController();
    final listBtnController = TextEditingController();
    final listTitleController = TextEditingController();

    String mediaType = 'NONE';
    String interactiveType = 'NONE';
    
    // Manage dynamic items inside dialog state
    List<Map<String, dynamic>> dynamicButtons = [];
    List<Map<String, dynamic>> dynamicSections = []; // ignore: unused_element

    final nextVerNum = _selectedTemplateVersions.isEmpty
        ? 1
        : _selectedTemplateVersions.map((v) => v['versionNumber'] as int).reduce((a, b) => a > b ? a : b) + 1;

    showDialog<void>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                "Create Draft Version $nextVerNum",
                style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: bodyController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: "Message Body (Required)",
                            hintText: "Use *bold* or _italics_ formatting rules.",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? "Body text is required" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: headerController,
                          decoration: InputDecoration(
                            labelText: "Header Text (Optional)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: footerController,
                          decoration: InputDecoration(
                            labelText: "Footer Text (Optional)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: mediaType,
                          decoration: InputDecoration(
                            labelText: "Media Attachment Type",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'NONE', child: Text('No Media')),
                            DropdownMenuItem(value: 'IMAGE', child: Text('Image (Media URL)')),
                            DropdownMenuItem(value: 'VIDEO', child: Text('Video (Media URL)')),
                            DropdownMenuItem(value: 'DOCUMENT', child: Text('Document File (Media URL)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => mediaType = val);
                          },
                        ),
                        if (mediaType != 'NONE') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: mediaUrlController,
                            decoration: InputDecoration(
                              labelText: "Media URL",
                              hintText: "https://example.com/image.png",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: interactiveType,
                          decoration: InputDecoration(
                            labelText: "Interactive Action Controls",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'NONE', child: Text('Plain Text Notification')),
                            DropdownMenuItem(value: 'BUTTONS', child: Text('Quick Reply Action Buttons')),
                            DropdownMenuItem(value: 'CTA_URL', child: Text('Call to Action Link (CTA)')),
                            DropdownMenuItem(value: 'LIST', child: Text('Interactive Option List Menu')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => interactiveType = val);
                          },
                        ),
                        // Conditional UI based on action controls
                        if (interactiveType == 'CTA_URL') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: ctaTitleController,
                            decoration: InputDecoration(
                              labelText: "Link Button Title",
                              hintText: "e.g., Pay Now, Track Order",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: ctaUrlController,
                            decoration: InputDecoration(
                              labelText: "Redirect URL",
                              hintText: "https://example.com/pay",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                        if (interactiveType == 'BUTTONS') ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Quick Reply Buttons (${dynamicButtons.length}/3)",
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                              ),
                              if (dynamicButtons.length < 3)
                                TextButton.icon(
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text("Add Button"),
                                  onPressed: () {
                                    setDialogState(() {
                                      dynamicButtons.add({'title': 'Button ${dynamicButtons.length + 1}'});
                                    });
                                  },
                                ),
                            ],
                          ),
                          ...dynamicButtons.asMap().entries.map((entry) {
                            final idx = entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: entry.value['title'] as String?,
                                      decoration: InputDecoration(
                                        labelText: "Button ${idx + 1} Text",
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onChanged: (val) => dynamicButtons[idx]['title'] = val,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () {
                                      setDialogState(() => dynamicButtons.removeAt(idx));
                                    },
                                  )
                                ],
                              ),
                            );
                          }),
                        ],
                        if (interactiveType == 'LIST') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: listBtnController,
                            decoration: InputDecoration(
                              labelText: "Menu Selector Button Text",
                              hintText: "e.g., View Menu, Choose Size",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: listTitleController,
                            decoration: InputDecoration(
                              labelText: "List Main Header Title",
                              hintText: "e.g., Categories, Cakes",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Menu Sections (${dynamicSections.length})",
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add_box, size: 16),
                                label: const Text("Add Section"),
                                onPressed: () {
                                  setDialogState(() {
                                    dynamicSections.add({
                                      'title': 'Section ${dynamicSections.length + 1}',
                                      'dataSource': 'STATIC',
                                      'rows': [
                                        {'title': 'Option 1', 'description': 'Description here'}
                                      ]
                                    });
                                  });
                                },
                              ),
                            ],
                          ),
                          ...dynamicSections.asMap().entries.map((sEntry) {
                            final sIdx = sEntry.key;
                            final section = sEntry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: cs.surfaceContainerHigh,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: section['title'] as String?,
                                            decoration: const InputDecoration(labelText: "Section Title", isDense: true),
                                            onChanged: (val) => dynamicSections[sIdx]['title'] = val,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                          onPressed: () {
                                            setDialogState(() => dynamicSections.removeAt(sIdx));
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: section['dataSource'] as String?,
                                      decoration: const InputDecoration(labelText: "Data Source Mode", isDense: true),
                                      items: const [
                                        DropdownMenuItem(value: 'STATIC', child: Text('Static Text Rows')),
                                        DropdownMenuItem(value: 'CATEGORIES', child: Text('Dynamic: Bakery Categories')),
                                        DropdownMenuItem(value: 'TOP_FAVORITES', child: Text('Dynamic: Best Sellers')),
                                        DropdownMenuItem(value: 'PRODUCT_LIST', child: Text('Dynamic: Full Menu Catalog')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() => dynamicSections[sIdx]['dataSource'] = val);
                                        }
                                      },
                                    ),
                                    if (section['dataSource'] == 'STATIC') ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Static Items:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          TextButton(
                                            onPressed: () {
                                              setDialogState(() {
                                                (dynamicSections[sIdx]['rows'] as List<Map<String, dynamic>>).add({
                                                  'title': 'New Option',
                                                  'description': ''
                                                });
                                              });
                                            },
                                            child: const Text("Add Row", style: TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                      ...(section['rows'] as List<Map<String, dynamic>>).asMap().entries.map((rEntry) {
                                        final rIdx = rEntry.key;
                                        final row = rEntry.value;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  initialValue: row['title'] as String?,
                                                  decoration: const InputDecoration(labelText: "Title", isDense: true),
                                                  onChanged: (val) => (dynamicSections[sIdx]['rows'] as List<Map<String, dynamic>>)[rIdx]['title'] = val,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextFormField(
                                                  initialValue: row['description'] as String?,
                                                  decoration: const InputDecoration(labelText: "Description", isDense: true),
                                                  onChanged: (val) => (dynamicSections[sIdx]['rows'] as List<Map<String, dynamic>>)[rIdx]['description'] = val,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.remove, size: 16),
                                                onPressed: () {
                                                  setDialogState(() {
                                                    (dynamicSections[sIdx]['rows'] as List).removeAt(rIdx);
                                                  });
                                                },
                                              )
                                            ],
                                          ),
                                        );
                                      }),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    if (formKey.currentState?.validate() == true) {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await WhatsAppService.createTemplateVersion(
                          templateId: _selectedTemplate!['id'] as String,
                          versionNumber: nextVerNum,
                          bodyText: bodyController.text,
                          headerText: headerController.text.isNotEmpty ? headerController.text : null,
                          footerText: footerController.text.isNotEmpty ? footerController.text : null,
                          mediaUrl: mediaUrlController.text.isNotEmpty ? mediaUrlController.text : null,
                          mediaType: mediaType,
                          interactiveType: interactiveType,
                          ctaButtonTitle: ctaTitleController.text.isNotEmpty ? ctaTitleController.text : null,
                          ctaButtonUrl: ctaUrlController.text.isNotEmpty ? ctaUrlController.text : null,
                          listButtonTitle: listBtnController.text.isNotEmpty ? listBtnController.text : null,
                          listTitle: listTitleController.text.isNotEmpty ? listTitleController.text : null,
                          buttons: dynamicButtons,
                          listSections: dynamicSections,
                        );

                        if (!mounted) return;
                        navigator.pop();
                        await _loadTemplateVersions(_selectedTemplate!['id'] as String);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('New version created successfully!')),
                        );
                      } catch (e, stackTrace) {
                        debugPrint('Error creating template version: $e');
                        debugPrint('Stack trace: $stackTrace');
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Error creating template version')),
                        );
                      }
                    }
                  },
                  child: const Text("Publish Draft"),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      bodyController.dispose();
      headerController.dispose();
      footerController.dispose();
      mediaUrlController.dispose();
      ctaTitleController.dispose();
      ctaUrlController.dispose();
      listBtnController.dispose();
      listTitleController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 750;
    final isTablet = MediaQuery.of(context).size.width >= 750 && MediaQuery.of(context).size.width < 1100;

    final sidebarWidget = Container(
      color: cs.surface,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: WhatsAppService.getTemplatesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint("❌ Templates load error: ${snapshot.error}");
            return const Center(child: Text("Failed to load data"));
          }
          final templates = snapshot.data ?? [];
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: cs.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    "No templates configured yet.",
                    style: TextStyle(color: cs.secondary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              final isSelected = _selectedTemplate?['id'] == t['id'];
              return Card(
                elevation: isSelected ? 2 : 0,
                color: isSelected ? cs.primaryContainer : cs.surfaceContainerLow,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    setState(() {
                      _selectedTemplate = t;
                    });
                    await _loadTemplateVersions(t['id'] as String);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                (t['code'] as String?) ?? '',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.65,
                              child: Switch(
                                value: (t['isActive'] as bool?) ?? true,
                                activeThumbColor: cs.primary,
                                onChanged: (value) async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  try {
                                    await WhatsAppService.updateTemplateStatus(t['id'] as String, value);
                                  } catch (e, stackTrace) {
                                    debugPrint('Error updating template status: $e\n$stackTrace');
                                    if (mounted) {
                                      setState(() {});
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Failed to update status: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (t['description'] != null && t['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            t['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                                  : cs.secondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isSelected ? cs.onPrimaryContainer : cs.primary).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (t['category'] as String?) ?? 'GENERAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? cs.onPrimaryContainer : cs.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isSelected ? cs.onPrimaryContainer : cs.secondary).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (t['language'] ?? 'en').toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? cs.onPrimaryContainer : cs.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    Widget bodyWidget;

    if (isMobile) {
      if (_selectedTemplate == null) {
        bodyWidget = sidebarWidget;
      } else {
        bodyWidget = _buildDetailsInspector(cs, showMockupSideBySide: false, isMobile: isMobile);
      }
    } else if (isTablet) {
      bodyWidget = Row(
        children: [
          Expanded(
            flex: 4,
            child: sidebarWidget,
          ),
          Container(width: 1, color: cs.secondary.withValues(alpha: 0.08)),
          Expanded(
            flex: 6,
            child: _selectedTemplate == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_customize_outlined, size: 72, color: cs.primary.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text(
                          "Select a Template to Edit Layout Details",
                          style: GoogleFonts.plusJakartaSans(
                            color: cs.secondary.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  )
                : _buildDetailsInspector(cs, showMockupSideBySide: false, isMobile: isMobile),
          ),
        ],
      );
    } else {
      // Desktop
      bodyWidget = Row(
        children: [
          Expanded(
            flex: 3,
            child: sidebarWidget,
          ),
          Container(width: 1, color: cs.secondary.withValues(alpha: 0.08)),
          Expanded(
            flex: 7,
            child: _selectedTemplate == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_customize_outlined, size: 72, color: cs.primary.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text(
                          "Select a Template to Edit Layout Details",
                          style: GoogleFonts.plusJakartaSans(
                            color: cs.secondary.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  )
                : _buildDetailsInspector(cs, showMockupSideBySide: true, isMobile: isMobile),
          ),
        ],
      );
    }

    final headerWidget = Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "WhatsApp Notification Engine",
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: isMobile ? 18 : 22,
                        color: cs.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage transactional template layouts and dynamic bot responses",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 10 : 12,
                        color: cs.secondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedTemplate == null) // Show New Template button only when templates list is showing
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      isMobile ? "New" : "New Template",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _showCreateTemplateDialog,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: cs.secondary.withValues(alpha: 0.08),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          headerWidget,
          Expanded(child: bodyWidget),
        ],
      ),
    );
  }

  void _insertVariable(String variable) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    // Fallback if no selection/cursor active
    if (selection.start < 0 || selection.end < 0) {
      _bodyController.text = text + variable;
      _bodyController.selection = TextSelection.collapsed(offset: _bodyController.text.length);
      return;
    }
    final newText = text.replaceRange(selection.start, selection.end, variable);
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + variable.length),
    );
  }

  Future<void> _saveAndApplyLive() async {
    if (_selectedTemplate == null || _selectedVersionDetails == null) return;
    setState(() => _isSavingLive = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final nextVerNum = _selectedTemplateVersions.isEmpty
          ? 1
          : _selectedTemplateVersions.map((v) => v['versionNumber'] as int).reduce((a, b) => a > b ? a : b) + 1;

      // Extract buttons and list sections with type safety
      final buttons = (_selectedVersionDetails!['buttons'] as List<dynamic>?)
          ?.map((b) => Map<String, dynamic>.from(b as Map))
          .toList();
      final listSections = (_selectedVersionDetails!['listSections'] as List<dynamic>?)
          ?.map((s) {
            final section = Map<String, dynamic>.from(s as Map);
            final rows = (section['rows'] as List<dynamic>?)
                ?.map((r) => Map<String, dynamic>.from(r as Map))
                .toList();
            section['rows'] = rows;
            return section;
          })
          .toList();

      // Create new draft version with updated fields in database
      final newVer = await WhatsAppService.createTemplateVersion(
        templateId: _selectedTemplate!['id'] as String,
        versionNumber: nextVerNum,
        bodyText: _bodyController.text,
        headerText: _headerController.text.isNotEmpty ? _headerController.text : null,
        footerText: _footerController.text.isNotEmpty ? _footerController.text : null,
        mediaUrl: _selectedVersionDetails!['mediaUrl'] as String?,
        mediaType: _selectedVersionDetails!['mediaType'] as String? ?? 'NONE',
        interactiveType: _selectedVersionDetails!['interactiveType'] as String? ?? 'NONE',
        ctaButtonTitle: _selectedVersionDetails!['ctaButtonTitle'] as String?,
        ctaButtonUrl: _selectedVersionDetails!['ctaButtonUrl'] as String?,
        listButtonTitle: _selectedVersionDetails!['listButtonTitle'] as String?,
        listTitle: _selectedVersionDetails!['listTitle'] as String?,
        buttons: buttons,
        listSections: listSections,
      );

      // Deploy it as active immediately
      await WhatsAppService.setActiveVersion(
        _selectedTemplate!['id'] as String,
        newVer['id'] as String,
      );

      // Update in-memory selected template reference
      setState(() {
        _selectedTemplate!['activeVersionId'] = newVer['id'];
      });

      // Reload versions and select new active version
      await _loadTemplateVersions(_selectedTemplate!['id'] as String);
      
      messenger.showSnackBar(
        const SnackBar(content: Text('Changes saved and deployed live successfully!')),
      );
    } catch (e, stackTrace) {
      debugPrint('Error saving and applying live: $e\n$stackTrace');
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save and apply: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingLive = false);
      }
    }
  }

  Widget _buildDetailsInspector(ColorScheme cs, {required bool showMockupSideBySide, required bool isMobile}) {
    if (_isLoadingVersions) {
      return const Center(child: CircularProgressIndicator());
    }

    final editorPanel = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (isMobile) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedTemplate = null;
                  _selectedTemplateVersions = [];
                });
              },
              icon: Icon(Icons.arrow_back_ios_new, size: 14, color: cs.primary),
              label: Text(
                "Back to Templates",
                style: GoogleFonts.plusJakartaSans(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_selectedTemplate!['code'] as String?) ?? '',
                    style: GoogleFonts.notoSerif(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: cs.secondary.withValues(alpha: 0.6)),
              onSelected: (val) async {
                if (val == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Template"),
                      content: Text("Are you sure you want to delete ${(_selectedTemplate!['code'] as String?) ?? ''} and all its historical draft configurations?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        )
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (!mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await WhatsAppService.deleteTemplate(_selectedTemplate!['id'] as String);
                      if (!mounted) return;
                      setState(() {
                        _selectedTemplate = null;
                        _selectedTemplateVersions = [];
                      });
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Template deleted successfully!')),
                      );
                    } catch (e, stackTrace) {
                      debugPrint('Error deleting template: $e\n$stackTrace');
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to delete template: $e')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'delete', child: Text("Delete Template", style: TextStyle(color: Colors.red))),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        
        
        if (_selectedVersionDetails != null) ...[
          // Direct WYSIWYG Editor Panel
          Card(
            color: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Edit Template Content",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Changes will update the live WhatsApp assistant instantly on save.",
                    style: TextStyle(color: cs.secondary.withValues(alpha: 0.6), fontSize: 12),
                  ),
                  const Divider(height: 32),
                  
                  // Header input (optional)
                  Text(
                    "Header Text (Optional)",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _headerController,
                    decoration: InputDecoration(
                      hintText: "Enter header title...",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Body Copy input (Required)
                  Text(
                    "Message Body (Required)",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bodyController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: "Type message content here. Use *bold* or _italics_.",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Variables Toolbar (Quick Tap Badges)
                  Text(
                    "Tap to Insert Variables:",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text("Customer Name"),
                        onPressed: () => _insertVariable("{{customer_name}}"),
                        backgroundColor: cs.primary.withValues(alpha: 0.05),
                        labelStyle: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      ActionChip(
                        label: const Text("Order Number"),
                        onPressed: () => _insertVariable("{{order_number}}"),
                        backgroundColor: cs.primary.withValues(alpha: 0.05),
                        labelStyle: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      ActionChip(
                        label: const Text("Total Price"),
                        onPressed: () => _insertVariable("{{total_price}}"),
                        backgroundColor: cs.primary.withValues(alpha: 0.05),
                        labelStyle: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      ActionChip(
                        label: const Text("Delivery Date"),
                        onPressed: () => _insertVariable("{{delivery_date}}"),
                        backgroundColor: cs.primary.withValues(alpha: 0.05),
                        labelStyle: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      ActionChip(
                        label: const Text("Payment Link"),
                        onPressed: () => _insertVariable("{{payment_link}}"),
                        backgroundColor: cs.primary.withValues(alpha: 0.05),
                        labelStyle: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Footer input (optional)
                  Text(
                    "Footer Note (Optional)",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _footerController,
                    decoration: InputDecoration(
                      hintText: "Enter disclaimer or bot footnote...",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    "Action Interface Type",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _interactiveType,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NONE', child: Text('Plain Text Notification')),
                      DropdownMenuItem(value: 'BUTTONS', child: Text('Quick Reply Action Buttons')),
                      DropdownMenuItem(value: 'CTA_URL', child: Text('Call to Action Link (CTA)')),
                      DropdownMenuItem(value: 'LIST', child: Text('Interactive Option List Menu')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _interactiveType = val;
                          _selectedVersionDetails!['interactiveType'] = val;
                        });
                      }
                    },
                  ),
                  if (_interactiveType == 'CTA_URL') ...[
                    const SizedBox(height: 16),
                    Text(
                      "Redirect Link Title",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.secondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _ctaButtonTitleController,
                      decoration: InputDecoration(
                        hintText: "e.g., Pay Now",
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "URL Address",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.secondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _ctaButtonUrlController,
                      decoration: InputDecoration(
                        hintText: "https://...",
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    "Attachment Type",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.secondary.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _mediaType,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NONE', child: Text('No Attachment')),
                      DropdownMenuItem(value: 'IMAGE', child: Text('Image')),
                      DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
                      DropdownMenuItem(value: 'DOCUMENT', child: Text('Document (PDF)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _mediaType = val;
                          _selectedVersionDetails!['mediaType'] = val;
                        });
                      }
                    },
                  ),
                  if (_mediaType != 'NONE') ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Attachment Source",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cs.secondary.withValues(alpha: 0.7),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: _isUploadingMedia
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_upload, size: 14),
                          label: Text(
                            _isUploadingMedia ? "Uploading..." : "Choose File",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isUploadingMedia ? null : _uploadMediaFile,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _mediaUrlController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "https://... (or upload file above)",
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // Action button to Save and Apply
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: _isSavingLive 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Icon(Icons.flash_on, size: 16),
                      label: Text(
                        _isSavingLive ? "SAVING & GOING LIVE..." : "SAVE & APPLY LIVE",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSavingLive ? null : _saveAndApplyLive,
                    ),
                  ),
                ],
              ),
            ),
          )
        ]
      ],
    );

    final mockupPanel = Container(
      color: cs.surfaceContainerHigh.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: _buildPhoneMockup(cs),
      ),
    );

    if (showMockupSideBySide) {
      return Row(
        children: [
          Expanded(flex: 4, child: editorPanel),
          Expanded(flex: 3, child: mockupPanel),
        ],
      );
    } else {
      // Premium custom tabs when mockup cannot fit side-by-side
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeInspectorTab = 0),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _activeInspectorTab == 0 ? cs.primary : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_note, size: 18, color: _activeInspectorTab == 0 ? cs.onPrimary : cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              "Config Layout",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _activeInspectorTab == 0 ? cs.onPrimary : cs.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeInspectorTab = 1),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _activeInspectorTab == 1 ? cs.primary : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_android, size: 18, color: _activeInspectorTab == 1 ? cs.onPrimary : cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              "Live Preview",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _activeInspectorTab == 1 ? cs.onPrimary : cs.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _activeInspectorTab == 0 ? editorPanel : mockupPanel,
          ),
        ],
      );
    }
  }



  // ─────────────────────────────────────────────────────────────────────────────
  // ─── Live WhatsApp Mockup Simulator
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildPhoneMockup(ColorScheme cs) {
    if (_selectedVersionDetails == null) {
      return Container();
    }

    final String body = (_selectedVersionDetails!['bodyText'] as String?) ?? '';
    final String? header = _selectedVersionDetails!['headerText'] as String?;
    final String? footer = _selectedVersionDetails!['footerText'] as String?;
    final String? mediaUrl = _selectedVersionDetails!['mediaUrl'] as String?;
    final String mediaType = (_selectedVersionDetails!['mediaType'] as String?) ?? 'NONE';
    final String isInteractive = (_selectedVersionDetails!['interactiveType'] as String?) ?? 'NONE';

    return Container(
      width: 320,
      height: 520,
      decoration: BoxDecoration(
        color: const Color(0xFFE5DDD5), // Standard WhatsApp chat background green-beige tint
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.black, width: 8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 15))],
      ),
      child: Column(
        children: [
          // Phone top bar
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF075E54), // WhatsApp classic green top bar
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.white24),
                const SizedBox(width: 8),
                Text(
                  "Sonna Bakery Bot",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_vert, color: Colors.white, size: 16),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // WhatsApp Chat Bubble
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Media Attachment
                                  if (mediaType != 'NONE' && mediaUrl != null && mediaUrl.isNotEmpty)
                                    Container(
                                      height: 120,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: mediaType == 'IMAGE'
                                          ? Image.network(
                                              mediaUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, st) => const Center(
                                                child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                                              ),
                                            )
                                          : Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(mediaType == 'VIDEO' ? Icons.play_circle_outline : Icons.insert_drive_file_outlined, size: 36, color: Colors.grey),
                                                  const SizedBox(height: 4),
                                                  Text(mediaType, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                    ),
                                  
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Bold Header text
                                        if (header != null && header.isNotEmpty) ...[
                                          Text(
                                            header,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        
                                        // Body text
                                        Text(
                                          body,
                                          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                                        ),
                                        
                                        // Footer text
                                        if (footer != null && footer.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            footer,
                                            style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Quick Reply Interactive Buttons Mockup
                          if (isInteractive == 'BUTTONS' && _selectedVersionDetails!['buttons'] != null)
                            ...(_selectedVersionDetails!['buttons'] as List).map((btn) {
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 6),
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                                ),
                                child: Center(
                                  child: Text(
                                    (btn['title'] as String?) ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFF00A884), // WhatsApp primary brand green
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          
                          // CTA button link Mockup
                          if (isInteractive == 'CTA_URL')
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 6),
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.open_in_new, size: 14, color: Color(0xFF00A884)),
                                  const SizedBox(width: 6),
                                  Text(
                                    (_selectedVersionDetails!['ctaButtonTitle'] as String?) ?? 'Open Link',
                                    style: const TextStyle(
                                      color: Color(0xFF00A884),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // List Menu Mockup
                          if (isInteractive == 'LIST')
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 6),
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.list_alt_rounded, size: 14, color: Color(0xFF00A884)),
                                  const SizedBox(width: 6),
                                  Text(
                                    (_selectedVersionDetails!['listButtonTitle'] as String?) ?? 'View Options',
                                    style: const TextStyle(
                                      color: Color(0xFF00A884),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }
}
