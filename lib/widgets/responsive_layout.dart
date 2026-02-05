// lib/widgets/responsive_layout.dart
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;

  const ResponsiveLayout({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, constraints);
      },
    );
  }
}

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double mobilePadding;
  final double? tabletPadding;
  final double? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding = 16.0,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, constraints) {
        double padding = mobilePadding;

        if (constraints.maxWidth >= 1200 && desktopPadding != null) {
          padding = desktopPadding!;
        } else if (constraints.maxWidth >= 600 && tabletPadding != null) {
          padding = tabletPadding!;
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: child,
        );
      },
    );
  }
}

class ResponsiveValue<T> extends StatelessWidget {
  final T mobileValue;
  final T? tabletValue;
  final T? desktopValue;
  final Widget Function(T value) builder;

  const ResponsiveValue({
    super.key,
    required this.mobileValue,
    this.tabletValue,
    this.desktopValue,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, constraints) {
        T value = mobileValue;

        if (constraints.maxWidth >= 1200 && desktopValue != null) {
          value = desktopValue!;
        } else if (constraints.maxWidth >= 600 && tabletValue != null) {
          value = tabletValue!;
        }

        return builder(value);
      },
    );
  }
}