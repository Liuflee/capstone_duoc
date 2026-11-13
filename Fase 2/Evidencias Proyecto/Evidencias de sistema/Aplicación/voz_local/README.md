# Voz e interpretación dentro del dispositivo

La aplicación utiliza **Whisper Tiny multilingüe** para transcribir español y
**paraphrase-multilingual-MiniLM-L12-v2, ONNX int8** para clasificar preguntas.
Ambos se ejecutan dentro del teléfono o computador. La app ya no llama al
servidor Python ni necesita configurar `WHISPER_URL`.

## Uso en Android

1. Instala la APK e inicia sesión con una cuenta de Supabase.
2. Abre **Consultas por voz** desde el menú lateral.
3. Pulsa **Descargar IA en este dispositivo**. Se descargan aproximadamente
   205 MB; usa Wi-Fi y deja espacio adicional para los archivos temporales.
4. Permite el micrófono. Pulsa **Hablar**, formula una sola pregunta y pulsa
   **Detener y transcribir**. El máximo es 30 segundos.
5. Revisa el texto, especialmente códigos, y pulsa **Consultar**.

Tras preparar los modelos, la transcripción y la clasificación no necesitan
internet. La lectura de la base de datos **sí requiere conexión a Supabase** y
una sesión válida. No se necesita mantener encendido otro computador, configurar
una red local ni pagar una API de IA.

## Consultas y límites

| Categoría | Ejemplo |
| --- | --- |
| Stock bajo | ¿Qué repuestos están por acabarse? |
| Producto por código | Necesito saber cuánto queda del código ABC-123 |
| Ventas por período | ¿Cuánto llevamos vendido este mes? |

El stock bajo corresponde a **5 unidades o menos** y muestra hasta 50 productos,
con aviso si hay más. Los códigos se consultan por coincidencia exacta: no se
adivinan letras o ceros que Whisper haya reconocido incorrectamente.

Ventas admite **hoy, ayer, esta semana y este mes**. Semana comienza el lunes.
Los períodos usan la zona horaria del dispositivo; configura America/Santiago
en los equipos del taller. Se excluyen ventas sin fecha y pendientes locales.
Los importes se calculan con los detalles de venta visibles según RLS.

MiniLM compara el significado con 54 ejemplos del dominio. Se abstiene si la
similitud es baja o dos categorías quedan próximas. Las puntuaciones **no son
porcentajes de certeza**. La extracción de parámetros exige códigos y períodos
admitidos; si faltan, pide aclaración. No mantiene conversación entre preguntas.
Los umbrales iniciales requieren evaluación adicional con habla y ruido reales.

## Privacidad y recursos

- Los modelos se descargan desde revisiones fijas de sus repositorios oficiales
  por HTTPS; se verifican tamaño y SHA-256 antes de utilizarlos.
- El audio no se envía al servidor Python ni a un proveedor de IA. Se escribe
  un WAV temporal privado para la inferencia y se elimina al terminar. Si el
  sistema mata el proceso durante la inferencia, puede quedar en la caché
  temporal de la aplicación hasta su limpieza por el sistema.
- La transcripción y la pregunta se procesan en el propio dispositivo.
- Solo se hacen consultas de lectura mediante la sesión de Supabase y RLS.
- Se limitan los motores a dos hilos y la entrada de MiniLM a 128 tokens.
  Whisper libera su modelo al terminar; MiniLM se libera al salir de la pantalla.
- El rendimiento y la memoria dependen del teléfono; Tiny prioriza recursos
  frente a la precisión de modelos Whisper más grandes.
- Plataformas nativas: Android 7/API 24 o posterior; configuración iOS 16 o
  posterior. Para compilar/probar iOS hace falta un Mac con Xcode. Esta ruta
  de inferencia no está preparada para Flutter web.

## Compilar

Con Flutter, Java y el SDK de Android configurados, desde `Aplicación`:

```powershell
flutter pub get
flutter build apk --debug --dart-define-from-file=supabase.config.json
```

La APK de prueba queda en `build/app/outputs/flutter-apk/app-debug.apk`.
Para una APK optimizada de 64 bits desde Windows, evitando el problema del
compilador con rutas que contienen acentos:

```powershell
powershell -ExecutionPolicy Bypass -File .\voz_local\compilar_android.ps1
```

El script usa una copia de fuentes en `.compilacion_android/`, ignorada por Git,
y copia la APK resultante a `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
Las compilaciones de distribución necesitan la firma propia del proyecto.
Whisper requiere el NDK fijado en `android/app/build.gradle.kts`; Gradle puede
descargarlo si las licencias del SDK están aceptadas.

## Mantener modelos y ejemplos

Los pesos no se incluyen en Git ni en la APK. El manifiesto está en
`assets/ia/modelos.json`; los ejemplos y sus vectores normalizados, en la misma
carpeta. Para regenerarlos con el mismo proceso que produce las pruebas de
paridad, instala las dependencias Python y ejecuta:

```powershell
Push-Location voz_local
.\.venv\Scripts\python.exe preparar_movil.py
Pop-Location
```

El script descarga los originales a `.modelos_ia/` (ignorado por Git), fija sus
revisiones/hashes y genera los vectores con mean pooling y normalización L2.
Revisa los cambios de manifiesto y evalúa frases nuevas antes de distribuirlos.
Cambiar modelo, tokenizador o ejemplos requiere regenerar los vectores.

```powershell
flutter test test/asistente_test.dart test/clasificacion_local_test.dart
flutter test integration_test/ia_local_test.dart -d windows --dart-define=IA_RAIZ_MODELOS=RUTA_ABSOLUTA_MODELOS --dart-define=IA_AUDIO_PRUEBA=RUTA_WAV_ESPANOL
```

Las pruebas de tokenización comparan Dart con HuggingFace en español, códigos y
Unicode. Las pruebas nativas utilizan los pesos reales. Debe completarse la
validación de calidad, micrófono y consumo con el teléfono de destino.

`servidor.py` e `iniciar.ps1` se conservan como herramientas del prototipo anterior;
la aplicación actual no los usa.

Referencias: https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2,
https://huggingface.co/ggerganov/whisper.cpp, https://pub.dev/packages/whisper_ggml,
https://pub.dev/packages/flutter_onnxruntime, https://pub.dev/packages/dart_sentencepiece_tokenizer.
