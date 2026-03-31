// why_it_works_screen.dart
// Summary: Explains the behavioral psychology behind Closer's label system.
// Exports: WhyItWorksScreen
// Sections: Peak-End Rule image, one-liner, 4 labels, scoring rules, 2 science refs.
// Execution Flow: StatelessWidget → SingleChildScrollView → CrayonCard sections.
// Design Notes: Crayon storybook style, url_launcher for external links.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/crayon_theme.dart';
import '../theme/crayon_widgets.dart';

class WhyItWorksScreen extends StatelessWidget {
  const WhyItWorksScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Why It Works'),
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIconsThin.arrowLeft, size: 22,
              color: CrayonColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Peak-End Rule Image ──────────────────────────────
            CrayonCard(
              seed: 10,
              fillColor: CrayonColors.surface,
              strokeColor: CrayonColors.strokeLight,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/peak_end_rule.png',
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your brain judges people by their peak moment + last interaction — not the full picture.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.caveat(
                      fontSize: 16,
                      color: CrayonColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Section 2: One-liner ─────────────────────────────────────────
            CrayonCard(
              seed: 20,
              fillColor: CrayonColors.surfaceAlt,
              strokeColor: CrayonColors.strokeLight,
              child: Row(
                children: [
                  PhosphorIcon(PhosphorIconsThin.eye, size: 20,
                      color: CrayonColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.caveat(
                          fontSize: 19,
                          color: CrayonColors.textPrimary,
                        ),
                        children: const [
                          TextSpan(text: 'Closer looks at the '),
                          TextSpan(
                            text: 'whole pattern',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ', not just the highlights.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section 3: The 4 Labels ──────────────────────────────────────
            Text(
              'The 4 Labels',
              style: GoogleFonts.caveat(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CrayonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _LabelCard(
              seed: 31,
              dotColor: CrayonColors.activeLabel,
              borderColor: const Color(0xFF7BC4A0),
              label: 'Active',
              labelTextColor: CrayonColors.activeLabelText,
              description: 'Consistently positive — worth reaching out first.',
            ),
            const SizedBox(height: 8),
            _LabelCard(
              seed: 32,
              dotColor: CrayonColors.responsiveLabel,
              borderColor: const Color(0xFF7AAAC8),
              label: 'Responsive',
              labelTextColor: CrayonColors.responsiveLabelText,
              description: 'Neutral pattern — engage when they come to you.',
            ),
            const SizedBox(height: 8),
            _LabelCard(
              seed: 33,
              dotColor: CrayonColors.obligatoryLabel,
              borderColor: const Color(0xFFD4A870),
              label: 'Obligatory',
              labelTextColor: CrayonColors.obligatoryLabelText,
              description:
                  'You want distance but still have to show up (coworker, difficult neighbor).',
            ),
            const SizedBox(height: 8),
            _LabelCard(
              seed: 34,
              dotColor: CrayonColors.cutOffLabel,
              borderColor: const Color(0xFFAAAAAA),
              label: 'Cut-off',
              labelTextColor: CrayonColors.cutOffLabelText,
              description: 'A line was crossed — it\'s okay to step away.',
            ),

            const SizedBox(height: 20),

            // ── Section 4: Scoring Rules ─────────────────────────────────────
            Text(
              'Scoring Rules',
              style: GoogleFonts.caveat(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CrayonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            CrayonCard(
              seed: 40,
              fillColor: CrayonColors.surface,
              strokeColor: CrayonColors.strokeLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bullet(
                    'Rate each interaction: ',
                    bold: '-3',
                    boldSuffix: ' (crossed a line) → ',
                    bold2: '+3',
                    bold2Suffix: ' (came through in a crisis)',
                  ),
                  const SizedBox(height: 8),
                  _BulletPlain(
                    'Closer checks your last 3 (rarely see) or 5 (often see) interactions',
                  ),
                  const SizedBox(height: 8),
                  _BulletPlain(
                    'Positive total → worth investing · Zero or below → time to reconsider',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section 5: Science ───────────────────────────────────────────
            Text(
              'The Science',
              style: GoogleFonts.caveat(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CrayonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _ScienceCard(
              seed: 51,
              title: 'Social Exchange Theory',
              body:
                  'Every relationship has a cost and a benefit. Closer makes yours visible.',
              citation: 'Thibaut & Kelley, 1959',
              url:
                  'https://www.simplypsychology.org/what-is-social-exchange-theory.html',
              onTap: _launch,
            ),
            const SizedBox(height: 8),
            _ScienceCard(
              seed: 52,
              title: 'Gottman\'s 5:1 Ratio',
              body:
                  'Thriving relationships have ~5 positive moments for every 1 negative. Your score reflects this balance.',
              citation: 'Dr. John Gottman',
              url:
                  'https://www.gottman.com/blog/the-magic-relationship-ratio-according-science/',
              onTap: _launch,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _LabelCard extends StatelessWidget {
  final int seed;
  final Color dotColor;
  final Color borderColor;
  final String label;
  final Color labelTextColor;
  final String description;

  const _LabelCard({
    required this.seed,
    required this.dotColor,
    required this.borderColor,
    required this.label,
    required this.labelTextColor,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return CrayonCard(
      seed: seed,
      fillColor: dotColor.withAlpha(30),
      strokeColor: borderColor.withAlpha(160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CrayonCircle(
            fillColor: dotColor.withAlpha(140),
            strokeColor: borderColor,
            size: 18,
            seed: seed,
            child: const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: labelTextColor,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    color: CrayonColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final String bold;
  final String boldSuffix;
  final String bold2;
  final String bold2Suffix;

  const _Bullet(this.text,
      {required this.bold,
      required this.boldSuffix,
      required this.bold2,
      required this.bold2Suffix});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: GoogleFonts.caveat(fontSize: 18, color: CrayonColors.textSecondary)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.caveat(fontSize: 17, color: CrayonColors.textPrimary),
              children: [
                TextSpan(text: text),
                TextSpan(
                    text: bold,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: boldSuffix),
                TextSpan(
                    text: bold2,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: bold2Suffix),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BulletPlain extends StatelessWidget {
  final String text;
  const _BulletPlain(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: GoogleFonts.caveat(fontSize: 18, color: CrayonColors.textSecondary)),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.caveat(fontSize: 17, color: CrayonColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _ScienceCard extends StatelessWidget {
  final int seed;
  final String title;
  final String body;
  final String citation;
  final String url;
  final Future<void> Function(String) onTap;

  const _ScienceCard({
    required this.seed,
    required this.title,
    required this.body,
    required this.citation,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(url),
      child: CrayonCard(
        seed: seed,
        fillColor: CrayonColors.surface,
        strokeColor: CrayonColors.strokeLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.caveat(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: CrayonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: GoogleFonts.caveat(fontSize: 17, color: CrayonColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              citation,
              style: GoogleFonts.caveat(
                fontSize: 15,
                color: CrayonColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Read more',
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    color: CrayonColors.responsiveLabelText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                PhosphorIcon(
                  PhosphorIconsThin.arrowRight,
                  size: 14,
                  color: CrayonColors.responsiveLabelText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
