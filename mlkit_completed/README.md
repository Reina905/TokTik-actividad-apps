# Clase 24 · ML Kit — texto, imagen, rostros y filtros faciales

App de ejemplo para la Clase 24 (Semana 8, Desarrollo de Aplicaciones
Móviles). Tiene dos pantallas:

## 1. ML Kit básico (`lib/mlkit_basico_screen.dart`)

Los tres reconocedores del guion de la clase, siguiendo el patrón InputImage
→ procesador → resultado tal como lo presenta el libro de referencia
(Flutter Cookbook, Cap. 14):

- **TextRecognizer** — reconocimiento de texto (OCR).
- **ImageLabeler** — etiquetado de imagen, con `confidenceThreshold: 0.7`.
- **FaceDetector** — conteo de rostros, con `performanceMode: accurate`,
  `enableLandmarks: true` y `enableClassification: true` (probabilidad de
  sonrisa y de ojos abiertos).

Los tres procesadores se declaran como campos y se inicializan una sola vez
en `initState()`, se cierran en `dispose()`, y cada llamada a
`processImage()` está protegida con una bandera `_isProcessing` y el guard
`if (!mounted) return` — exactamente las buenas prácticas que pide la
Sección 5 del guion (criterios de desempeño) y el banco de repaso
(preguntas 16 y 55).

Evidencia mínima de la clase: con esta pantalla sola ya se cumple "al menos
dos de los tres reconocedores funcionando sobre una imagen propia".

## 2. Filtros faciales (`lib/filtros_faciales_screen.dart`)

La pieza que pediste además del guion: un filtro estilo "lentes y bigote"
construido sobre los **landmarks** de `FaceDetector` — los mismos puntos
(ojos, nariz, boca) que el guion menciona solo "a nivel de panorama" y que
se profundizan recién en la Clase 29. Esta pantalla es el adelanto
concreto de para qué sirven.

Cómo funciona, paso a paso:

1. Se detectan los rostros con `FaceDetector(enableLandmarks: true)`.
2. Para los **lentes**: se toman los landmarks `leftEye` y `rightEye`. El
   punto medio entre ambos es el centro del overlay, la distancia entre
   ellos define el ancho (lentes más grandes si la cara está más cerca de
   la cámara) y el ángulo entre los dos ojos define la rotación (la
   cabeza inclinada inclina también los lentes).
3. Para el **bigote**: se usan `leftMouth` y `rightMouth` (comisuras de la
   boca) para el ancho, el ángulo y el centro horizontal; `noseBase` (o, si
   no está disponible, una estimación a partir de la boca) ubica el centro
   vertical entre la nariz y el labio superior.
4. Todo el dibujo ocurre en un `CustomPainter` (`FiltrosFacialesPainter`)
   que escala el canvas una sola vez a `size.width / image.width` y
   después dibuja la imagen de base y los overlays usando directamente las
   coordenadas de píxel que devolvió ML Kit — así ambos comparten siempre
   el mismo sistema de referencia, sin cálculos de conversión por overlay.
5. Si a un rostro le falta algún landmark (por ejemplo, está de perfil o
   parcialmente tapado), ese filtro simplemente no se dibuja para ese
   rostro — la pantalla lo informa en el mensaje de estado, un punto de
   discusión útil en clase sobre los límites de la detección.
6. Dos `SwitchListTile` permiten activar/desactivar lentes y bigote por
   separado sin volver a correr la detección.

Los overlays (`assets/filtros/glasses.png` y `assets/filtros/bigote.png`)
son ilustraciones simples generadas para este ejercicio (no provienen de
ningún banco de imágenes con derechos reservados), pensadas para que el
efecto se note con claridad en clase; se pueden reemplazar por cualquier
PNG con fondo transparente sin tocar el código, siempre que se mantenga la
misma ruta en `pubspec.yaml`.

## 3. Filtros en vivo (`lib/filtros_en_vivo_screen.dart`)

Los mismos lentes y bigote, pero sobre el video de la cámara (paquete
`camera`). La geometría es idéntica: ambas pantallas llaman a
`pintarFiltrosEnRostro()` (en `filtros_faciales_screen.dart`). Lo que cambia:

1. **De dónde sale el InputImage:** cada frame llega como `CameraImage`
   (bytes NV21 en Android) y se convierte con `InputImage.fromBytes`,
   indicando tamaño, formato, `bytesPerRow` y la **rotación del sensor**.
2. **Descartar frames:** la cámara entrega ~30 frames/s; si ML Kit sigue
   ocupado, el frame nuevo se ignora (`_isProcessing`).
3. **Modo `fast`** en lugar de `accurate`: en video importa la latencia.
4. **Coordenadas:** ML Kit responde en píxeles del frame ya rotado a
   vertical; el painter escala el canvas a la vista previa y, con la cámara
   frontal, lo refleja en X porque la vista previa se muestra como espejo.
5. La pantalla se fija en vertical para que la rotación sea siempre la del
   sensor; el botón de la barra superior cambia entre cámara frontal y
   trasera.

## Qué mostrar en clase

1. Pantalla "ML Kit básico": reconocer texto de una foto de un letrero o
   de un libro, etiquetar una foto cualquiera, y detectar rostros con
   probabilidad de sonrisa/ojos abiertos.
2. Pantalla "Filtros faciales": tomar o elegir una selfie, mostrar lentes y
   bigote colocados automáticamente, apagar y encender cada filtro, y
   preguntar: ¿qué pasaría si la persona estuviera de perfil? (probarlo en
   vivo si alguien se anima).
3. Cierre: relacionar esto con `enableClassification` y la idea de que
   ML Kit puede entregar no solo "dónde está la cara" sino "qué forma
   tiene la cara" — la puerta hacia la Clase 29.

## Cómo configurarla y correrla

Esta app **sí necesita el SDK de Flutter** pero **no necesita ningún
servicio en la nube** (a diferencia de la Clase 23): todo el
procesamiento de ML Kit corre on-device.

```bash
flutter create . --project-name clase24_mlkit_demo
# o, si ya tienes un proyecto Flutter vacío:
#   cp -r <esta_carpeta>/lib .
#   cp -r <esta_carpeta>/assets .
#   cp <esta_carpeta>/pubspec.yaml .
flutter pub get
flutter analyze
flutter run
```

Permisos de cámara/galería: `image_picker` ya gestiona el permiso en
tiempo de ejecución en Android e iOS, pero conviene declarar el uso de
cámara en `ios/Runner/Info.plist` (`NSCameraUsageDescription`,
`NSPhotoLibraryUsageDescription`) antes de probar en un iPhone real —
`flutter create` genera `Info.plist` sin estas claves por defecto.

**Importante:** este código no pudo compilarse ni ejecutarse en el entorno
donde se generó (no hay SDK de Flutter/Dart disponible aquí). Se revisó a
mano con cuidado — cada llamada a ML Kit (`TextRecognizer`, `ImageLabeler`,
`FaceDetector`, los `FaceLandmarkType` usados) se verificó contra el
capítulo del libro de referencia y la documentación de
`google_mlkit_face_detection` — pero conviene correr `flutter analyze` y
`flutter run` con un dispositivo o emulador real antes de usarla en clase.
Si `flutter pub get` no resuelve exactamente las versiones fijadas en
`pubspec.yaml` (los paquetes de ML Kit actualizan seguido), sube los
números de versión a los que te proponga; la API usada aquí es estable
desde hace varias versiones.

Referencia bibliográfica: Alessandria, Yovo y Anwar, *Flutter Cookbook,
Third Edition* (Packt Publishing, 2026), Capítulo 14, "Adding Machine
Learning to Your Apps with ML Kit" — secciones "Implementing Text, Image,
and Face Recognition" y "Using and Customizing ML Kit Models" (de donde
salen `enableLandmarks` y `enableClassification`).
