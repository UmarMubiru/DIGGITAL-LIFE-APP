import 'package:flutter/material.dart';

class AppBrand extends StatelessWidget {
  final double logoSize;
  final TextStyle? textStyle;
  final MainAxisAlignment alignment;

  const AppBrand.centered({super.key, this.logoSize = 72, this.textStyle})
      : alignment = MainAxisAlignment.center;

  const AppBrand.compact({super.key, this.logoSize = 28, this.textStyle})
      : alignment = MainAxisAlignment.center;

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? const TextStyle(
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Try to load an asset logo; fallback to FlutterLogo if missing.
        Image.asset(
          'assets/logo.jpg',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => FlutterLogo(size: logoSize),
        ),
        const SizedBox(height: 4),
        Text('DigiCare', style: style.copyWith(fontSize: logoSize * 0.45)),
      ],
    );
  }
}


