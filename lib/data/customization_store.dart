import 'package:shared_preferences/shared_preferences.dart';

import '../app/models.dart';

class CustomizationStore {
  Future<CustomizationSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return CustomizationSettings(
      receiveAsmeB16Parts: preferences.getBool(_receiveAsmeB16PartsKey) ?? true,
      preferredB16Standards:
          preferences.getStringList(_preferredB16StandardsKey) ??
          List<String>.from(kDefaultPreferredB16Standards),
      surfaceFinishRequired:
          preferences.getBool(_surfaceFinishRequiredKey) ?? false,
      surfaceFinishUnit: preferences.getString(_surfaceFinishUnitKey) ?? 'u-in',
      defaultQcInspectorName:
          preferences.getString(_defaultQcInspectorNameKey) ?? '',
      defaultQcManagerName:
          preferences.getString(_defaultQcManagerNameKey) ?? '',
      hasSavedInspectorSignature:
          preferences.getBool(_hasSavedInspectorSignatureKey) ?? false,
      savedInspectorSignaturePath:
          preferences.getString(_savedInspectorSignaturePathKey) ?? '',
      includeCompanyLogoOnReports:
          preferences.getBool(_includeCompanyLogoOnReportsKey) ?? false,
      companyLogoPath: preferences.getString(_companyLogoPathKey) ?? '',
    );
  }

  Future<void> save(CustomizationSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      _receiveAsmeB16PartsKey,
      settings.receiveAsmeB16Parts,
    );
    await preferences.setStringList(
      _preferredB16StandardsKey,
      settings.preferredB16Standards,
    );
    await preferences.setBool(
      _surfaceFinishRequiredKey,
      settings.surfaceFinishRequired,
    );
    await preferences.setString(
      _surfaceFinishUnitKey,
      settings.surfaceFinishUnit,
    );
    await preferences.setString(
      _defaultQcInspectorNameKey,
      settings.defaultQcInspectorName,
    );
    await preferences.setString(
      _defaultQcManagerNameKey,
      settings.defaultQcManagerName,
    );
    await preferences.setBool(
      _hasSavedInspectorSignatureKey,
      settings.hasSavedInspectorSignature,
    );
    await preferences.setString(
      _savedInspectorSignaturePathKey,
      settings.savedInspectorSignaturePath,
    );
    await preferences.setBool(
      _includeCompanyLogoOnReportsKey,
      settings.includeCompanyLogoOnReports,
    );
    await preferences.setString(_companyLogoPathKey, settings.companyLogoPath);
  }
}

const _receiveAsmeB16PartsKey = 'receive_asme_b16_parts';
const _preferredB16StandardsKey = 'preferred_b16_standards';
const _surfaceFinishRequiredKey = 'surface_finish_required';
const _surfaceFinishUnitKey = 'surface_finish_unit';
const _defaultQcInspectorNameKey = 'default_qc_inspector_name';
const _defaultQcManagerNameKey = 'default_qc_manager_name';
const _hasSavedInspectorSignatureKey = 'has_saved_inspector_signature';
const _savedInspectorSignaturePathKey = 'saved_inspector_signature_path';
const _includeCompanyLogoOnReportsKey = 'include_company_logo_on_reports';
const _companyLogoPathKey = 'company_logo_path';
