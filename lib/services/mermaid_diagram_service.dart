/// Service to generate Mermaid.js diagram definitions and HTML graphic representations.
class MermaidDiagramService {
  /// Generates a Mermaid flowchart HTML block.
  String generateFlowchartHtml(List<String> steps) {
    if (steps.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('<div class="diagram-flowchart" style="padding: 16px; background: rgba(0,0,0,0.03); border-radius: 12px; margin-top: 16px;">');
    buffer.writeln('<h3>Sơ Đồ Quy Trình (Flowchart)</h3>');
    buffer.writeln('<div style="display: flex; gap: 12px; align-items: center; overflow-x: auto;">');

    for (var i = 0; i < steps.length; i++) {
      buffer.writeln(
        '<div style="padding: 12px 18px; background: #3B82F6; color: white; border-radius: 8px; font-weight: bold;">'
        '${i + 1}. ${steps[i]}'
        '</div>',
      );
      if (i < steps.length - 1) {
        buffer.writeln('<div style="font-size: 20px; color: #6B7280;">➔</div>');
      }
    }

    buffer.writeln('</div></div>');
    return buffer.toString();
  }

  /// Generates a Mermaid mindmap HTML block.
  String generateMindmapHtml(String centralTopic, List<String> subtopics) {
    final buffer = StringBuffer();
    buffer.writeln('<div class="diagram-mindmap" style="padding: 16px; background: rgba(0,0,0,0.03); border-radius: 12px; margin-top: 16px;">');
    buffer.writeln('<h3>Sơ Đồ Tư Duy (Mindmap): $centralTopic</h3>');
    buffer.writeln('<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px;">');

    for (final topic in subtopics) {
      buffer.writeln(
        '<div style="padding: 14px; background: #10B981; color: white; border-radius: 8px; text-align: center; font-weight: 500;">'
        '📌 $topic'
        '</div>',
      );
    }

    buffer.writeln('</div></div>');
    return buffer.toString();
  }
}
