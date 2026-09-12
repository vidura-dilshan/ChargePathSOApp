import 'package:flutter/material.dart';
import 'package:chargepathso/Widgets/responsive_breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet =
            constraints.maxWidth >= ResponsiveBreakpoints.tabletWidth;

        if (isTablet) {
          return tablet;
        }

        return mobile;
      },
    );
  }
}