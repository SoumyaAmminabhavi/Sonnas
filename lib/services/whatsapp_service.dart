import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class WhatsAppService {
  static SupabaseClient get _client => SupabaseService.client;

  // ─────────────────────────────────────────────────────────────────────────────
  // ─── WhatsAppTemplate Operations
  // ─────────────────────────────────────────────────────────────────────────────

  /// Real-time stream for all templates
  static Stream<List<Map<String, dynamic>>> getTemplatesStream() {
    return _client
        .from('WhatsAppTemplate')
        .stream(primaryKey: ['id'])
        .order('code');
  }

  /// One-time fetch for all templates, joining the active version details
  static Future<List<Map<String, dynamic>>> fetchTemplates() async {
    final res = await _client
        .from('WhatsAppTemplate')
        .select('*, activeVersion:WhatsAppTemplateVersion(*)')
        .order('code');
    return List<Map<String, dynamic>>.from(res);
  }

  /// Create a new WhatsApp template
  static Future<Map<String, dynamic>> createTemplate({
    required String code,
    required String category,
    String language = 'en',
    String? description,
  }) async {
    final res = await _client.from('WhatsAppTemplate').insert({
      'code': code.toUpperCase().trim(),
      'category': category.toUpperCase().trim(),
      'language': language,
      'description': description,
      'isActive': true,
    }).select().single();
    return Map<String, dynamic>.from(res);
  }

  /// Toggle template active/inactive state
  static Future<void> updateTemplateStatus(String templateId, bool isActive) async {
    await _client.from('WhatsAppTemplate').update({
      'isActive': isActive,
    }).eq('id', templateId);
  }

  /// Delete a template and cascade delete its versions
  static Future<void> deleteTemplate(String templateId) async {
    await _client.from('WhatsAppTemplate').delete().eq('id', templateId);
  }

  /// Set the active version for a template
  static Future<void> setActiveVersion(String templateId, String versionId) async {
    await _client.from('WhatsAppTemplate').update({
      'activeVersionId': versionId,
    }).eq('id', templateId);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ─── WhatsAppTemplateVersion Operations
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch all versions for a specific template, sorting by version number descending
  static Future<List<Map<String, dynamic>>> fetchTemplateVersions(String templateId) async {
    final res = await _client
        .from('WhatsAppTemplateVersion')
        .select('*, buttons:WhatsAppButton(*), listSections:WhatsAppListSection(*, rows:WhatsAppListRow(*))')
        .eq('templateId', templateId)
        .order('versionNumber', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Fetch a single specific version with all its buttons and list sections
  static Future<Map<String, dynamic>?> fetchVersionDetails(String versionId) async {
    final res = await _client
        .from('WhatsAppTemplateVersion')
        .select('*, buttons:WhatsAppButton(*), listSections:WhatsAppListSection(*, rows:WhatsAppListRow(*))')
        .eq('id', versionId)
        .maybeSingle();
    return res != null ? Map<String, dynamic>.from(res) : null;
  }

  /// Create a new template version with full interactive component bindings
  static Future<Map<String, dynamic>> createTemplateVersion({
    required String templateId,
    required int versionNumber,
    required String bodyText,
    String? headerText,
    String? footerText,
    String? mediaUrl,
    String mediaType = 'NONE',
    String interactiveType = 'NONE',
    String? ctaButtonTitle,
    String? ctaButtonUrl,
    String? listButtonTitle,
    String? listTitle,
    String? changeLog,
    String? createdBy,
    List<Map<String, dynamic>>? buttons,
    List<Map<String, dynamic>>? listSections,
  }) async {
    String? versionId;
    try {
      // 1. Insert Core Template Version record
      final versionRecord = await _client.from('WhatsAppTemplateVersion').insert({
        'templateId': templateId,
        'versionNumber': versionNumber,
        'bodyText': bodyText,
        'headerText': headerText,
        'footerText': footerText,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType.toUpperCase(),
        'interactiveType': interactiveType.toUpperCase(),
        'ctaButtonTitle': ctaButtonTitle,
        'ctaButtonUrl': ctaButtonUrl,
        'listButtonTitle': listButtonTitle,
        'listTitle': listTitle,
        'changeLog': changeLog,
        'createdBy': createdBy,
      }).select().single();

      versionId = versionRecord['id'].toString();

      // 2. Insert associated buttons if any
      if (interactiveType.toUpperCase() == 'BUTTONS' && buttons != null && buttons.isNotEmpty) {
        final buttonsPayload = buttons.asMap().entries.map((entry) {
          final index = entry.key;
          final btn = entry.value;
          return {
            'versionId': versionId,
            'sortOrder': index,
            'buttonId': btn['buttonId'] ?? 'btn_${index + 1}',
            'title': btn['title'] ?? '',
          };
        }).toList();
        await _client.from('WhatsAppButton').insert(buttonsPayload);
      }

      // 3. Insert associated list sections & list rows if any
      if (interactiveType.toUpperCase() == 'LIST' && listSections != null && listSections.isNotEmpty) {
        for (int sIndex = 0; sIndex < listSections.length; sIndex++) {
          final section = listSections[sIndex];
          final sectionRecord = await _client.from('WhatsAppListSection').insert({
            'versionId': versionId,
            'sortOrder': sIndex,
            'title': section['title'] ?? 'Section ${sIndex + 1}',
            'dataSource': section['dataSource'] ?? 'STATIC',
          }).select().single();

          final String sectionId = sectionRecord['id'].toString();
          final List? rows = section['rows'];

          if (rows != null && rows.isNotEmpty) {
            final rowsPayload = rows.asMap().entries.map((rEntry) {
              final rIndex = rEntry.key;
              final row = rEntry.value;
              return {
                'sectionId': sectionId,
                'sortOrder': rIndex,
                'rowId': row['rowId'] ?? 'row_${sIndex + 1}_${rIndex + 1}',
                'title': row['title'] ?? '',
                'description': row['description'],
              };
            }).toList();
            await _client.from('WhatsAppListRow').insert(rowsPayload);
          }
        }
      }

      // Return the full version record with relations refreshed
      final fullDetails = await fetchVersionDetails(versionId);
      return fullDetails ?? Map<String, dynamic>.from(versionRecord);
    } catch (e) {
      if (versionId != null) {
        await _client.from('WhatsAppTemplateVersion').delete().eq('id', versionId);
      }
      rethrow;
    }
  }
}
