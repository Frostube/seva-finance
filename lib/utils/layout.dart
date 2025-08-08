import 'package:flutter/widgets.dart';

class LayoutUtils {
  static double responsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 48; // desktop
    if (width >= 900) return 40; // large tablet
    if (width >= 600) return 32; // tablet
    return 24; // phones
  }

  static EdgeInsets pagePadding(BuildContext context, {double? top, double? bottom}) {
    final h = responsiveHorizontalPadding(context);
    return EdgeInsets.fromLTRB(h, top ?? 24, h, bottom ?? 24);
  }

  static double responsiveSectionSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) return 24;
    if (width >= 600) return 20;
    return 16;
  }
}


