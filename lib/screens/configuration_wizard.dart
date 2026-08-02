import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_ai_provider_config.dart';
import '../providers/enhanced_ai_provider_manager.dart';

// Step 1: Provider Type Selection Screen
class _ProviderTypeStep extends StatefulWidget {
  final Function(EnhancedAIProviderConfig) onProviderCreated;

  const _ProviderTypeStep({required this.onProviderCreated});

  @override
  State<_ProviderTypeStep> createState() => _ProviderTypeStepState();
}

class _ProviderTypeStepState extends State<_ProviderTypeStep> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController(text: 'https://api.openai.com');
  String _selectedProviderType = 'openai';

  final List<Map<String, dynamic>> _providerTypes = [
    {
      'id': 'openai',
      'name': 'OpenAI (GPT-4o / GPT-3.5)',
      'baseUrl': 'https://api.openai.com',
      'icon': Icons.smart_toy,
      'color': Colors.green,
    },
    {
      'id': 'anthropic',
      'name': 'Anthropic (Claude)',
      'baseUrl': 'https://api.anthropic.com',
      'icon': Icons.psychology,
      'color': Colors.purple,
    },
    {
      'id': 'gemini',
      'name': 'Google Gemini',
      'baseUrl': 'https://generativelanguage.googleapis.com',
      'icon': Icons.auto_awesome,
      'color': Colors.blue,
    },
    {
      'id': 'ollama',
      'name': 'Ollama (Local)',
      'baseUrl': 'http://localhost:11434/v1',
      'icon': Icons.computer,
      'color': Colors.orange,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 1: Chọn loại nhà cung cấp AI',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn loại dịch vụ AI bạn muốn cấu hình',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),

        // Provider type grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: _providerTypes.length,
          itemBuilder: (context, index) {
            final provider = _providerTypes[index];
            final isSelected = _selectedProviderType == provider['id'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedProviderType = provider['id'];
                  _baseUrlController.text = provider['baseUrl'];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.05)
                      : theme.colorScheme.surface,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      provider['icon'] as IconData,
                      size: 32,
                      color: isSelected
                          ? (provider['color'] as Color).darker
                          : (provider['color'] as Color).withOpacity(0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider['name'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Basic configuration fields
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Tên nhà cung cấp',
            hintText: 'Ví dụ: My OpenAI Connection',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.label_outlined),
          ),
          onChanged: (value) {
            // Update baseUrl if empty when provider type changes
            if (value.isEmpty && _selectedProviderType == 'openai') {
              _baseUrlController.text = 'https://api.openai.com';
            }
          },
        ),

        const SizedBox(height: 16),

        TextField(
          controller: _baseUrlController,
          decoration: InputDecoration(
            labelText: 'Base URL',
            hintText: 'https://api.example.com',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.link_outlined),
          ),
          onChanged: (value) {
            setState(() {
              _baseUrlController.text = value;
            });
          },
        ),

        const SizedBox(height: 32),

        // Next button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_nameController.text.isNotEmpty &&
                  _baseUrlController.text.isNotEmpty) {
                final provider = EnhancedAIProviderConfig(
                  id: '${_selectedProviderType}_custom',
                  name: _nameController.text,
                  baseUrl: _baseUrlController.text,
                  apiKeys: [],
                  availableModels: [],
                  selectedModel: '',
                  status: ProviderStatus.testing,
                  lastChecked: DateTime.now(),
                );
                widget.onProviderCreated(provider);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập tên nhà cung cấp và Base URL'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Tiếp theo'),
          ),
        ),
      ],
    );
  }
}

// Step 2: API Key Management Screen
class _APIKeyStep extends StatefulWidget {
  final EnhancedAIProviderConfig providerConfig;
  final Function(EnhancedAIProviderConfig) onConfigUpdated;

  const _APIKeyStep({
    required this.providerConfig,
    required this.onConfigUpdated,
  });

  @override
  State<_APIKeyStep> createState() => _APIKeyStepState();
}

class _APIKeyStepState extends State<_APIKeyStep> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _keyControllers = [];
  final List<TextEditingController> _labelControllers = [];
  final List<TextEditingController> _scheduleControllers = [];
  final List<String> _rotationSchedules = ['manual', 'weekly', 'monthly', 'quarterly'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (int i = 0; i < widget.providerConfig.apiKeys.length; i++) {
      _keyControllers.add(TextEditingController(
        text: widget.providerConfig.apiKeys[i].key.isNotEmpty
            ? '••••••••' + widget.providerConfig.apiKeys[i].key.substring(widget.providerConfig.apiKeys[i].key.length - 4)
            : '',
      ));
      _labelControllers.add(TextEditingController(
        text: widget.providerConfig.apiKeys[i].label,
      ));
      _scheduleControllers.add(TextEditingController(
        text: widget.providerConfig.apiKeys[i].rotationSchedule,
      ));
    }
    // Add empty controllers for new keys
    _addEmptyKeyControllers();
  }

  void _addEmptyKeyControllers() {
    if (_keyControllers.length == _labelControllers.length) {
      _keyControllers.add(TextEditingController());
      _labelControllers.add(TextEditingController());
      _scheduleControllers.add(TextEditingController(text: 'manual'));
    }
  }

  @override
  void dispose() {
    for (final controller in _keyControllers) {
      controller.dispose();
    }
    for (final controller in _labelControllers) {
      controller.dispose();
    }
    for (final controller in _scheduleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 2: Cấu hình API Keys',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thêm và cấu hình API keys cho nhà cung cấp',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),

        Form(
          key: _formKey,
          child: Column(
            children: [
              ...List.generate(_keyControllers.length, (index) {
                return _buildKeyCard(index);
              }),

              const SizedBox(height: 16),

              // Add key button
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _addEmptyKeyControllers();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm API Key'),
              ),

              const SizedBox(height: 32),

              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final updatedKeys = <APIKeyConfig>[];

                      for (int i = 0; i < _keyControllers.length - 1; i++) {
                        final keyText = _keyControllers[i].text;
                        final labelText = _labelControllers[i].text;
                        final scheduleText = _scheduleControllers[i].text;

                        if (keyText.isNotEmpty && labelText.isNotEmpty) {
                          // Mask the key (show only last 4 characters)
                          final maskedKey = keyText.length > 4
                              ? '••••••••' + keyText.substring(keyText.length - 4)
                              : keyText;

                          updatedKeys.add(APIKeyConfig(
                            key: maskedKey,
                            label: labelText,
                            isPrimary: i == 0,
                            lastUsed: DateTime.now(),
                            isActive: true,
                            rotationSchedule: scheduleText,
                          ));
                        }
                      }

                      final updatedConfig = widget.providerConfig.copyWith(
                        apiKeys: updatedKeys,
                        status: ProviderStatus.testing,
                        lastChecked: DateTime.now(),
                      );

                      widget.onConfigUpdated(updatedConfig);
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Tiếp theo'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyCard(int index) {
    final theme = Theme.of(context);
    final isLast = index == _keyControllers.length - 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'API Key ${index + 1}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLast)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _keyControllers.removeAt(index);
                        _labelControllers.removeAt(index);
                        _scheduleControllers.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _labelControllers[index],
              decoration: const InputDecoration(
                labelText: 'Tên key',
                hintText: 'Ví dụ: Primary Key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên key';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _keyControllers[index],
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Nhập API key (sẽ được che giấu)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
              validator: (value) {
                if (!isLast && (value == null || value.isEmpty)) {
                  return 'Bỏ trống chỉ dành cho key cuối cùng';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _scheduleControllers[index].text,
              decoration: const InputDecoration(
                labelText: 'Lịch trình rotation',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: _rotationSchedules
                  .map((schedule) => DropdownMenuItem(
                        value: schedule,
                        child: Text(_getScheduleDisplayName(schedule)),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _scheduleControllers[index].text = value ?? 'manual';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getScheduleDisplayName(String schedule) {
    switch (schedule) {
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      case 'quarterly':
        return 'Hàng quý';
      default:
        return 'Thủ công';
    }
  }
}

// Step 3: Model Selection Screen
class _ModelSelectionStep extends StatefulWidget {
  final EnhancedAIProviderConfig providerConfig;
  final Function(EnhancedAIProviderConfig) onConfigUpdated;

  const _ModelSelectionStep({
    required this.providerConfig,
    required this.onConfigUpdated,
  });

  @override
  State<_ModelSelectionStep> createState() => _ModelSelectionStepState();
}

class _ModelSelectionStepState extends State<_ModelSelectionStep> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _availableModels = [
    'gpt-4o',
    'gpt-4o-mini',
    'gpt-3.5-turbo',
    'claude-3-5-sonnet-20240620',
    'claude-3-opus-20240229',
    'claude-3-haiku-20240307',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'llama3.1',
    'mistral',
    'qwen2.5',
  ];
  final TextEditingController _contextWindowController = TextEditingController(text: '4096');
  final TextEditingController _temperatureController = TextEditingController(text: '0.7');
  final TextEditingController _maxTokensController = TextEditingController(text: '4096');

  @override
  void dispose() {
    _contextWindowController.dispose();
    _temperatureController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 3: Chọn Model và Tham số',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn model mong muốn và thiết lập tham số',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),

        Form(
          key: _formKey,
          child: Column(
            children: [
              // Model selection
              DropdownButtonFormField<String>(
                value: widget.providerConfig.selectedModel.isEmpty
                    ? null
                    : widget.providerConfig.selectedModel,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.model_training),
                ),
                items: _availableModels
                    .map((model) => DropdownMenuItem(
                          value: model,
                          child: Text(model),
                        ))
                    .toList(),
                onChanged: (value) {
                  // Update provider config
                  final updatedConfig = widget.providerConfig.copyWith(
                    selectedModel: value ?? '',
                    status: ProviderStatus.testing,
                    lastChecked: DateTime.now(),
                  );
                  widget.onConfigUpdated(updatedConfig);
                },
              ),

              const SizedBox(height: 16),

              // Context window
              TextFormField(
                controller: _contextWindowController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Context Window',
                  hintText: 'Ví dụ: 4096',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.memory),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập context window';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Context window phải là số dương';
                  }
                  return null;
                },
                onChanged: (value) {
                  final updatedConfig = widget.providerConfig.copyWith(
                    contextWindow: int.tryParse(value) ?? 4096,
                  );
                  widget.onConfigUpdated(updatedConfig);
                },
              ),

              const SizedBox(height: 16),

              // Temperature
              TextFormField(
                controller: _temperatureController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Temperature',
                  hintText: 'Ví dụ: 0.7',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.thermostat),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập temperature';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num < 0 || num > 2) {
                    return 'Temperature phải từ 0.0 đến 2.0';
                  }
                  return null;
                },
                onChanged: (value) {
                  final updatedConfig = widget.providerConfig.copyWith(
                    temperature: double.tryParse(value) ?? 0.7,
                  );
                  widget.onConfigUpdated(updatedConfig);
                },
              ),

              const SizedBox(height: 16),

              // Max tokens
              TextFormField(
                controller: _maxTokensController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Tokens',
                  hintText: 'Ví dụ: 4096',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập max tokens';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Max tokens phải là số dương';
                  }
                  return null;
                },
                onChanged: (value) {
                  final updatedConfig = widget.providerConfig.copyWith(
                    maxTokens: int.tryParse(value) ?? 4096,
                  );
                  widget.onConfigUpdated(updatedConfig);
                },
              ),

              const SizedBox(height: 32),

              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final updatedConfig = widget.providerConfig.copyWith(
                        contextWindow: int.tryParse(_contextWindowController.text) ?? 4096,
                        temperature: double.tryParse(_temperatureController.text) ?? 0.7,
                        maxTokens: int.tryParse(_maxTokensController.text) ?? 4096,
                        status: ProviderStatus.healthy,
                        lastChecked: DateTime.now(),
                      );
                      widget.onConfigUpdated(updatedConfig);
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Tiếp theo'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Step 4: Summary and Configuration Complete
class _SummaryStep extends StatelessWidget {
  final EnhancedAIProviderConfig providerConfig;
  final Function() onConfigurationComplete;

  const _SummaryStep({
    required this.providerConfig,
    required this.onConfigurationComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước 4: Hoàn thành cấu hình',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Xem lại cấu hình của bạn và bắt đầu sử dụng',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),

        // Configuration summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      providerConfig.apiKeys.isNotEmpty
                          ? Icons.check_circle
                          : Icons.warning,
                      color: providerConfig.apiKeys.isNotEmpty
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        providerConfig.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                _buildSummaryRow(
                  context,
                  'Base URL',
                  providerConfig.baseUrl,
                  Icons.link,
                ),

                _buildSummaryRow(
                  context,
                  'Model',
                  providerConfig.selectedModel,
                  Icons.model_training,
                ),

                _buildSummaryRow(
                  context,
                  'API Keys',
                  '${providerConfig.apiKeys.length} key(s)',
                  Icons.vpn_key,
                ),

                _buildSummaryRow(
                  context,
                  'Context Window',
                  '${providerConfig.contextWindow}',
                  Icons.memory,
                ),

                _buildSummaryRow(
                  context,
                  'Temperature',
                  '${providerConfig.temperature}',
                  Icons.thermostat,
                ),

                _buildSummaryRow(
                  context,
                  'Max Tokens',
                  '${providerConfig.maxTokens}',
                  Icons.numbers,
                ),

                const Divider(height: 24),

                _buildStatusRow(context, providerConfig.status),

                const SizedBox(height: 24),

                // Start button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onConfigurationComplete,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Bắt đầu sử dụng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, ProviderStatus status) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          _getStatusIcon(status),
          size: 20,
          color: _getStatusColor(status),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Trạng thái: ${_getStatusDisplayName(status)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(ProviderStatus status) {
    switch (status) {
      case ProviderStatus.unknown:
        return Icons.help_outline;
      case ProviderStatus.testing:
        return Icons.hourglass_empty;
      case ProviderStatus.healthy:
        return Icons.check_circle;
      case ProviderStatus.degraded:
        return Icons.warning;
      case ProviderStatus.failed:
        return Icons.error_outline;
      case ProviderStatus.rotated:
        return Icons.autorenew;
    }
  }

  Color _getStatusColor(ProviderStatus status) {
    switch (status) {
      case ProviderStatus.unknown:
        return Colors.grey;
      case ProviderStatus.testing:
        return Colors.orange;
      case ProviderStatus.healthy:
        return Colors.green;
      case ProviderStatus.degraded:
        return Colors.amber;
      case ProviderStatus.failed:
        return Colors.red;
      case ProviderStatus.rotated:
        return Colors.blue;
    }
  }

  String _getStatusDisplayName(ProviderStatus status) {
    switch (status) {
      case ProviderStatus.unknown:
        return 'Unknown';
      case ProviderStatus.testing:
        return 'Đang kiểm tra';
      case ProviderStatus.healthy:
        return 'Đã kiểm tra';
      case ProviderStatus.degraded:
        return ' degraded';
      case ProviderStatus.failed:
        return 'Thất bại';
      case ProviderStatus.rotated:
        return 'Đã rotation';
    }
  }
}

// Main Configuration Wizard
class ConfigurationWizard extends StatefulWidget {
  const ConfigurationWizard({super.key});

  @override
  State<ConfigurationWizard> createState() => _ConfigurationWizardState();
}

class _ConfigurationWizardState extends State<ConfigurationWizard> {
  int _currentStep = 0;
  EnhancedAIProviderConfig? _currentProvider;

  List<Widget> get _steps => [
    _ProviderTypeStep(onProviderCreated: _updateCurrentProvider),
    _APIKeyStep(providerConfig: _currentProvider ?? EnhancedAIProviderConfig(id: '', name: '', baseUrl: ''), onConfigUpdated: _updateCurrentProvider),
    _ModelSelectionStep(providerConfig: _currentProvider ?? EnhancedAIProviderConfig(id: '', name: '', baseUrl: ''), onConfigUpdated: _updateCurrentProvider),
    _SummaryStep(providerConfig: _currentProvider ?? EnhancedAIProviderConfig(id: '', name: '', baseUrl: ''), onConfigurationComplete: _completeConfiguration),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình Nhà cung cấp AI'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: theme.colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _steps[_currentStep],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Quay lại'),
                  )
                else
                  const SizedBox(width: 100),

                ElevatedButton.icon(
                  onPressed: () {
                    if (_currentStep < _steps.length - 1) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      // Complete configuration
                      _completeConfiguration();
                    }
                  },
                  icon: Icon(_currentStep < _steps.length - 1
                      ? Icons.arrow_forward
                      : Icons.check_circle),
                  label: Text(_currentStep < _steps.length - 1
                      ? 'Tiếp theo'
                      : 'Hoàn thành'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateCurrentProvider(EnhancedAIProviderConfig config) {
    setState(() {
      _currentProvider = config;
    });
  }

  void _completeConfiguration() {
    if (_currentProvider != null) {
      // Save to provider manager
      final manager = Provider.of<EnhancedAIProviderManager>(
        context,
        listen: false,
      );
      manager.addProvider(_currentProvider!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cấu hình nhà cung cấp AI thành công: ${_currentProvider!.name}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }
}

// Extension for Color class
extension ColorUtils on Color {
  Color get lighter => withOpacity(0.1);
  Color get darker => withOpacity(0.8);
}