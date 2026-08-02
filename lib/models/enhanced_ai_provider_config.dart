import 'package:shared_preferences/shared_preferences.dart';
import '../providers/ai_provider_manager.dart';

enum ProviderStatus {
  unknown,
  testing,
  healthy,
  degraded,
  failed,
  rotated;

  String get displayName {
    switch (this) {
      case ProviderStatus.unknown:
        return 'Unknown';
      case ProviderStatus.testing:
        return 'Testing';
      case ProviderStatus.healthy:
        return 'Healthy';
      case ProviderStatus.degraded:
        return 'Degraded';
      case ProviderStatus.failed:
        return 'Failed';
      case ProviderStatus.rotated:
        return 'Rotated';
    }
  }
}

class APIKeyConfig {
  final String key;
  final String label;
  final bool isPrimary;
  final DateTime lastUsed;
  final bool isActive;
  final String rotationSchedule;
  final DateTime? lastRotated;

  APIKeyConfig({
    required this.key,
    required this.label,
    this.isPrimary = false,
    required this.lastUsed,
    this.isActive = true,
    this.rotationSchedule = 'manual',
    this.lastRotated,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'isPrimary': isPrimary,
      'lastUsed': lastUsed.toIso8601String(),
      'isActive': isActive,
      'rotationSchedule': rotationSchedule,
      'lastRotated': lastRotated?.toIso8601String(),
    };
  }

  factory APIKeyConfig.fromMap(Map<String, dynamic> map) {
    return APIKeyConfig(
      key: map['key'] ?? '',
      label: map['label'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
      lastUsed: DateTime.tryParse(map['lastUsed'] ?? '') ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      rotationSchedule: map['rotationSchedule'] ?? 'manual',
      lastRotated: map['lastRotated'] != null
          ? DateTime.tryParse(map['lastRotated'])
          : null,
    );
  }

  bool get isValid => key.isNotEmpty && label.isNotEmpty;
}

class EnhancedAIProviderConfig {
  final String id;
  final String name;
  final String baseUrl;
  final List<APIKeyConfig> apiKeys;
  final List<String> availableModels;
  final String selectedModel;
  final int contextWindow;
  final String formatType;
  final double temperature;
  final int maxTokens;
  final ProviderStatus status;
  final DateTime lastChecked;
  final Map<String, dynamic> metadata;

  EnhancedAIProviderConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.apiKeys = const [],
    this.availableModels = const [],
    this.selectedModel = '',
    this.contextWindow = 4096,
    this.formatType = 'openai',
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.status = ProviderStatus.unknown,
    DateTime? lastChecked,
    this.metadata = const {},
  }) : lastChecked = lastChecked ?? DateTime.now();

  factory EnhancedAIProviderConfig.fromLegacy(
    AIProviderConfig legacyConfig, {
    String? primaryApiKey,
    ProviderStatus status = ProviderStatus.unknown,
    DateTime? lastChecked,
    Map<String, dynamic>? metadata,
  }) {
    final keys = <APIKeyConfig>[];
    final apiKey = primaryApiKey ?? legacyConfig.apiKey;
    if (apiKey.isNotEmpty) {
      keys.add(APIKeyConfig(
        key: apiKey,
        label: 'Primary Key',
        isPrimary: true,
        lastUsed: DateTime.now(),
      ));
    }

    return EnhancedAIProviderConfig(
      id: legacyConfig.id,
      name: legacyConfig.name,
      baseUrl: legacyConfig.baseUrl,
      apiKeys: keys,
      availableModels: legacyConfig.availableModels,
      selectedModel: legacyConfig.selectedModel,
      contextWindow: legacyConfig.contextWindow,
      formatType: legacyConfig.formatType,
      temperature: legacyConfig.temperature,
      maxTokens: legacyConfig.maxTokens,
      status: status,
      lastChecked: lastChecked,
      metadata: metadata ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'availableModels': availableModels,
      'selectedModel': selectedModel,
      'contextWindow': contextWindow,
      'formatType': formatType,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'status': status.index,
      'lastChecked': lastChecked.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory EnhancedAIProviderConfig.fromMap(Map<String, dynamic> map) {
    return EnhancedAIProviderConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      baseUrl: map['baseUrl'] ?? '',
      availableModels: List<String>.from(map['availableModels'] ?? []),
      selectedModel: map['selectedModel'] ?? '',
      contextWindow: map['contextWindow'] ?? 4096,
      formatType: map['formatType'] ?? 'openai',
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: map['maxTokens'] as int? ?? 4096,
      status: ProviderStatus.values[map['status'] ?? 0],
      lastChecked: DateTime.tryParse(map['lastChecked'] ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  bool get isValid => id.isNotEmpty && baseUrl.isNotEmpty;
  bool get requiresApiKey {
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    return host != 'localhost' && host != '127.0.0.1' && host != '0.0.0.0';
  }

  APIKeyConfig? getPrimaryKey() {
    final primaries = apiKeys.where((k) => k.isPrimary).toList();
    return primaries.isNotEmpty ? primaries.first : (apiKeys.isNotEmpty ? apiKeys.first : null);
  }

  List<APIKeyConfig> getActiveKeys => apiKeys.where((k) => k.isActive).toList();

  EnhancedAIProviderConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    List<APIKeyConfig>? apiKeys,
    List<String>? availableModels,
    String? selectedModel,
    int? contextWindow,
    String? formatType,
    double? temperature,
    int? maxTokens,
    ProviderStatus? status,
    DateTime? lastChecked,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedAIProviderConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKeys: apiKeys ?? this.apiKeys,
      availableModels: availableModels ?? this.availableModels,
      selectedModel: selectedModel ?? this.selectedModel,
      contextWindow: contextWindow ?? this.contextWindow,
      formatType: formatType ?? this.formatType,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      metadata: metadata ?? this.metadata,
    );
  }
}
