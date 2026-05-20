import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
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
      final versions = await WhatsAppService.fetchTemplateVersions(templateId);
      
      // Stale response guard
      if (currentTemplateId != _selectedTemplate?['id']?.toString()) {
        return;
      }

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
        const SnackBar(content: Text('Error loading template versions')),
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
    List<Map<String, dynamic>> dynamicSections = [];

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
        bodyWidget = _buildDetailsInspector(cs, showMockupSideBySide: false);
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
                : _buildDetailsInspector(cs, showMockupSideBySide: false),
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
                : _buildDetailsInspector(cs, showMockupSideBySide: true),
          ),
        ],
      );
    }

    final showBackButtonOnMobileDetails = isMobile && _selectedTemplate != null;

    final headerWidget = Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: cs.primary, size: 18),
                  onPressed: showBackButtonOnMobileDetails
                      ? () {
                          setState(() {
                            _selectedTemplate = null;
                            _selectedTemplateVersions = [];
                          });
                        }
                      : widget.onClose,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "WhatsApp Notification Engine",
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: 22,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Manage transactional template layouts and dynamic bot responses",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: cs.secondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile || _selectedTemplate == null)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      "New Template",
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
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

  Widget _buildDetailsInspector(ColorScheme cs, {required bool showMockupSideBySide}) {
    if (_isLoadingVersions) {
      return const Center(child: CircularProgressIndicator());
    }

    final editorPanel = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    "Draft Versions: ${_selectedTemplateVersions.length}",
                    style: TextStyle(color: cs.secondary.withValues(alpha: 0.6), fontSize: 13),
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
        const SizedBox(height: 24),
        
        // Versions section
        Card(
          color: cs.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text("Historical Drafts", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("New Draft Version"),
                        onPressed: _showCreateVersionDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectedTemplateVersions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        "No version drafts. Please add a version layout.",
                        style: TextStyle(color: cs.secondary.withValues(alpha: 0.5), fontSize: 13),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTemplateVersions.map((v) {
                      final isSel = _selectedVersionDetails?['id'] == v['id'];
                      final isActive = _selectedTemplate?['activeVersionId'] == v['id'];

                      return ChoiceChip(
                        label: Text("v${v['versionNumber']}"),
                        selected: isSel,
                        avatar: isActive ? const Icon(Icons.check_circle, size: 12, color: Colors.green) : null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedVersionDetails = v);
                          }
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        if (_selectedVersionDetails != null) ...[
          // Version details panel
          Card(
            color: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          "Draft Layout Config (v${_selectedVersionDetails!['versionNumber']})",
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        ),
                        if (_selectedTemplate?['activeVersionId'] != _selectedVersionDetails!['id'])
                          OutlinedButton.icon(
                            icon: const Icon(Icons.publish, size: 14),
                            label: const Text("Deploy Active", style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await WhatsAppService.setActiveVersion(
                                  _selectedTemplate!['id'] as String,
                                  _selectedVersionDetails!['id'] as String,
                                );
                                if (!mounted) return;
                                setState(() {
                                  _selectedTemplate!['activeVersionId'] = _selectedVersionDetails!['id'];
                                });
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Version deployed as live notification engine!')),
                                );
                              } catch (e, stackTrace) {
                                debugPrint('Error activating template version: $e\n$stackTrace');
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Failed to deploy version: $e')),
                                );
                              }
                            },
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, size: 12, color: Colors.green),
                                SizedBox(width: 4),
                                Text("Deployed Live", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  _buildMetaField("Body Copy", (_selectedVersionDetails!['bodyText'] as String?) ?? '---', isLongText: true),
                  _buildMetaField("Header Title", (_selectedVersionDetails!['headerText'] as String?) ?? '---'),
                  _buildMetaField("Footer Note", (_selectedVersionDetails!['footerText'] as String?) ?? '---'),
                  _buildMetaField("Action Interface Type", (_selectedVersionDetails!['interactiveType'] as String?) ?? 'NONE'),
                  if (_selectedVersionDetails!['interactiveType'] == 'CTA_URL') ...[
                    _buildMetaField("Redirect Link Title", (_selectedVersionDetails!['ctaButtonTitle'] as String?) ?? '---'),
                    _buildMetaField("URL Address", (_selectedVersionDetails!['ctaButtonUrl'] as String?) ?? '---'),
                  ],
                  if (_selectedVersionDetails!['mediaType'] != 'NONE') ...[
                    _buildMetaField("Attachment Type", (_selectedVersionDetails!['mediaType'] as String?) ?? '---'),
                    _buildMetaField("Attachment Source Link", (_selectedVersionDetails!['mediaUrl'] as String?) ?? '---'),
                  ]
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

  Widget _buildMetaField(String label, String val, {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            val,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: isLongText ? FontWeight.w500 : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
