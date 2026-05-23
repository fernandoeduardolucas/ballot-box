import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  // Helper methods para poderes usar noutros locais do código (ex: para desligar animações)
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 850;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 850;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Se a largura for maior ou igual a 850 pixéis, renderiza a versão Web (TopBar)
        if (constraints.maxWidth >= 850) {
          return desktop;
        }
        // Caso contrário, renderiza a versão Mobile (BottomNavigationBar)
        else {
          return mobile;
        }
      },
    );
  }
}