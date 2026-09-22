# Changelog

Todos los cambios notables de Pulpero, del más nuevo al más viejo. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es/1.1.0/) y las versiones,
[SemVer](https://semver.org/lang/es/).

## [1.1.1] - 2026-09-22

### Arreglado
- Las Novedades también se abren al actualizar desde la 1.0.2 o anteriores, que no guardaban la
  versión vista.

## [1.1.0] - 2026-09-22

### Agregado
- Novedades en la app: tocá la versión en el setup para ver este changelog. También se abre solo
  la primera vez que arranca una versión nueva.
- **Generala**, tercer juego: planilla de 11 casillas para 2 a 6 jugadores, puntaje según el
  reglamento de Ruibal. Tocá una celda y elegí el valor entre los válidos; caras de dado y
  E, F, P, G, G2 como en la planilla de papel. Generala servida gana la partida. Empate
  compartido.
- Ícono propio: el pulpero lustrando el ancho de espadas.
- Reglas de Truco en `docs/truco.md`.

### Cambiado
- La app se llama **Pulpero**. El repo pasó a `T4toh/pulpero`; las instalaciones viejas siguen
  encontrando las actualizaciones.
- Generala doble (G2) vale 100; no está en el PDF del reglamento pero sí en la planilla de la caja.

### Arreglado
- La barra de gestos de Android ya no queda gris: el paño llega hasta abajo.
- Rendimiento: el paño se dibuja como textura repetida. En tablets de gama baja cada frame
  tardaba ~40 ms; ahora ~6 ms. Afecta a los tres juegos.
- Renombrar no toca la pantalla si se cerró mientras el diálogo estaba abierto.

## [1.0.2] - 2026-09-21

### Agregado
- La versión instalada se muestra abajo a la derecha en el setup.

### Arreglado
- Updater: notificación al terminar la descarga, fase "listo" con botón Instalar, sin doble
  descarga al tocar dos veces.
- `release.sh` valida `gh auth`, el tag y el `versionCode` publicado antes de buildear.

## [1.0.1] - 2026-09-21

### Agregado
- **Actualización desde la app**: detecta una release nueva en GitHub, la descarga, verifica el
  SHA-256 y lanza el instalador. Sin Play Store.
- Rediseño **Mesa**: paño verde, paneles de madera, fósforos con volumen y tipografía Alegreya
  empaquetada.
- Truco agrupa los fósforos de a tres por columna: una columna llena son las malas o las buenas.
- Los nombres puestos por el usuario sobreviven a una partida nueva.

### Cambiado
- Truco y Escoba pasan a ser entradas de un catálogo con un modelo de contador compartido.
- Persistencia unificada con migración de los esquemas anteriores.
- Identificador de la app: `io.github.t4toh.contadordetruco`.

### Arreglado
- Fósforos recortados en pantallas chicas y en landscape.
- Escoba a 4 jugadores en landscape de teléfono.
- La app abre aunque falle la migración de datos guardados.

## [0.0.2] - 2026-03-19

### Agregado
- **Escoba del 15**, con navegación por pestañas.

### Arreglado
- Fósforos recortados en el panel.

## [0.0.1] - 2025-11-11

### Agregado
- Contador de Truco: partidas a 15 (malas) o a 30 (buenas), dos equipos, puntos dibujados como
  fósforos.

[1.1.1]: https://github.com/T4toh/pulpero/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/T4toh/pulpero/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/T4toh/pulpero/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/T4toh/pulpero/compare/v0.0.2...v1.0.1
[0.0.2]: https://github.com/T4toh/pulpero/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/T4toh/pulpero/releases/tag/v0.0.1
