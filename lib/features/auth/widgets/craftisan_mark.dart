import 'package:flutter/material.dart';

class CraftisanMark extends StatelessWidget {
  const CraftisanMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/branding/craftisan_bag_icon.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    semanticLabel: 'Craftisan shopping bag logo',
  );
}
