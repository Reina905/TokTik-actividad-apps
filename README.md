# TokTik - A Flutter Project

Clon sencillo de TikTok hecho con Flutter. Los usuarios pueden registrarse, subir videos y fotos (desde la galería o con la cámara y filtros), ver las publicaciones de todos en la pantalla de inicio y visitar el perfil de cada creador.

## Demo

 [Ver demo de TokTik en video](https://esenedusv-my.sharepoint.com/personal/20245517_esen_edu_sv/_layouts/15/stream.aspx?id=%2Fpersonal%2F20245517%5Fesen%5Fedu%5Fsv%2FDocuments%2FApps%20moviles%20%2D%20Trabajos%20grupales%2FDemo%20TokTik%2F1018%282%29%2Emp4&referrer=StreamWebApp%2EWeb&referrerScenario=AddressBarCopied%2Eview%2E3e6aa384%2D1944%2D4641%2Da9c0%2D3e72d8ca8d0d)

## Importante

### Los videos ya no se descargan ni se guardan en el repositorio

Las versiones anteriores del proyecto usaban 8 videos locales (`1.mp4` a `8.mp4`). **Ya no son necesarios.** Ahora los archivos se suben a **Cloudinary** y en **Firestore** solo se guarda la información de cada publicación (URL, descripción, autor, etc.), así que el repositorio no contiene ningún video.

### ¿Por qué Cloudinary y no Firebase Storage?

Usamos Cloudinary en lugar de Firebase Storage porque, a pesar de que Firebase Storage tiene un plan gratuito, activarlo exige registrar una tarjeta de crédito y datos de facturación. Cloudinary ofrece un plan gratuito que no los pide, y nos sirve igual para alojar los videos y las fotos.

### Archivos que NO están en el repositorio

Por seguridad, estos dos archivos con la configuración de Firebase no se suben a GitHub. Hay que pedírselos a alguien del equipo (por mensaje privado) o generarlos con acceso al proyecto de Firebase:

| Archivo | Dónde va |
|---|---|
| `firebase_options.dart` | `lib/firebase_options.dart` |
| `google-services.json` | `android/app/google-services.json` |

Para generarlos uno mismo: `flutterfire configure` (requiere tener acceso al proyecto de Firebase).

> No subas llaves, credenciales ni archivos `.env` al repositorio.

## Tecnologías

- **Flutter** y **Provider** (manejo de estado)
- **Firebase Authentication**: registro e inicio de sesión
- **Cloud Firestore**: información de las publicaciones
- **Cloudinary**: almacenamiento de videos y fotos
- **video_player**: reproducción de videos
- **image_picker**: selección de archivos de la galería
- **camera** y **Google ML Kit (face detection)**: cámara con filtros

## Funcionalidades

- Registro e inicio de sesión. La sesión se recuerda al volver a abrir la app.
- **Inicio:** desplazamiento vertical de videos y fotos de todos los usuarios.
- **Subida de contenido (botón +):** video desde la cámara con filtros, o video/foto desde la galería. Las publicaciones sin usuario se guardan como `anonimo`.
- **Perfil propio** y **perfil del creador**: al deslizar a la izquierda en una publicación se abre el perfil de su autor (no aplica a publicaciones anónimas).

## Estructura de datos (Firestore)

Colección `videos`. Cada documento tiene:

| Campo | Tipo | Descripción |
|---|---|---|
| `cloudinaryUrl` | string | URL del archivo en Cloudinary |
| `caption` | string | Descripción de la publicación |
| `userId` | string | uid de Firebase Auth del autor, o `anonimo` |
| `thumbnailUrl` | string | Miniatura (puede estar vacía) |
| `isVideo` | bool | `true` = video, `false` = foto |
| `likes` | number | Cantidad de likes |
| `views` | number | Cantidad de vistas |
| `createdAt` | timestamp | Fecha de creación |

## Cómo ejecutarlo

1. Clona el repositorio.
2. Agrega los dos archivos de configuración de Firebase (ver arriba).
3. Instala las dependencias y corre la app:

```bash
flutter pub get
flutter run
```

**Dispositivo recomendado:** un emulador o celular **Android**, o **Chrome** (`flutter run -d chrome`). El paquete `video_player` no reproduce video en Windows de escritorio.

## Estructura del proyecto

El código sigue una arquitectura por capas dentro de `lib/`:

```
lib/
├── config/            # Tema y utilidades
├── domain/            # Entidades y contratos
├── infrastructure/    # Datasources, repositorios y servicios (Firestore, Cloudinary)
├── presentation/      # Providers, pantallas y widgets
└── shared/            # Datos y recursos compartidos
```
