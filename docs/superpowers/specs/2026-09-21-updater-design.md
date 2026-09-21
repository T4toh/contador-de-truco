# Updater in-app — diseño

Fecha: 2026-09-21

## Problema

La app se distribuye como APK sideloaded desde GitHub Releases, firmado con un keystore
propio. No hay Play Store, así que no hay ningún mecanismo que le avise al usuario que salió
una versión nueva: hoy alguien con la `1.0.0+2` instalada se queda ahí para siempre salvo que
le pasen el APK a mano.

El objetivo es que la app detecte que hay una versión nueva publicada, la descargue y lance el
instalador de Android, sin salir de la app y sin depender de ninguna tienda.

## Alcance

Entra: chequeo de versión contra la API de GitHub, aviso no intrusivo, descarga con progreso,
verificación de integridad, lanzamiento del instalador, y el manejo del permiso de instalación.

No entra (ver [Trabajo posterior](#trabajo-posterior)): changelog en el banner, actualización
obligatoria, APKs por ABI. Descartado por completo: rollback a una versión anterior.

## Restricciones del proyecto

Cuatro cosas del estado actual condicionan el diseño:

1. **El release no tiene permiso `INTERNET`.** Flutter solo lo declara en los manifiestos de
   `debug` y `profile`. Esto ya rompió `google_fonts` en silencio una vez (ver `CLAUDE.md`).
   Hay que declararlo en `android/app/src/main/AndroidManifest.xml`.
2. **El `versionCode` sale de `pubspec.yaml`** (el número después del `+`). Hoy es
   `1.0.0+2`, y el último tag publicado es `v0.0.2`. No se pueden comparar.
3. **La firma es propia y manual.** Un APK firmado con otro keystore se rechaza con
   `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, y resolverlo implica desinstalar, lo que borra las
   partidas guardadas. El updater no puede detectar esto de antemano.
4. **No hay dependencias más allá de `shared_preferences` y `cupertino_icons`.** El diseño no
   agrega ninguna: todo sale de `dart:io`, `dart:convert` y un `MethodChannel` propio.

## Decisiones

| Decisión | Elegida | Por qué |
|---|---|---|
| Alcance del updater | Descargar e instalar dentro de la app | Pedido explícito. Avisar y abrir el navegador era más barato pero deja al usuario a mitad de camino. |
| Mecanismo de descarga | `DownloadManager` nativo de Android | Sobrevive a que se cierre la app y a cortes de red, reanuda, y no agrega dependencias. Descargar con `HttpClient` en Dart obligaba a escribir reintentos y reanudación a mano. |
| Plugin de terceros | No | `ota_update` y similares son paquetes chicos con un mantenedor al que hay que darle permiso de instalar APKs. El ahorro de código no paga la auditoría de supply-chain. |
| Frecuencia de chequeo | Al abrir, como mucho 1 vez cada 24 h | Chequear en cada arranque gasta datos y la API anónima de GitHub tiene un límite de 60 requests por hora por IP. Un botón manual no lo iba a tocar nadie. |
| Aviso de descarga completa | Consultar `DownloadManager` con un timer | Un `BroadcastReceiver` muere con la app, y desde Android 10 no puede lanzar el instalador estando en background. Consultar mientras el banner está visible y al volver a la app cubre los dos casos con un solo mecanismo, y de paso da la barra de progreso con el tema de la app. |

## Arquitectura

### Lado Dart

| Archivo | Responsabilidad | Depende de |
|---|---|---|
| `lib/update/update_info.dart` | Dato puro: `versionCode`, `versionName`, `apkUrl`, `sha256`. Parsea el JSON de la release. | nada |
| `lib/update/update_checker.dart` | Consulta la API, compara versiones, aplica el gate de 24 h. | `update_info.dart`, `shared_preferences`, `dart:io` |
| `lib/update/updater_channel.dart` | Wrapper del `MethodChannel`. | `services.dart` |
| `lib/widgets/update_banner.dart` | El aviso y la barra de progreso, con `MesaColors`. | los tres de arriba |

`UpdateChecker` no importa nada de `widgets`, igual que `ScoreGame`. Se testea sin
`WidgetTester`.

### Lado nativo

Un solo archivo Kotlin, `android/app/src/main/kotlin/io/github/t4toh/contadordetruco/UpdaterPlugin.kt`,
sobre el canal `io.github.t4toh.contadordetruco/updater`:

| Método | Devuelve | Notas |
|---|---|---|
| `currentVersionCode` | `int` | Vía `PackageManager`. Reemplaza a `package_info_plus`. |
| `canRequestInstall` | `bool` | `packageManager.canRequestPackageInstalls()`. |
| `openInstallSettings` | `void` | Intent `ACTION_MANAGE_UNKNOWN_APP_SOURCES` con el `applicationId`. |
| `enqueueDownload(url)` | `long` (downloadId) | `DownloadManager.Request` con destino en `getExternalFilesDir(DIRECTORY_DOWNLOADS)`, nombre fijo `update.apk`. |
| `queryDownload(id)` | `{status, bytesSoFar, bytesTotal}` | `DownloadManager.query()`. |
| `verifyAndInstall(id, sha256)` | `bool` | Calcula el SHA-256 del archivo en un hilo de fondo; si coincide lanza el intent de instalación, si no borra el archivo y devuelve `false`. |

El intent de instalación es `ACTION_VIEW` con `setDataAndType(uri, "application/vnd.android.package-archive")`
y los flags `FLAG_GRANT_READ_URI_PERMISSION` y `FLAG_ACTIVITY_NEW_TASK`, sobre una URI de
`FileProvider`.

### Manifest

En `android/app/src/main/AndroidManifest.xml`:

- `<uses-permission android:name="android.permission.INTERNET"/>`
- `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>`
- Un `<provider>` de `FileProvider` con autoridad `io.github.t4toh.contadordetruco.fileprovider`
  y `android/app/src/main/res/xml/filepaths.xml` exponiendo `<external-files-path>`.

## Flujo

1. `HomeScreen.initState` registra un `addPostFrameCallback`. El chequeo nunca corre en
   `main()`: ahí ya está la migración de `GameStorage`, y no queremos red bloqueando el arranque.
2. `UpdateChecker.check()` mira `update_last_check` en `SharedPreferences`. Si pasaron menos de
   24 h, corta ahí y no toca la red.
3. `GET https://api.github.com/repos/T4toh/contador-de-truco/releases/latest`. Del JSON salen
   `tag_name` y, del asset `.apk`, su `browser_download_url` y su campo `digest`
   (`"sha256:954c2b…"`, que la API ya expone).
4. Se parsea el build number del tag y se compara con `currentVersionCode`. Si no es mayor, no
   pasa nada. Se guarda el timestamp igual.
5. Si es mayor, aparece el `UpdateBanner` arriba del `IndexedStack` de `HomeScreen`. No es
   modal y no interrumpe una partida en curso.
6. Al tocar "Actualizar": si `canRequestInstall` es `false`, el botón manda a Ajustes con una
   explicación. Si es `true`, `enqueueDownload` y el banner pasa a modo progreso.
7. Un `Timer.periodic` de 1 s llama a `queryDownload` y actualiza la barra. El `downloadId`
   se guarda en `SharedPreferences` para poder retomar el estado si el usuario sale y vuelve.
8. Al llegar a `STATUS_SUCCESSFUL`, `verifyAndInstall`. A partir de ahí la pantalla es la del
   instalador de Android.

## Versionado

`pubspec.yaml` es la única fuente de verdad. Los tags pasan a tener el formato
`v<version>+<build>` — el próximo release es `v1.0.1+3`.

El updater parsea el número después del `+`. Los tags viejos (`v0.0.1`, `v0.0.2`) no parsean y
se ignoran, así que no hay que borrar ni renombrar nada: el primer release con el formato nuevo
es el que empieza a funcionar.

Se agrega un `release.sh` que lee la versión de `pubspec.yaml`, verifica que exista
`android/key.properties` antes de buildear, y arma el comando de `gh release create`.
**El script no publica solo**: imprime el comando para que lo corra una persona. Publicar un tag
es una acción que decide el usuario, no el agente.

## Manejo de errores

| Situación | Qué hace |
|---|---|
| Sin red, API caída, o rate limit de GitHub | Silencio. Se loguea y se reintenta al día siguiente. Nunca un diálogo de error al abrir la app. |
| El JSON no tiene asset `.apk`, o el tag no parsea | Se trata como "no hay update". |
| SHA-256 no coincide | Borra el archivo, el banner dice "La descarga se corrompió, probá de nuevo". **No instala.** |
| `canRequestPackageInstalls() == false` | El botón manda a Ajustes con una explicación. En los Xiaomi esto va a pasar la primera vez, siempre. |
| La descarga falla (`STATUS_FAILED`) | El banner ofrece reintentar. |
| El APK está firmado con otro keystore | Lo rechaza el instalador de Android; la app no puede preverlo. Queda documentado en `CLAUDE.md` junto al resto de las advertencias del keystore. |

## Tests

`flutter test`, sobre `UpdateChecker` con el JSON inyectado:

- Release con build mayor que el local → hay update.
- Release con build igual o menor → no hay update.
- Tag que no parsea (`v0.0.2`) → no hay update.
- JSON sin asset `.apk` → no hay update.
- Último chequeo hace menos de 24 h → no toca la red.
- Último chequeo hace más de 24 h → consulta y actualiza el timestamp.

El `MethodChannel` se moquea con `TestDefaultBinaryMessengerBinding.setMockMethodCallHandler`
para cubrir el flujo del banner: sin permiso de instalación, descarga exitosa, y SHA-256 que no
coincide.

El Kotlin queda sin tests. Montar el toolchain de tests instrumentados de Android para ~80
líneas no se paga; se verifica a mano en los dos Xiaomi.

## Trabajo posterior

Fuera de este spec, en orden de valor:

1. **APKs por ABI** (`--split-per-abi` en `build_apk.sh`). Baja el download de 48 MB a ~18-20 MB.
   Requiere que el updater elija el asset según la ABI del dispositivo, así que toca
   `UpdateInfo` y el `release.sh`. Reemplaza a la idea de "descarga delta", que fuera de Play
   Store es inviable: Play usa parches bsdiff vía Play Core, y un APK reconstruido tiene que
   quedar byte-idéntico o la firma no valida.
2. **Changelog en el banner.** El body de la release ya viene en el JSON; es UI, no lógica.
3. **Actualización obligatoria.** Un campo en la release que marque una versión como mínima y
   haga el banner bloqueante. Tiene sentido recién si alguna vez sale una versión que rompa el
   formato de persistencia.

Descartado: **rollback** a una versión anterior. Android no deja bajar el `versionCode` sin
desinstalar, y desinstalar borra las partidas.
