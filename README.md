# Cátedra

App móvil de gestión académica para estudiantes universitarios en Colombia.

Importa el horario desde un PDF, avisa a qué hora salir de casa según la ruta
real al campus, lleva el conteo de faltas contra el límite de cada materia, y
calcula qué nota se necesita en el final para pasar.

Hoy funciona: bienvenida e importación del horario desde PDF (parser local y,
con clave, Claude); Hoy con cuenta atrás, cancelaciones con deshacer y huecos
entre clases; horario semanal navegable; materias con notas, asistencia y
calculadora inversa; ajustes de buffer, transporte, límite de faltas y tema;
tablet con riel y dos paneles. Pendiente: ubicación (Fase 4), widgets (Fase 5),
sync (Fase 6).

Flutter · Riverpod · Drift · offline primero.

## Arrancar

```bash
flutter pub get
dart run tool/gen_tokens.dart      # genera el tema y el microcopy desde el contrato
dart run build_runner build --delete-conflicting-outputs   # Drift
flutter run
```

Los tres archivos generados están en `.gitignore` a propósito: se regeneran, no
se versionan.

```bash
flutter test        # la lógica de negocio, sin Flutter de por medio
```

## Dónde está qué

| Ruta | Qué es |
|---|---|
| `design/tokens.json` | El contrato entre diseño e implementación |
| `tool/gen_tokens.dart` | Lo convierte en código tipado |
| `DESIGN_DECISIONS.md` | Cada desviación del prototipo, con su razón |
| `ARCHITECTURE.md` | Cómo está organizado y por qué |
| `lib/domain/` | Lógica de negocio en Dart puro, con tests |
| `graphify-out/graph.html` | Grafo navegable del proyecto |

## Claves de API

Solo por `--dart-define`. Nunca en el repo.

```bash
flutter run --dart-define=ANTHROPIC_API_KEY=... --dart-define=GOOGLE_MAPS_API_KEY=...
```

Sin `ANTHROPIC_API_KEY` la app funciona igual: el importador de PDF usa solo el
parser local y no abre red. Con la clave, el texto extraído (no el archivo) se
manda a `claude-opus-5` como segunda pasada.
