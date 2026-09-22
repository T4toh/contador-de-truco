# Generala — diseño

Fecha: 2026-09-21

## Problema

Generala es el tercer juego de la app y el primero que no es un "contador de puntos": cada
jugador llena una planilla de 10 casillas, una por vuelta, y gana el mayor total al final.
`GameSpec` y `ScoreGame` modelan "un entero por participante con tope" y el spec del rediseño de
mesa la dejó explícitamente afuera de esa abstracción. Hace falta un modelo y una pantalla
propios que convivan con los otros dos juegos en la misma navegación.

## Reglas

Se implementa el **reglamento de Ruibal** (el que viene en la caja del juego), tal cual:
<https://ruibalgames.com/wp-content/uploads/2015/11/Reglamento-Generala.pdf>. La marca se cita en
`docs/generala.md`, en el README y en una línea chica del setup de la app, para que no haya
malentendidos con otras variantes (Yahtzee, doble generala, bonus de 63).

- **10 casillas**: 1, 2, 3, 4, 5, 6, Escalera, Full, Póker, Generala. 10 vueltas.
- **Números**: cantidad de dados con ese número × el número. Cinco 6 = 30.
- **Escalera** 20, **Full** 30, **Póker** 40. **Servidos** (en el primer tiro) suman 5.
- **Generala** 60. **Generala servida gana la partida** en el acto, aunque el jugador ya tenga
  puntaje en ese número.
- Una casilla se anota una sola vez. Tachar es cero.
- Gana el mayor total. El reglamento no habla de empates: la app lo muestra como **empate**
  entre los jugadores con el total máximo, sin ganador.
- **2 a 6 jugadores**, decisión de la app, el reglamento no fija cantidad.

## Alcance

Entra: modelo de planilla, persistencia de la partida en curso, pantalla con tabla, carga de
celdas por fichas, fin de partida, docs al canon Ruibal.

No entra: tirador de dados, cálculo automático desde los dados, historial de partidas,
estadísticas, variantes de reglas configurables.

## Arquitectura

### Catálogo de pestañas

`catalogo` en `lib/games/catalog.dart` pasa de `List<GameSpec>` a `List<Juego>`:

```dart
class Juego {
  final String titulo;
  final IconData icono;
  final Widget Function(String? version) pantalla;
}
```

Truco y Escoba se envuelven con un helper `Juego.contador(GameSpec)` que construye
`CounterScreen`. Generala es una entrada más que construye `GeneralaScreen`. `HomeScreen`
itera `catalogo` igual que hoy, con `IndexedStack` y `NavigationBar`. Se mantiene la
convención "un juego = una entrada del catálogo".

Descartadas: generalizar `GameSpec`/`ScoreGame` para celdas (rompe algo que funciona para un
caso que no se parece) y hardcodear la pestaña en `HomeScreen` (rompe la convención).

### Modelo — `lib/generala/`

Sin dependencia de widgets, se testea directo.

**`reglas.dart`**

```dart
enum Casilla { uno, dos, tres, cuatro, cinco, seis, escalera, full, poker, generala }

class Jugada {
  final int valor;
  final String etiqueta;   // '16', '25 servida', 'Servida, gana'
  final bool ganaPartida;  // solo la generala servida
}
```

`Casilla.etiqueta` ('Cuatros', 'Escalera'), `Casilla.etiquetaCorta` ('4', 'Esc.') y
`Casilla.opciones`: la lista de `Jugada` válidas, siempre empezando por tachar (valor 0,
etiqueta '✕'). Es la única tabla de reglas; el comentario cita el reglamento Ruibal.

| Casilla | Opciones |
| --- | --- |
| 1 al 6 | ✕, n×1, n×2, n×3, n×4, n×5 |
| Escalera | ✕, 20, 25 servida |
| Full | ✕, 30, 35 servida |
| Póker | ✕, 40, 45 servida |
| Generala | ✕, 60, 60 servida (`ganaPartida`) |

**`generala_game.dart`**

```dart
class GeneralaGame {
  List<String> nombres;
  List<List<int?>> planilla;   // [jugador][casilla]; null = vacía, 0 = tachada
  bool empezada;
  bool terminada;
  List<int> ganadores;         // índices; vacía si no terminó, varios si empate
}
```

- `empezar(participantes)`: como `ScoreGame.empezar`, conserva nombres ya puestos.
- `anotar(jugador, casilla, jugada)`: escribe `jugada.valor`. Si `jugada.ganaPartida`,
  `terminada = true`, `ganadores = [jugador]`. Si con esa anotación la planilla queda completa,
  `terminada = true` y `ganadores` = los índices con total máximo.
- `borrar(jugador, casilla)`: vuelve a null. No se puede si `terminada`.
- `total(jugador)`: suma de no nulos.
- `vuelta`: mínimo de casillas cargadas entre los jugadores + 1, clampeado a 10.
- `renombrar`, `reiniciar` (vacía la planilla, conserva nombres, `empezada = false`).
- `toJson` / `fromJson`.

Los nombres por defecto y cortos son los de Escoba extendidos a 6: `Jugador 1..6` y `J#1..6`.

### Persistencia

Un solo JSON en `SharedPreferences` bajo la clave `generala_partida`, escrito con `jsonEncode`
de `GeneralaGame.toJson()`. Sin tocar `GameStorage` ni `schema_version`: la forma es distinta
y no hay nada guardado que migrar. Si el JSON no parsea, se arranca una partida nueva y se
loguea con `debugPrint`, misma política que la migración: nunca una pantalla en blanco.

Se guarda después de cada mutación, igual que `CounterScreen`.

### Pantalla — `lib/generala/generala_screen.dart`

`StatefulWidget` dueño del `GeneralaGame`, misma estructura que `CounterScreen`.

**Setup.** "¿Cuántos jugadores?" con botones 2 a 6, mismo aspecto que el setup de Escoba.
Debajo del título, en `bodySmall` atenuado: "Puntaje según reglamento Ruibal". Para no
duplicar, el `_elegir` privado de `CounterScreen` se extrae a `lib/widgets/setup_choice.dart`
(`SetupChoice`) y lo usan las dos pantallas. Es el único cambio a `CounterScreen`.

**Partida.** `FeltBackground` + `SafeArea` + `Column`:

- `GameHeader` reutilizado. Título "Vuelta N de 10". Reinicio con la confirmación que ya trae.
- `Expanded` con un `WoodPanel` que contiene la tabla:
  - Cabecera: celda vacía + un nombre por jugador. Long-press en el nombre renombra con
    `mostrarNameDialog`. Con ancho por columna menor a un umbral (mismo criterio que
    `ScorePanel`, constante propia), se muestra el nombre corto `J#n` mientras siga siendo el
    de fábrica.
  - 10 filas: etiqueta de la casilla a la izquierda (corta si el ancho no da) + una celda por
    jugador. Vacía: punto atenuado. Tachada: ✕ en `MesaColors.brasa`. Servida: valor en
    `MesaColors.doradoClaro`. Normal: valor en crema.
  - Fila de total, separada con una línea dorada, en `titleMedium`.
  - Filas con `Expanded`, para que las 12 filas llenen el alto disponible sin scroll. En
    landscape queda apretado pero legible; no se optimiza.
- Sin resaltar "a quién le toca": el orden de la mesa lo llevan los jugadores.

**Carga.** Tocar una celda abre `showModalBottomSheet` con `JugadaSheet`
(`lib/generala/jugada_sheet.dart`): título con la casilla y el nombre del jugador, y una fila
de fichas `FilledButton.tonal` con `Casilla.opciones`. Tachar en `brasa`, servida en `dorado`.
Si la celda ya tenía valor, se agrega una ficha "Borrar" al final. Elegir una ficha cierra el
sheet y anota. Con `terminada`, tocar celdas no hace nada.

**Fin.** Al quedar `terminada`, `WinnerBottomSheet` no dismissible, como en `CounterScreen`.
Se le agrega un parámetro opcional `titulo`; por defecto sigue siendo `'¡GANÓ $winnerName!'`.
Con un ganador: por defecto. Con empate: `titulo: '¡EMPATE!'` y `winnerName` con los nombres
unidos ("Tato y Flor"). "Nueva partida" vuelve al setup.

### Manejo de errores

- JSON guardado inválido: partida nueva + `debugPrint`.
- Cantidad de jugadores persistida fuera de 2..6: se clampea, igual que hace `GameStorage.cargar`.
- Anotar sobre una celda con `terminada`: no-op en el modelo, la UI tampoco abre el sheet.

## Tests

- `test/generala_reglas_test.dart`: cada casilla da las opciones de la tabla; solo la generala
  servida tiene `ganaPartida`; toda lista empieza con tachar.
- `test/generala_game_test.dart`: anotar y total; `vuelta` avanza con el mínimo; completar la
  planilla termina y elige el máximo; empate devuelve varios; generala servida termina en el
  acto con un solo ganador; `borrar` no anda con `terminada`; JSON ida y vuelta preserva todo;
  `fromJson` con basura devuelve null.
- `test/generala_screen_test.dart`: setup elige 3 jugadores; tocar una celda abre el sheet;
  elegir "16" en Cuatros muestra 16 en la celda y en el total; long-press renombra.
- Los tests de `CounterScreen` existentes siguen en verde después de extraer `SetupChoice`.

## Docs

- `docs/generala.md` reescrito al reglamento Ruibal: 10 casillas, valores, servida, generala
  servida gana, sin doble ni bonus, con el link al PDF y la aclaración de marca. Empate y 2 a 6
  jugadores marcados como decisión de la app.
- README: Generala pasa a ✅ en la tabla de juegos, con "reglamento Ruibal" en el detalle; se
  saca de pendientes.
- `CLAUDE.md`: el catálogo ahora es de `Juego`, y Generala vive en `lib/generala/` con su propia
  persistencia.

## Riesgos

| Riesgo | Mitigación |
| --- | --- |
| Con 6 jugadores en portrait las celdas quedan muy angostas | Etiquetas cortas de casilla y `J#n`. Si aun así no alcanza, landscape; medir en dispositivo antes de cerrar. |
| Alguien juega otra variante y la app "está mal" | Atribución a Ruibal visible en el setup y en los docs. |
| `Casilla.opciones` como `List` recalculada en cada build | Diez listas chicas; si molesta, `static final` por casilla. |

## Orden sugerido

1. `reglas.dart` + tests.
2. `GeneralaGame` + JSON + tests.
3. `Juego` en el catálogo y `HomeScreen`; extraer `SetupChoice`.
4. `GeneralaScreen` con tabla y `JugadaSheet`; `WinnerBottomSheet.titulo`.
5. Widget test.
6. Docs y README.
7. Repaso visual en el teléfono con 2, 4 y 6 jugadores.

## Cambios posteriores

- 2026-09-21: Etiquetas de la planilla: caras de dado y E/F/P/G/G2, pedido del usuario al probar
  en el teléfono.
- 2026-09-21: Casilla Generala doble (100, servida gana), 11 casillas: está en la planilla
  impresa de Ruibal aunque no en el PDF.
