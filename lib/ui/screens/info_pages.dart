import 'package:material_ui/material_ui.dart';

import '../../theme/swara_theme.dart';
import '../widgets/markdown_view.dart';

enum InfoPage { help, privacy, license }

extension InfoPageText on InfoPage {
  String get title => switch (this) {
    InfoPage.help => 'Help',
    InfoPage.privacy => 'Privacy Policy',
    InfoPage.license => 'License',
  };

  String get subtitle => switch (this) {
    InfoPage.help => 'Guides and answers for using SwaraGuru.',
    InfoPage.privacy => 'How SwaraGuru handles information and audio.',
    InfoPage.license => 'The terms for using SwaraGuru source code.',
  };
}

/// Marks where the README's user guide ends and developer documentation
/// (setup, project structure, deployment) begins.
const appHelpEndMarker = '<!-- end-of-app-help';

/// Returns the part of [readme] shown on the in-app Help page.
String appHelpFromReadme(String readme) {
  final end = readme.indexOf(appHelpEndMarker);
  return end < 0 ? readme : readme.substring(0, end).trimRight();
}

class InfoPageView extends StatelessWidget {
  const InfoPageView({super.key, required this.page, required this.readme});

  final InfoPage page;
  final Future<String> readme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          page.title,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: SwaraColors.brightGold,
          ),
        ),
        const SizedBox(height: 8),
        Text(page.subtitle, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        switch (page) {
          InfoPage.help => _HelpContent(readme: readme),
          InfoPage.privacy => const _PrivacyContent(),
          InfoPage.license => const _LicenseContent(),
        },
      ],
    );
  }
}

class _HelpContent extends StatelessWidget {
  const _HelpContent({required this.readme});

  final Future<String> readme;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: readme,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Unable to load the documentation: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Text('Loading documentation...');
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: MarkdownView(data: appHelpFromReadme(snapshot.data!)),
          ),
        );
      },
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        InfoCard(title: 'Effective date', body: 'November 17, 2026'),
        InfoCard(
          title: 'Information handled by the app',
          body:
              'SwaraGuru does not require an account and the app does not '
              'collect or transmit personal information, usage analytics, or '
              'microphone recordings. Custom lessons and practice selections '
              'are held in app memory for the current session and are not '
              'saved after you close it.',
        ),
        InfoCard(
          title: 'Audio and microphone',
          body:
              'The Shruti box and Varisai playback generate tampura, '
              'harmonium and piano tones locally on your device; no audio is '
              'sent to a server. The microphone is used only after you press '
              '"Listen & Identify" or start Sing & Match with Microphone '
              'input, and only after you grant permission. Microphone audio '
              'is analysed on-device in short buffers to estimate pitch; it is '
              'never recorded, stored, or transmitted, and the microphone is '
              'released as soon as you stop listening.',
        ),
        InfoCard(
          title: 'Web hosting',
          body:
              'If you use the hosted web app, GitHub Pages may process '
              'standard connection information such as your IP address and '
              'browser request data to deliver the site. That processing is '
              'governed by GitHub’s privacy policy: '
              'https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement.',
        ),
        InfoCard(
          title: 'Changes and contact',
          body:
              'If app behavior changes, this policy will be updated. Questions '
              'or privacy concerns can be raised at '
              'https://github.com/kvedala/swaraguru/issues. GitHub Issues '
              'are public, so do not post personal or sensitive information.',
        ),
      ],
    );
  }
}

class _LicenseContent extends StatelessWidget {
  const _LicenseContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCard(
          title: 'MIT License',
          body:
              'Copyright (c) 2026 SwaraGuru contributors\n\n'
              'Permission is hereby granted, free of charge, to any person '
              'obtaining a copy of this software and associated documentation '
              'files (the "Software"), to deal in the Software without '
              'restriction, including without limitation the rights to use, '
              'copy, modify, merge, publish, distribute, sublicense, and/or '
              'sell copies of the Software, and to permit persons to whom the '
              'Software is furnished to do so, subject to the following '
              'conditions:\n\n'
              'The above copyright notice and this permission notice shall be '
              'included in all copies or substantial portions of the '
              'Software.\n\n'
              'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY '
              'KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE '
              'WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR '
              'PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR '
              'COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
              'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, '
              'ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE '
              'USE OR OTHER DEALINGS IN THE SOFTWARE.',
        ),
        InfoCard(
          title: 'Third-party components',
          body:
              'This license applies to SwaraGuru project source code. '
              'Third-party packages and components remain subject to their '
              'own licenses.',
        ),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: SwaraColors.royalGold,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              body,
              style: const TextStyle(height: 1.5, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
