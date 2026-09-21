import 'package:flutter/material.dart';

import 'mesa_colors.dart';

/// Familias empaquetadas. Los nombres tienen que coincidir exactamente con
/// los `family:` de la sección `fonts:` de pubspec.yaml.
const _serif = 'Alegreya';
const _sans = 'Alegreya Sans';

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
  // Familias empaquetadas en pubspec.yaml, no bajadas en runtime: ver el
  // comentario de la sección `fonts:` de ahí.
  final sans = base.textTheme.apply(fontFamily: _sans);

  return base.copyWith(
    scaffoldBackgroundColor: MesaColors.panoBase,
    // Ripple clásico en vez del InkSparkle de Material 3: el sparkle pinta
    // con un fragment shader (`shaders/ink_sparkle.frag`) que el runner de
    // `flutter test` no puede compilar —el asset del SDK trae solo stages
    // Vulkan y el runner usa SkSL—, así que cualquier toque en un botón
    // tiraba una excepción en los tests. Además el destello no aporta nada
    // sobre la madera.
    splashFactory: InkRipple.splashFactory,
    textTheme: sans.copyWith(
      // Puntaje grande.
      displaySmall: const TextStyle(
        fontFamily: _serif,
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: MesaColors.crema,
        height: 1,
      ),
      // Nombre del equipo o jugador.
      headlineMedium: const TextStyle(
        fontFamily: _serif,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: MesaColors.crema,
      ),
      // Título del header y de los diálogos.
      titleMedium: const TextStyle(
        fontFamily: _sans,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: MesaColors.crema,
      ),
      // Chips y botones.
      labelLarge: const TextStyle(
        fontFamily: _sans,
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
        const TextStyle(
          fontFamily: _sans,
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
