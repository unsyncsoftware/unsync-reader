import 'package:flutter/material.dart';

class AppTheme {
  // UnSync brand colors
  static const _primary = Color(0xFF6C63FF);
  static const _background = Color(0xFF1A1A2E);
  static const _surface = Color(0xFF16213E);
  static const _surfaceVariant = Color(0xFF0F3460);
  static const _onSurface = Color(0xFFE0E0E0);
  static const _onSurfaceMuted = Color(0xFF9E9E9E);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _primary,
          background: _background,
          surface: _surface,
          surfaceVariant: _surfaceVariant,
          onSurface: _onSurface,
          onBackground: _onSurface,
        ),
        scaffoldBackgroundColor: _background,
        appBarTheme: const AppBarTheme(
          backgroundColor: _surface,
          foregroundColor: _onSurface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: _surface,
        ),
        iconTheme: const IconThemeData(
          color: _onSurfaceMuted,
          size: 20,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: _onSurface),
          bodySmall: TextStyle(color: _onSurfaceMuted),
          labelMedium: TextStyle(color: _onSurfaceMuted, fontSize: 11),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2A2A4A),
          thickness: 1,
        ),
        tooltipTheme: const TooltipThemeData(
          decoration: BoxDecoration(
            color: _surfaceVariant,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          textStyle: TextStyle(color: _onSurface, fontSize: 12),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: _primary,
        ),
      );
}
