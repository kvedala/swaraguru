import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:swaraguru/ui/widgets/markdown_view.dart';

const _sample = '''
# Title

## Section

Plain text with **bold** words and `inline code`.

- First item
  - Nested item

| Pitch | Hz |
| --- | ---: |
| C# | 138.59 |

```sh
flutter test
```

See the [license](LICENSE) or https://example.com/docs.
''';

Future<void> pumpMarkdown(WidgetTester tester, LinkLauncher onTapLink) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MarkdownView(data: _sample, onTapLink: onTapLink),
        ),
      ),
    ),
  );
}

void main() {
  group('resolveMarkdownLink', () {
    test('resolves relative paths against the GitHub repository', () {
      expect(
        resolveMarkdownLink('LICENSE'),
        Uri.parse('https://github.com/kvedala/swaraguru/blob/main/LICENSE'),
      );
      expect(
        resolveMarkdownLink('.github/workflows/web.yml'),
        Uri.parse(
          'https://github.com/kvedala/swaraguru/blob/main/'
          '.github/workflows/web.yml',
        ),
      );
    });

    test('keeps web and mail links and rejects anchors and other schemes', () {
      expect(
        resolveMarkdownLink('https://example.com/a?b=1'),
        Uri.parse('https://example.com/a?b=1'),
      );
      expect(
        resolveMarkdownLink('mailto:hi@example.com'),
        Uri.parse('mailto:hi@example.com'),
      );
      expect(resolveMarkdownLink('#getting-started'), isNull);
      expect(resolveMarkdownLink('javascript:alert(1)'), isNull);
    });
  });

  testWidgets('renders Markdown structure instead of raw syntax', (
    tester,
  ) async {
    await pumpMarkdown(tester, (_) async => true);

    expect(find.text('Title', findRichText: true), findsOneWidget);
    expect(find.text('Section', findRichText: true), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^#|\*\*|`|\|'), findRichText: true),
      findsNothing,
    );
    expect(find.text('Nested item', findRichText: true), findsOneWidget);
    expect(find.text('◦'), findsOneWidget);

    expect(find.byType(Table), findsOneWidget);
    expect(find.text('138.59', findRichText: true), findsOneWidget);
    final hzCell = tester.widget<RichText>(
      find.text('138.59', findRichText: true),
    );
    expect(hzCell.textAlign, TextAlign.right);
    expect(find.text('flutter test'), findsOneWidget);
  });

  testWidgets('opens resolved links and reports failures', (tester) async {
    final opened = <Uri>[];
    await pumpMarkdown(tester, (uri) async {
      opened.add(uri);
      return uri.host == 'github.com';
    });

    await tester.tapOnText(find.textRange.ofSubstring('license'));
    await tester.pump();
    expect(opened, [
      Uri.parse('https://github.com/kvedala/swaraguru/blob/main/LICENSE'),
    ]);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tapOnText(find.textRange.ofSubstring('example.com/docs'));
    await tester.pump();
    expect(opened.last, Uri.parse('https://example.com/docs'));
    expect(
      find.text('Could not open https://example.com/docs'),
      findsOneWidget,
    );
  });

  testWidgets('links are tab-focusable and activate with Enter and Space', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final opened = <Uri>[];
    await pumpMarkdown(tester, (uri) async {
      opened.add(uri);
      return true;
    });

    final licenseFocus = Focus.of(tester.element(find.text('license')));
    final docsFocus = Focus.of(
      tester.element(
        find.textContaining('https://example.com/docs', findRichText: true),
      ),
    );
    final linkSemantics = tester
        .getSemantics(find.bySemanticsLabel('license'))
        .getSemanticsData();
    expect(linkSemantics.flagsCollection.isLink, isTrue);
    expect(linkSemantics.hasAction(SemanticsAction.tap), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(licenseFocus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, [
      Uri.parse('https://github.com/kvedala/swaraguru/blob/main/LICENSE'),
    ]);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(docsFocus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(opened.last, Uri.parse('https://example.com/docs'));
    semantics.dispose();
  });
}
