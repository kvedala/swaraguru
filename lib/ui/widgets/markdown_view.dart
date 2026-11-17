import 'package:flutter/gestures.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/swara_theme.dart';

/// Opens [uri] and reports whether it could be launched.
typedef LinkLauncher = Future<bool> Function(Uri uri);

/// Where relative README links (such as `LICENSE`) live on GitHub.
final Uri readmeLinkBase = Uri.parse(
  'https://github.com/kvedala/swaraguru/blob/main/',
);

const _linkSchemes = {'http', 'https', 'mailto'};

/// Resolves a Markdown `href` against [base], allowing only web and mail
/// links. Returns null for in-page anchors and unsupported schemes.
Uri? resolveMarkdownLink(String href, {Uri? base}) {
  final trimmed = href.trim();
  if (trimmed.isEmpty || trimmed.startsWith('#')) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  final resolved = uri.hasScheme
      ? uri
      : (base ?? readmeLinkBase).resolveUri(uri);
  return _linkSchemes.contains(resolved.scheme.toLowerCase()) ? resolved : null;
}

Future<bool> launchExternalLink(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Renders GitHub-flavoured Markdown with the SwaraGuru palette.
///
/// Supports headings, paragraphs, emphasis, inline and fenced code, nested
/// lists, tables, block quotes, rules, and tappable links. Text is selectable.
class MarkdownView extends StatefulWidget {
  const MarkdownView({
    super.key,
    required this.data,
    this.onTapLink = launchExternalLink,
    this.linkBase,
  });

  final String data;
  final LinkLauncher onTapLink;

  /// Base for relative links; defaults to [readmeLinkBase].
  final Uri? linkBase;

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  final _recognizers = <TapGestureRecognizer>[];
  List<Widget>? _blocks;

  @override
  void didUpdateWidget(MarkdownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.onTapLink != widget.onTapLink ||
        oldWidget.linkBase != widget.linkBase) {
      _blocks = null;
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _openLink(Uri uri) async {
    var opened = false;
    try {
      opened = await widget.onTapLink(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text('Could not open $uri')));
    }
  }

  List<Widget> _build() {
    _disposeRecognizers();
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    final nodes = document.parseLines(widget.data.split(RegExp(r'\r?\n')));
    return _MarkdownBuilder(
      linkBase: widget.linkBase,
      recognizerFor: (uri) {
        final recognizer = TapGestureRecognizer()..onTap = () => _openLink(uri);
        _recognizers.add(recognizer);
        return recognizer;
      },
    ).blocks(nodes);
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _blocks ??= _build(),
      ),
    );
  }
}

class _MarkdownStyles {
  static const bodyColor = Color(0xFFE2E8F0);
  static const _codeColor = Color(0xFFF8FAFC);
  static const _mono = 'monospace';
  static const _monoFallback = [
    'Menlo',
    'Consolas',
    'Roboto Mono',
    'Courier New',
  ];

  static const body = TextStyle(fontSize: 15, height: 1.55, color: bodyColor);

  static TextStyle heading(int level) => switch (level) {
    1 => const TextStyle(
      fontFamily: 'serif',
      fontSize: 27,
      height: 1.25,
      fontWeight: FontWeight.bold,
      color: SwaraColors.brightGold,
    ),
    2 => const TextStyle(
      fontSize: 21,
      height: 1.3,
      fontWeight: FontWeight.bold,
      color: SwaraColors.royalGold,
    ),
    3 => const TextStyle(
      fontSize: 17.5,
      height: 1.35,
      fontWeight: FontWeight.bold,
      color: SwaraColors.brightGold,
    ),
    _ => const TextStyle(
      fontSize: 15.5,
      height: 1.4,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  };

  static TextStyle inlineCode(TextStyle base) => base.copyWith(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: (base.fontSize ?? 15) * 0.9,
    color: SwaraColors.brightGold,
    backgroundColor: const Color(0x26E5B869),
  );

  static const codeBlock = TextStyle(
    fontFamily: _mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 13.5,
    height: 1.45,
    color: _codeColor,
  );

  static TextStyle link(TextStyle base) => base.copyWith(
    color: SwaraColors.cyanWave,
    decoration: TextDecoration.underline,
    decorationColor: SwaraColors.cyanWave.withValues(alpha: 0.6),
  );
}

class _MarkdownBuilder {
  _MarkdownBuilder({required this.linkBase, required this.recognizerFor});

  final Uri? linkBase;
  final TapGestureRecognizer Function(Uri uri) recognizerFor;

  static const _blockTags = {
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'p',
    'ul',
    'ol',
    'pre',
    'blockquote',
    'hr',
    'table',
  };

  List<Widget> blocks(List<md.Node> nodes, {int listDepth = 0}) {
    final widgets = <Widget>[];
    final pendingInline = <md.Node>[];

    void flushInline() {
      if (pendingInline.isEmpty) return;
      widgets.add(_paragraph(List.of(pendingInline), _MarkdownStyles.body));
      pendingInline.clear();
    }

    for (final node in nodes) {
      if (node is md.Element && _blockTags.contains(node.tag)) {
        flushInline();
        widgets.add(_block(node, listDepth));
      } else {
        pendingInline.add(node);
      }
    }
    flushInline();
    return _spaced(widgets, listDepth > 0 ? 6 : 12);
  }

  List<Widget> _spaced(List<Widget> widgets, double gap) => [
    for (var i = 0; i < widgets.length; i++) ...[
      if (i > 0) SizedBox(height: gap),
      widgets[i],
    ],
  ];

  Widget _block(md.Element element, int listDepth) {
    final children = element.children ?? const <md.Node>[];
    switch (element.tag) {
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        return _heading(element, int.parse(element.tag.substring(1)));
      case 'ul':
        return _list(element, ordered: false, depth: listDepth);
      case 'ol':
        return _list(element, ordered: true, depth: listDepth);
      case 'pre':
        return _codeBlock(element.textContent);
      case 'blockquote':
        return Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: SwaraColors.royalGold, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: blocks(children, listDepth: listDepth),
          ),
        );
      case 'hr':
        return const Divider(color: SwaraColors.borderGold, height: 16);
      case 'table':
        return _table(element);
      default:
        return _paragraph(children, _MarkdownStyles.body);
    }
  }

  Widget _heading(md.Element element, int level) {
    final text = _paragraph(
      element.children ?? const [],
      _MarkdownStyles.heading(level),
    );
    final topGap = switch (level) {
      1 => 0.0,
      2 => 18.0,
      3 => 10.0,
      _ => 6.0,
    };
    if (level > 2) {
      return Padding(
        padding: EdgeInsets.only(top: topGap),
        child: text,
      );
    }
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: topGap),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SwaraColors.borderGold)),
      ),
      child: text,
    );
  }

  Widget _paragraph(
    List<md.Node> nodes,
    TextStyle style, {
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text.rich(
      TextSpan(children: _inlines(nodes, style)),
      style: style,
      textAlign: textAlign,
    );
  }

  List<InlineSpan> _inlines(
    List<md.Node> nodes,
    TextStyle style, {
    TapGestureRecognizer? recognizer,
  }) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      if (node is md.Text) {
        spans.add(
          TextSpan(
            // Soft line breaks inside a paragraph render as spaces.
            text: node.text.replaceAll(RegExp(r'\s*\n\s*'), ' '),
            style: style,
            recognizer: recognizer,
          ),
        );
      } else if (node is md.Element) {
        spans.addAll(_inlineElement(node, style, recognizer));
      } else {
        spans.add(TextSpan(text: node.textContent, style: style));
      }
    }
    return spans;
  }

  List<InlineSpan> _inlineElement(
    md.Element element,
    TextStyle style,
    TapGestureRecognizer? recognizer,
  ) {
    final children = element.children ?? const <md.Node>[];
    switch (element.tag) {
      case 'strong' || 'b':
        return _inlines(
          children,
          style.copyWith(
            fontWeight: FontWeight.bold,
            color: style.color == _MarkdownStyles.bodyColor
                ? Colors.white
                : style.color,
          ),
          recognizer: recognizer,
        );
      case 'em' || 'i':
        return _inlines(
          children,
          style.copyWith(fontStyle: FontStyle.italic),
          recognizer: recognizer,
        );
      case 'del' || 's':
        return _inlines(
          children,
          style.copyWith(decoration: TextDecoration.lineThrough),
          recognizer: recognizer,
        );
      case 'code':
        return [
          TextSpan(
            text: element.textContent.replaceAll('\n', ' '),
            style: _MarkdownStyles.inlineCode(style),
            recognizer: recognizer,
          ),
        ];
      case 'a':
        final uri = resolveMarkdownLink(
          element.attributes['href'] ?? '',
          base: linkBase,
        );
        if (uri == null) {
          return _inlines(children, style, recognizer: recognizer);
        }
        return _inlines(
          children,
          _MarkdownStyles.link(style),
          recognizer: recognizerFor(uri),
        );
      case 'br':
        return [TextSpan(text: '\n', style: style)];
      case 'img':
        final alt = element.attributes['alt'];
        return [
          if (alt != null && alt.isNotEmpty)
            TextSpan(
              text: alt,
              style: style.copyWith(fontStyle: FontStyle.italic),
            ),
        ];
      default:
        return _inlines(children, style, recognizer: recognizer);
    }
  }

  Widget _list(
    md.Element element, {
    required bool ordered,
    required int depth,
  }) {
    final start = int.tryParse(element.attributes['start'] ?? '') ?? 1;
    final items = (element.children ?? const <md.Node>[])
        .whereType<md.Element>()
        .where((child) => child.tag == 'li')
        .toList();
    final bullet = depth.isEven ? '•' : '◦';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _spaced([
        for (var i = 0; i < items.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: ordered ? 28 : 20,
                child: Text(
                  ordered ? '${start + i}.' : bullet,
                  style: _MarkdownStyles.body.copyWith(
                    color: SwaraColors.royalGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: blocks(
                    items[i].children ?? const [],
                    listDepth: depth + 1,
                  ),
                ),
              ),
            ],
          ),
      ], 6),
    );
  }

  Widget _codeBlock(String code) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SwaraColors.midnightBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SwaraColors.borderGold),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          code.replaceFirst(RegExp(r'\n+$'), ''),
          style: _MarkdownStyles.codeBlock,
          softWrap: false,
        ),
      ),
    );
  }

  Widget _table(md.Element element) {
    final rows = <(md.Element, bool)>[];
    for (final section
        in (element.children ?? const <md.Node>[]).whereType<md.Element>()) {
      final isHeader = section.tag == 'thead';
      final sectionRows = section.tag == 'tr'
          ? [section]
          : (section.children ?? const <md.Node>[])
                .whereType<md.Element>()
                .where((row) => row.tag == 'tr');
      for (final row in sectionRows) {
        rows.add((row, isHeader));
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    final columnCount = rows
        .map((row) => (row.$1.children ?? const []).length)
        .reduce((a, b) => a > b ? a : b);

    TableRow buildRow(md.Element row, bool isHeader) {
      final cells = (row.children ?? const <md.Node>[])
          .whereType<md.Element>()
          .toList();
      final style = isHeader
          ? _MarkdownStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: SwaraColors.brightGold,
            )
          : _MarkdownStyles.body;
      return TableRow(
        decoration: isHeader
            ? const BoxDecoration(color: Color(0x1FE5B869))
            : null,
        children: [
          for (var i = 0; i < columnCount; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: i < cells.length
                  ? _paragraph(
                      cells[i].children ?? const [],
                      style,
                      textAlign: switch (cells[i].attributes['align']) {
                        'center' => TextAlign.center,
                        'right' => TextAlign.right,
                        _ => TextAlign.start,
                      },
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(
          color: SwaraColors.borderGold,
          borderRadius: BorderRadius.circular(8),
        ),
        children: [for (final (row, isHeader) in rows) buildRow(row, isHeader)],
      ),
    );
  }
}
