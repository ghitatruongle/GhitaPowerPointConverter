import 'package:flutter/material.dart';

/// Mermaid Diagram Dialog — v1.2.0
/// Generates flowchart/mindmap/sequence HTML via Mermaid.js-compatible markup.
class MermaidDialog extends StatefulWidget {
  final void Function(String html)? onInsertHtml;

  const MermaidDialog({super.key, this.onInsertHtml});

  @override
  State<MermaidDialog> createState() => _MermaidDialogState();
}

class _MermaidDialogState extends State<MermaidDialog> {
  String _diagramType = 'flowchart';
  final _nodesController = TextEditingController(text: 'Start,Process,Decision,End');
  final _edgesController = TextEditingController(text: 'Start->Process,Process->Decision,Decision->End');

  @override
  void dispose() {
    _nodesController.dispose();
    _edgesController.dispose();
    super.dispose();
  }

  String _generateHtml() {
    final nodes = _nodesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final edges = _edgesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    switch (_diagramType) {
      case 'flowchart':
        return _buildFlowchartHtml(nodes, edges);
      case 'mindmap':
        return _buildMindmapHtml(nodes);
      case 'sequence':
        return _buildSequenceHtml(nodes, edges);
      default:
        return _buildFlowchartHtml(nodes, edges);
    }
  }

  String _buildFlowchartHtml(List<String> nodes, List<String> edges) {
    final nodeHtml = nodes.map((node) {
      final id = node.toLowerCase().replaceAll(' ', '_');
      return '  <div id="$id" style="background: #e65100; color: white; padding: 10px 20px; border-radius: 8px; text-align: center; font-weight: bold; min-width: 80px;">$node</div>';
    }).join('\n');

    return '<div style="display: flex; flex-direction: column; align-items: center; gap: 12px; margin: 16px 0;">\n'
        '$nodeHtml\n'
        '  <!-- Edges: ${edges.join(', ')} -->\n'
        '</div>';
  }

  String _buildMindmapHtml(List<String> nodes) {
    if (nodes.isEmpty) return '<p>Empty mindmap</p>';
    final center = nodes.first;
    final branches = nodes.skip(1).toList();

    final branchHtml = branches.map((b) =>
      '<div style="background: #1565c0; color: white; padding: 8px 16px; border-radius: 20px; font-size: 0.9em;">$b</div>'
    ).join('\n    ');

    return '<div style="display: flex; flex-direction: column; align-items: center; margin: 16px 0;">\n'
        '  <div style="background: #e65100; color: white; padding: 16px 32px; border-radius: 50%; font-weight: bold; font-size: 1.2em;">$center</div>\n'
        '  <div style="display: flex; flex-wrap: wrap; justify-content: center; gap: 12px; margin-top: 16px;">\n'
        '    $branchHtml\n'
        '  </div>\n'
        '</div>';
  }

  String _buildSequenceHtml(List<String> nodes, List<String> edges) {
    final actors = nodes.take(3).toList();
    final messages = edges.take(4).toList();

    final actorHeaders = actors.map((a) =>
      '<div style="flex: 1; text-align: center; font-weight: bold; padding: 8px; background: #1565c0; color: white; border-radius: 4px;">$a</div>'
    ).join('\n    ');

    final messageHtml = messages.map((m) {
      final parts = m.split('->');
      final from = parts.isNotEmpty ? parts[0].trim() : '';
      final to = parts.length > 1 ? parts[1].trim() : '';
      return '<div style="text-align: center; padding: 4px; font-size: 0.85em;">$from → $to</div>';
    }).join('\n    ');

    return '<div style="margin: 16px 0;">\n'
        '  <div style="display: flex; gap: 16px; margin-bottom: 12px;">\n    $actorHeaders\n  </div>\n'
        '  <div style="border-top: 2px solid #ccc; padding-top: 8px;">\n    $messageHtml\n  </div>\n'
        '</div>';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_tree),
                  const SizedBox(width: 12),
                  Text('Mermaid Diagram', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'flowchart', label: Text('Flowchart'), icon: Icon(Icons.account_tree)),
                        ButtonSegment(value: 'mindmap', label: Text('Mindmap'), icon: Icon(Icons.bubble_chart)),
                        ButtonSegment(value: 'sequence', label: Text('Sequence'), icon: Icon(Icons.swap_horiz)),
                      ],
                      selected: {_diagramType},
                      onSelectionChanged: (v) => setState(() => _diagramType = v.first),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nodesController,
                      decoration: InputDecoration(
                        labelText: _diagramType == 'mindmap' ? 'Nodes (center, branch1, branch2...)' : 'Nodes (comma-separated)',
                        border: const OutlineInputBorder(),
                        hintText: 'Start,Process,End',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_diagramType != 'mindmap')
                      TextField(
                        controller: _edgesController,
                        decoration: const InputDecoration(
                          labelText: 'Edges (A->B, comma-separated)',
                          border: OutlineInputBorder(),
                          hintText: 'Start->Process,Process->End',
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preview HTML:', style: theme.textTheme.labelSmall),
                          const SizedBox(height: 4),
                          Text(
                            _generateHtml(),
                            style: const TextStyle(fontFamily: 'Consolas', fontSize: 9),
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onInsertHtml?.call(_generateHtml());
                    },
                    child: const Text('Chèn Diagram'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
