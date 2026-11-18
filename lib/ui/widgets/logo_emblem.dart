import 'package:material_ui/material_ui.dart';

class SwaraGuruLogoEmblem extends StatelessWidget {
  const SwaraGuruLogoEmblem({
    super.key,
    this.size = 56,
    this.showTitle = false,
  });

  final double size;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/images/swaraguru_emblem.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
