import 'package:flutter/material.dart';
import '../providers/ai_provider_manager.dart';
import '../services/api_fallback_cascade_service.dart';
import '../services/local_ai_detector_service.dart';

class ProviderSettingsScreen extends StatefulWidget {
  final AIProviderManager aiProviderManager;

  const ProviderSettingsScreen({
    super.key,
    required this.aiProviderManager,
  });

  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
  final Map<String, PingResult?> _pingResults = {};
  final Map<String, bool> _loadingState = {};
  final APIFallbackCascadeService _cascadeService = APIFallbackCascadeService();
  final LocalAIDetectorService _localDetector = LocalAIDetectorService();

  Future<void> _testPing(AIProviderConfig config) async {
    setState(() => _loadingState[config.id] = true);
    final res = await _cascadeService.testProviderPing(config);
    if (mounted) {
      setState(() {
        _pingResults[config.id] = res;
        _loadingState[config.id] = false;
      });
    }
  }

  Future<void> _fetchModels(AIProviderConfig config) async {
    setState(() => _loadingState[config.id] = true);
    final models = await widget.aiProviderManager.fetchAvailableModels(config);
    if (mounted) {
      setState(() => _loadingState[config.id] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật ${models.length} mô hình cho ${config.name}')),
      );
    }
  }

  Future<void> _scanLocalAI() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang quét các dịch vụ AI Local (Ollama, LM Studio...)...')),
    );
    final detected = await _localDetector.scanLocalAIServices();
    if (mounted) {
      if (detected.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy dịch vụ AI Local đang chạy.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tìm thấy ${detected.length} dịch vụ AI Local!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providers = widget.aiProviderManager.providers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý AI Provider & Kết Nối'),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar),
            tooltip: 'Tự động quét AI Local (Auto-Discover)',
            onPressed: _scanLocalAI,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: providers.length,
        itemBuilder: (context, index) {
          final p = providers[index];
          final ping = _pingResults[p.id];
          final isLoading = _loadingState[p.id] ?? false;

          return Card(
            key: ValueKey(p.id),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            p.formatType == 'gemini'
                                ? Icons.auto_awesome
                                : p.formatType == 'anthropic'
                                    ? Icons.psychology
                                    : Icons.hub,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (ping != null)
                        Chip(
                          avatar: Icon(
                            ping.isSuccess ? Icons.check_circle : Icons.error,
                            color: ping.isSuccess ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          label: Text(
                            ping.isSuccess ? '${ping.latencyMs} ms' : 'Error',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Base URL: ${p.baseUrl}', style: theme.textTheme.bodySmall),
                  Text('Model hiện tại: ${p.selectedModel}', style: theme.textTheme.bodySmall),
                  Text('Mô hình khả dụng: ${p.availableModels.join(", ")}',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.speed, size: 16),
                        label: const Text('Test Ping'),
                        onPressed: isLoading ? null : () => _testPing(p),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('Tải danh sách Model'),
                        onPressed: isLoading ? null : () => _fetchModels(p),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
