import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mesa_colors.dart';

/// Tema único de la app. No hay variante clara: una mesa de paño verde
/// no la tiene, y mantener dos duplicaría el trabajo de diseño.
ThemeData mesaTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: MesaColors.doradoClaro,
    onPrimary: MesaColors.maderaBorde,
    primaryContainer: MesaColors.maderaClara,
    onPrimaryContainer: MesaColors.crema,
    secondary: MesaColors.dorado,
    onSecondary: MesaColors.maderaBorde,
    secondaryContainer: MesaColors.maderaOscura,
    onSecondaryContainer: MesaColors.crema,
    tertiary: MesaColors.panoLuz,
    onTertiary: MesaColors.crema,
    tertiaryContainer: MesaColors.panoBase,
    onTertiaryContainer: MesaColors.crema,
    error: MesaColors.brasa,
    onError: MesaColors.crema,
    surface: MesaColors.panoBase,
    onSurface: MesaColors.crema,
    surfaceContainerHighest: MesaColors.maderaOscura,
    onSurfaceVariant: MesaColors.crema,
    outline: MesaColors.maderaBorde,
    outlineVariant: MesaColors.dorado,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final sans = GoogleFonts.alegreyaSansTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: MesaColors.panoBase,
    textTheme: sans.copyWith(
      // Puntaje grande.
      displaySmall: GoogleFonts.alegreya(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: MesaColors.crema,
        height: 1,
      ),
      // Nombre del equipo o jugador.
      headlineMedium: GoogleFonts.alegreya(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: MesaColors.crema,
      ),
      // Título del header y de los diálogos.
      titleMedium: GoogleFonts.alegreyaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: MesaColors.crema,
      ),
      // Chips y botones.
      labelLarge: GoogleFonts.alegreyaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: MesaColors.crema,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: MesaColors.panoSombra,
      indicatorColor: MesaColors.maderaClara,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.alegreyaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: MesaColors.crema,
        ),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: MesaColors.doradoClaro),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: MesaColors.maderaOscura,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
