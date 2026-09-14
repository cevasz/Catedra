# Estado del programa · 11 de septiembre de 2026

Cátedra es una app Flutter (Riverpod + Drift, offline primero) para
estudiantes universitarios en Colombia. Este archivo dice qué funciona hoy,
qué falta y en qué orden conviene seguir. Las razones de cada decisión están
en `DESIGN_DECISIONS.md`; la estructura, en `ARCHITECTURE.md`.

**Cifras:** 57 archivos Dart escritos a mano, 119 tests en verde,
`flutter analyze` sin avisos, APK release compilando.

## Funciona

### Bienvenida e importar PDF (Fase 3)
- [x] A1: portada con Erizógenes, lema y dos salidas; aparece mientras no haya materias
- [x] A2: selector de PDF del sistema; el pie dice si el texto sale del teléfono o no
- [x] Extracción de texto local (Syncfusion, en isolate); un PDF escaneado se detecta como tal
- [x] Parser heurístico en Dart puro: una fila por clase, nombre arriba y horario abajo, encabezado de día; horas «1-3 pm» y «11-1»; profesor con etiqueta; misma materia en dos filas se une
- [x] A3: las filas aparecen en cascada con «Detectando filas · N de M»; cancelable
- [x] Segunda pasada con `claude-opus-5` (salida estructurada) solo si hay `ANTHROPIC_API_KEY`; si falla, se sigue con lo heurístico
- [x] A4: revisión en sitio con motivo de cada duda, horario por chips, quitar materia, agregar a mano; «Confirmar N clases» se habilita cuando todo tiene nombre y día
- [x] A5: error con la mascota confundida y tres cuerpos según el motivo
- [x] Guardado: materias con color por orden, salones reutilizados, sesiones materializadas
- [x] Entradas: bienvenida, icono en Materias y botón en su estado vacío

### Hoy
- [x] Cuenta atrás hasta la hora de salir, con anillo que se vacía y odómetro
- [x] Estado «sal ya»: anillo terracota, háptica pesada, mascota rodando en la esquina
- [x] Botones «Ya voy» (marca asistencia y avanza a la siguiente) y «Cancelar»
- [x] Card de cancelada (B3): «Cancelada por el profe · Marcada hace N min · Deshacer», se retira sola al pasar la hora
- [x] Card «Nada más» al terminar el día, con «Lo próximo: jue 8:00 · Física II»
- [x] Timeline con huecos («Hueco de 1 h 30»), rango horario, salón, estado y etiqueta «Siguiente» / «Sal ahora»
- [x] Día vacío con mascota dormida, «Lo próximo» y botón «Ver la semana»
- [x] El buffer y el transporte salen de Ajustes y mueven la hora en vivo

### Semana
- [x] Siete columnas, hoy resaltada, auto-scroll a hoy, días pasados atenuados
- [x] Flechas para cambiar de semana; rango «1 sep – 7 sep · 12 clases» tocable para volver
- [x] Bloques con hora, salón, tachado si está cancelada; hero hacia el sheet
- [x] Sheet de materia con faltas (semáforo), acumulada y próxima evaluación; marcar falta / cancelada / deshacer

### Materias
- [x] Lista con semáforo de faltas y acumulada, en cascada
- [x] Alta y edición: nombre, profesor, créditos, límite, color, fecha límite de cancelación, horario
- [x] Borrado en cascada con confirmación
- [x] Detalle en dos pestañas (Notas / Asistencia) con fecha límite de cancelación visible
- [x] Notas: acumulada, proyección, aviso si los porcentajes no suman 100, alta/edición de evaluaciones
- [x] Asistencia: anillo segmentado, «Te quedan N faltas», historial con deshacer, tachado animado
- [x] Calculadora inversa con tres veredictos (alcanzable / exigente / no da) y otras metas

### Ajustes
- [x] Buffer (0–30 min), transporte por defecto, límite de faltas por defecto, tema
- [x] Se guarda al tocar; el tema persiste entre sesiones

### Tablet y movimiento
- [x] Riel lateral desde 600 dp; barra inferior en teléfono
- [x] Desde 840 dp: Hoy en dos columnas, Materias en maestro-detalle, Notas y Asistencia lado a lado, semana sin scroll horizontal
- [x] Formularios, calculadora, ajustes y sheets acotados a 720 dp y centrados
- [x] Transición de ruta propia (fade + subida), cross-fade entre estados de la card de Hoy y del panel de detalle
- [x] Mascota: entrada con rebote, respiración, parpadeo, rodada con squash, sueño con «z», mirada que barre y monóculo que destella o se bambolea
- [x] Todo degrada bajo «reducir movimiento»

### Cimientos
- [x] Contrato `design/tokens.json` → tema, microcopy y umbrales generados; el guardia de contrato falla si aparece un literal en una pantalla
- [x] Dominio en Dart puro con tests: notas, faltas, salida, huecos
- [x] Drift v1 con volcado de esquema y test de migraciones
- [x] Reloj y «hoy» como providers: nada llama a `DateTime.now()` en un build

## No funciona todavía

| Qué | Fase | Qué hace falta |
|---|---|---|
| «Abrir la ruta» y hora de salida real | 4 | Ubicación, geocodificar salones, ruta a pie/bus/carro; el diseño de permisos denegados no existe |
| Pre-marcado de faltas por geofence | 4 | Polígono del campus (tabla `Campuses` ya existe), pregunta de fin de día; sin diseño |
| Notificación programada y escalado a urgente | 4 | Sin diseño |
| Pestaña Mapa | 4 | Hoy es un marcador de posición |
| Widgets de pantalla de inicio (2×2, 4×2, 4×4) | 5 | Tokens listos; falta el Kotlin de Glance |
| Sync con Supabase | 6 | Sin diseño; el esquema no lo condiciona |
| Estadísticas de fin de semestre | 6 | Sin diseño |
| Cambio de semestre | — | La tabla existe y se crea uno por defecto; no hay pantalla para cerrarlo ni abrir otro |
| Archivar materia | — | La columna `archivada` existe; no hay acción en la interfaz |
| Materia perdida (faltas ≥ límite) | — | El estado `lost` se calcula y colorea; falta una pantalla que lo diga con claridad |

## Deuda conocida

- La clave de Anthropic va embebida por `dart-define`: sirve para uso personal; una distribución pública necesita un servidor propio que haga la llamada.
- El parser heurístico está probado con doce casos sintéticos, no con PDF reales de universidades; hay que recoger tres o cuatro y ajustar.
- La segunda pasada con Claude no está probada contra la API real desde la app (sí el decodificador de su respuesta).
- La estimación de tiempo de ruta es fija por modo (15 / 35 / 20 min) hasta la Fase 4.
- «Lo próximo» solo mira sesiones ya materializadas (16 semanas desde el alta de la clase).
- Los formularios abren a pantalla completa también en tablet; podrían ser diálogos.
- Sin tests de widget para las pantallas completas: se prueba el dominio, los providers de Hoy, la mascota y el tachado.
- El proyecto no está bajo git.

## Siguiente paso recomendado

1. Probar el importador con dos o tres PDF reales de horario (Servicios
   académicos) y ajustar el parser con lo que falle; correr una vez con clave
   para ver la segunda pasada.
2. Fase 4 necesita diseño antes de código: permiso de ubicación denegado,
   pre-marcado por geofence y la notificación con escalado. Lo que sí se puede
   hacer ya sin diseño es geocodificar salones y la ruta a pie con «Abrir la
   ruta», porque B2 ya lo dibuja.
