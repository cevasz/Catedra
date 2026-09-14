# Decisiones de diseño

Cada desviación del prototipo importado, con su razón. El prototipo vive en
`https://claude.ai/design/p/f4061a58-2717-4d86-8957-20ae1223bee1`.

El contrato es `design/tokens.json`. Este archivo explica por qué el contrato
dice lo que dice donde no coincide con el prototipo.

---

## 1. La escala tipográfica se amplió de 9 a 11 pasos

**Prototipo:** `type` nombra 9 tamaños. Las pantallas usan 15.

**Desviación:** se añadieron `bodyS` (14 px) y `captionS` (11 px).

**Razón:** 14 px aparece 58 veces y 11 px 56 veces en `Screens.dc.html`. Son el
segundo y tercer tamaño más usados de toda la app: la tab bar, los metadatos de
los widgets y los subtítulos de la timeline. Redondearlos a 15 y 12 habría
cambiado visiblemente ~114 nodos de texto.

Los otros 7 tamaños fuera de escala (16, 18, 19, 21, 22, 26, 27 px; 24 usos en
total) **sí** se redondean al paso más cercano. Son títulos de una sola
aparición y el redondeo no es perceptible.

## 2. El semáforo de faltas se definió aquí, no en el diseño

**Prototipo:** solo dibuja un estado: 3 de 6 en `accent.attention` con la
insignia «Mitad del cupo usada». No hay verde ni rojo.

**Desviación:** cuatro estados con umbrales por fracción del límite.

| Estado | Fracción | Color |
|---|---|---|
| `ok` | < 0,5 | `accent.ok` |
| `attention` | 0,5 – 0,834 | `accent.attention` |
| `risk` | 0,834 – 1,0 | `accent.urgent` |
| `lost` | ≥ 1,0 | `accent.urgent` |

**Razón:** los umbrales son fracción y no conteo porque `limite_faltas` varía
por materia; un umbral de «3 faltas» sería falso con un límite de 3. El 0,5 sale
del único punto calibrado del prototipo. El 0,834 es 5/6: con el límite por
defecto, `risk` entra exactamente cuando queda una sola falta, que es cuando el
shake de 4 px tiene algo que decir.

**Aprobado el 2026-09-03.** Era la desviación con más criterio propio; queda
confirmada tal cual. Los umbrales viven en `semaphore.thresholds` de
`design/tokens.json` y se generan a `absence_state.g.dart`: cambiarlos es tocar
el contrato, no el código.

## 3. Se añadió `easeOutExpo` a las curvas

**Prototipo:** `tokens.json` define `easeOutCubic` como `(.33, 1, .68, 1)` y la
tabla de movimiento la asigna a la cascada de la timeline y al revelado del PDF.
Pero el CSS realmente dibujado usa `(.16, 1, .30, 1)`, que es easeOutExpo.

**Desviación:** se añadió `easeOutExpo` y se asignó a `timelineCascade` y
`pdfRows`. `easeOutCubic` sigue siendo la curva por defecto de todo lo demás.

**Razón:** el CSS es lo que el diseñador vio y aprobó al mirar el prototipo. La
tabla es una descripción posterior y menos precisa.

## 4. Los radios del anillo urgente son los dibujados, no los de la prosa

**Prototipo:** la sección 1f describe el paso a urgente como `r 50 → 47 → 49`.
El SVG dibujado usa `r = 45` en normal y `r = 43` en urgente, sin fotograma
intermedio.

**Desviación:** se implementa 45 → 43 con `easeOutBackSoft`.

**Razón:** esa curva sobrepasa por debajo de 43 y asienta ahí, lo que reproduce
el «contrae y asienta» descrito sin inventar una escala que el SVG no tiene. Los
números 50/47/49 no corresponden a ninguna geometría del prototipo.

## 5. El odómetro corre a 320 ms, no a 500

`motion.durations.odometer` dice 320 ms; el keyframe `sc-roll` del canvas corre a
500 ms. Manda la tabla: el keyframe del canvas es una demo, no una especificación.

## 6. La temperatura ambiental solo corre en tema oscuro

**Prototipo:** `surface.ambientWarmNight.light` = `#F7F1E4` existe como token
pero no aparece dibujado en ninguna pantalla.

**Desviación:** `color.ambient.enabledInLightTheme = false`.

**Razón:** sobre el hueso `#F5F0E6` del tema claro, un +4 % cálido vira a
amarillo sucio. El prototipo nunca lo dibujó, así que nadie lo ha visto. Se deja
como token para poder activarlo sin tocar código.

## 7. Las sombras del tema claro llevan alfa reducido

Las tres sombras del prototipo son negras con alfa fijo, calibradas sobre
`#14100E`. Sobre `#F5F0E6` quedan duras. En claro se usa el mismo desenfoque con
alfa × 0,45.

## 8. Se añadió `text.onUrgent`

El botón «Abrir la ruta» de la pantalla B2 usa `#F7EFE8` sobre `accent.urgent`,
en ambos temas, y no `text.onAccent`. No tenía nombre de token; ahora lo tiene.

## 9. Las pantallas de captura manual se escribieron aquí

**Prototipo:** el onboarding ofrece «Entrar los datos a mano» y ahí se acaba.
No hay formulario de materia, ni de clase, ni de evaluación.

**Desviación:** tres formularios nuevos, con su microcopy en el bloque `copy`
de `design/tokens.json` marcado `"$from": "gap-fill"`.

**Razón:** el criterio de cierre de la Fase 1 es que el horario se pueda meter a
mano. Sin estas pantallas la fase no cierra y no hay nada que probar contra el
prototipo, porque no habría datos.

Lo que sí sale del prototipo: el layout. Los campos usan `component.input`, los
botones `component.button`, los chips de día y de meta `component.chip`, y el
espaciado la escala `space`. No se inventó ningún componente nuevo salvo el
selector de color, que abajo tiene su propia entrada.

La voz del microcopy imita la del prototipo: segunda persona, frases cortas, sin
signos de admiración, y el porqué antes que la instrucción («El límite es 6 en el
semestre. Las canceladas por el profe no cuentan», no «Ingrese el límite»).

## 10. Cinco medidas que estaban dibujadas pero no tenían nombre

La regla del proyecto es que un literal en código de UI es un bug. Al escribir
las pantallas nuevas aparecieron cinco números sin token detrás:

| Token | Valor | De dónde sale |
|---|---|---|
| `layout.timelineRow.railHeight` | 34 | Dibujado en la timeline de B1 |
| `layout.weekColumnWidth` | 116 | Dibujado en la columna de día de C1 |
| `component.colorPicker.swatch` | 34 | `gap-fill` |
| `icon.named` (14/16/18/20/24) | — | Nombres para `icon.sizes`, que era una lista |
| `component.button.minTouchTarget` | 44 | Ya estaba en el contrato; el tema usaba 48 |

Los dos primeros ya se estaban usando como literales y solo les faltaba nombre.

`component.colorPicker.swatch` es de criterio propio: 34 px es tocable sin llegar
al mínimo de 44 del botón, que haría la fila de ocho colores más ancha que el
marco de 360.

`icon.named` no inventa medidas: pone nombre a los cinco valores que `icon.sizes`
ya tenía. Citarlos por índice desde un widget sería un número mágico disfrazado.

`minTouchTarget` es una corrección: el tema ponía 48 en los botones y el contrato
dice 44. Manda el contrato.

## 11. La mascota de la esquina urgente pasa de 40 a 62 px

La card de «Ya. Camina.» tenía la mascota a `size: 40`, un literal que no salía
de ningún sitio. `mascot.sizesUsed.urgentCorner` dice 62, que es la medida a la
que el diseño la dibujó en B2. Ahora el generador emite `MascotTokens.size*` y la
pantalla la cita.

Es un cambio visible: el erizo de la esquina se ve más grande que hasta ahora.
Se ve como en el prototipo.

---

## Los números de la calculadora del prototipo no son consistentes

No es una desviación: es un hallazgo. Las cifras de las pantallas E1 y E2 son
maquetación, no cálculo.

Con las evaluaciones de «Bases de datos» (Parcial 1 25 % → 3,2; Taller SQL 15 %
→ 4,1; Proyecto 30 % → 3,3; Parcial 2 30 % pendiente):

- Acumulada: 2,405 / 0,70 = **3,44** → «3,4» en pantalla. **Coincide.**
- Proyección: la pantalla dice **3,5**; extrapolando el rendimiento actual da 3,4.
- «Cerrar en 3,5» requiere (3,5 − 2,405) / 0,30 = **3,65**; la pantalla dice **3,8**.
- «Cerrar en 3,0» requiere **1,98**; la pantalla dice **2,2**.
- «Cerrar en 4,0» requiere **5,32** (imposible); la pantalla dice **5,0** (al límite).

Cada meta implicaría un acumulado distinto (2,34 / 2,36 / 2,50), así que los
números están escogidos a mano para que la pantalla se lea bien.

**Qué se implementó:** la fórmula correcta,
`necesito = (meta − puntos_asegurados) / peso_pendiente`, verificada en
`test/domain/grades_test.dart` contra estos mismos datos. La pantalla mostrará
3,7 donde el prototipo dice 3,8.

## El plan de salida del prototipo también se contradice

La pantalla B1 dice a la vez «sal 9:52» (= 10:00 − 8 min de ruta, buffer 0) y
«llegas 4 antes» (que implica buffer 4 y salida 9:48).

**Qué se implementó:** `hora_salida = hora_clase − ruta − buffer`, y
«llegas N antes» donde N **es** el buffer. Con buffer 4 la app dirá «sal 9:48».
Es la única lectura en la que las dos frases de la pantalla son ciertas a la vez.

## 12. La mascota no se limita a los estados vacíos

**Regla previa del proyecto:** «Erizógenes solo en estados vacíos».

**Prototipo:** lo dibuja en seis pantallas, y solo dos son estados vacíos. Las
otras cuatro son `A1 splash`, `A3 procesando PDF`, `A5 error de PDF` y la
esquina de `B2 sal ya`.

**Desviación:** manda `mascot.allowedScreens` del contrato, no la regla. La
lista de seis queda como está.

**Razón:** las cuatro pantallas no vacías son justo aquellas en las que la
persona está esperando o algo salió mal —arranque, parseo, error, urgencia—, y
son el único sitio donde la mascota hace un trabajo real en vez de decorar. La
regla «solo en vacíos» describía el caso mayoritario, no el criterio. El
criterio es: la mascota aparece donde no hay contenido que mirar, sea porque
todavía no lo hay, porque falló, o porque lo único que importa es salir ya.

**Aprobado el 2026-09-07.** El `assert` de `MascotView` sigue siendo la única
compuerta: una pantalla nueva no puede poner la mascota sin entrar antes en el
contrato. La regla del proyecto se reescribe como «la mascota solo en las
pantallas que el contrato autoriza».

## 13. Cinco tokens más para vaciar de literales el código de pantalla

La auditoría del 2026-09-07 encontró siete literales sobrevividos. Cinco
necesitaban nombre en el contrato:

| Token | Valor | Qué reemplaza |
|---|---|---|
| `ring.countdown.breatheScale` | 0,018 | Amplitud de la respiración, suelta en `countdown_ring.dart` |
| `ring.countdown.progressWindowMinutes` | 60 | La ventana del anillo, que además era regla de negocio en un widget |
| `motion.durations.clockTick` | 20 000 ms | Cadencia del `clockProvider` |
| `component.odometer.maxMinutes` | 999 | Tope de dígitos del odómetro |
| `copy.today.roomLine` | `Salón {code} · {hora}` | Microcopy escrito a mano en `today_screen.dart` |

`progressWindowMinutes` vive en el contrato porque es la **escala del dibujo**,
pero el cálculo se movió a `DeparturePlanner.ringProgress`, que es Dart puro y
tiene cinco tests. El dominio no lee tokens: la ventana entra por parámetro.

`copy.today.roomLine` va marcado `gap-fill`: el prototipo dibuja esa fila pero
nunca la nombra. `component.odometer.maxMinutes` también, y su porqué está en el
propio contrato.

Los otros dos literales no necesitaban token: el título de la app pasó a
`SOnboarding.brand`, que ya existía, y `RingMotion.radiusNormal/radiusUrgent`
dejaron de repetir 45 y 43 para citar `RingTokens.countdownRadius*`.

## 14. La calculadora tiene tres respuestas, no dos

**Prototipo:** dos mensajes. «Está dentro de lo que ya has sacado» cuando la
meta es cómoda, y «No da / Con los números actuales no da» cuando es imposible.
Entre los dos hay un hueco: cuando la nota requerida cabe en la escala pero está
por encima de todo lo que esa persona ha sacado, el prototipo no dice nada.

**Desviación:** `TargetVerdict` gana el estado `demanding`, con su propio
mensaje `copy.calculator.demanding`, marcado gap-fill.

| Veredicto | Condición | Mensaje |
|---|---|---|
| `reachable` | requerida ≤ tu mejor nota | «Está dentro de lo que ya has sacado.» |
| `demanding` | requerida ≤ 5,0 pero > tu mejor nota | «Está por encima de lo que has sacado hasta ahora.» |
| `impossible` | requerida > 5,0 | «No da.» + «Habla con el profe.» |

**Razón:** el umbral no es un número inventado sino **tu propio historial**, que
es la vara que el prototipo ya usaba en el mensaje `reachable`. Un 4,35 es
cómodo para quien viene sacando 4,1 y es otra cosa para quien no ha pasado de
2,4; un corte fijo en 4,0 trataría los dos casos igual. El caso de Física II del
prototipo (E2) es justo este: necesita 4,35 con una mejor nota de 2,4.

Sin nada calificado no se declara exigente. No hay con qué comparar, y afirmarlo
sería inventar un juicio sobre alguien de quien todavía no se sabe nada.

En la lista de «si quisieras otra meta» la fila exigente **conserva el número** y
dice su estado con color (`accent.attention`); solo la imposible lo reemplaza por
«No da», porque ahí el número ya no señala nada alcanzable.

## 15. El tachado de una cancelada se dibuja

**Prototipo:** muestra la clase cancelada tachada. No especifica si el tachado
entra animado, porque un HTML estático no puede mostrarlo.

**Desviación:** el trazo se dibuja de izquierda a derecha en los 400 ms de
`motion.durations.strike`, y el texto pierde color a la vez.

**Razón:** cancelar es algo que **acaba de pasar**. Un `lineThrough` que aparece
de golpe se lee como un estilo que siempre estuvo ahí; el trazo dibujándose se
lee como el resultado de lo que acabas de tocar. La duración ya existía en el
contrato con ese nombre exacto y no se estaba usando para nada.

Vive en `lib/theme/strike_through.dart`, junto a `CascadeIn`, porque la timeline
de Hoy y la pestaña de asistencia lo usan igual. Bajo reduced-motion el trazo no
se acorta: se salta, y la línea aparece entera en su estado final.

## 16. «Ya voy» avanza la card; «Cancelar» la convierte en la B3

**Prototipo:** B2 dibuja «Abrir la ruta» y «Ya voy» en el estado urgente, y B1
lista «Cancelar» entre las acciones de Hoy. No dice qué pasa con la card
después de tocar ninguno de los dos.

**Desviación:** «Ya voy» marca la sesión como asistida y la card pasa a la
clase de después (o a «Nada más» si no hay). «Cancelar» la marca cancelada por
el profe y aparece la card B3 —«Cancelada por el profe · No cuenta como falta ·
Marcada hace N min · Deshacer»— encima de la siguiente, etiquetada «Lo
siguiente». Las dos acciones están visibles en todos los estados, no solo en
urgente.

**Razón:** una clase a la que ya dijiste que vas no necesita alerta; dejar la
cuenta atrás corriendo sería seguir avisando de algo resuelto. Y la B3 no
puede quedarse para siempre: se retira sola cuando pasa la hora a la que la
clase habría terminado, que es cuando deja de ser noticia y pasa a ser
historial. «Abrir la ruta» sigue sin implementar: es de la Fase 4.

## 17. Los huecos de la timeline empiezan en 30 minutos

**Prototipo:** B1 dibuja «Hueco de 1 h 30» entre dos clases. No dice desde
cuánto tiempo un espacio entre clases merece una fila.

**Desviación:** `DayGaps.minimumMinutes = 30`, en el dominio y con tests. Por
debajo es cambio de salón y no se dibuja. Una clase cancelada no corta el
hueco: su tiempo se suma al de alrededor.

**Razón:** el umbral es regla de negocio, no medida de dibujo, así que vive en
`lib/domain/schedule/` y no en el contrato. Treinta es el punto en el que se
puede hacer algo con el tiempo —comer, ir a la biblioteca— y no solo caminar
al siguiente salón.

## 18. El rango de la semana y las flechas

**Prototipo:** C1 tiene el título «Semana» y la cadena `range` («{desde} –
{hasta} · {n} clases») pero la pantalla se dibuja solo para la semana actual.

**Desviación:** dos flechas mueven la semana de siete en siete y el rango se
vuelve tocable, en `accent.primary`, para volver a la de hoy. La columna de
hoy va sobre `surface.raised` con el día del mes al lado de la etiqueta, y las
columnas ya pasadas se atenúan. La franja arranca desplazada a la columna de
hoy.

**Razón:** «qué tengo la semana que viene» es la segunda pregunta más común
del horario y sin flechas no tenía respuesta. Todo lo demás son decisiones de
lectura: sin resaltar hoy, siete columnas iguales obligan a contar.

## 19. El sheet del bloque semanal contesta las tres cifras

**Prototipo:** C2 nombra `absences`, `ofLimit`, `accumulated` y `nextEval`,
pero la primera implementación solo puso el encabezado y los botones.

**Desviación:** fila de tres cifras —faltas con su semáforo, acumulada sobre
5,0 y la próxima evaluación con fecha o porcentaje— entre el encabezado y las
acciones. Si la sesión ya está marcada, los dos botones de marcar se
sustituyen por uno de «{estado} · Deshacer».

**Razón:** la próxima evaluación es la primera sin nota, ordenada por fecha
si la tiene y por `orden` si no. Ofrecer «Marcar falta» sobre una sesión ya
marcada como falta duplicaría la marca; el deshacer es lo único que tiene
sentido ahí.

## 20. Los rangos de Ajustes viven en el dominio

Ajustes deja mover el buffer de 0 a 30 minutos y el límite de faltas por
defecto de 1 a 20. Los cuatro números están en `DeparturePlanner` y
`AttendanceCounter`, no en el contrato ni en el widget: son límites de la
regla, no medidas del dibujo. El 6 del límite por defecto también tiene
nombre (`AttendanceCounter.defaultLimit`) y coincide con el `withDefault` de
las dos columnas que lo guardan.

## 21. Tablet: riel, dos paneles y ancho de contenido

**Prototipo:** dieciocho pantallas a 360 dp. Nada por encima.

**Desviación:** tres clases de tamaño con los cortes de Material 3, en
`layout.breakpoint*` del contrato:

| Clase | Ancho | Qué cambia |
|---|---|---|
| compact | < 600 | Nada: es el prototipo |
| medium | 600 – 839 | La barra inferior pasa a riel lateral; el contenido se acota a 720 |
| expanded | ≥ 840 | Hoy en dos columnas (cards \| el día); Materias en maestro-detalle; Notas y Asistencia lado a lado; la semana reparte sus siete columnas sin scroll |

Los sheets se acotan al mismo ancho de 720 y quedan centrados.

**Razón:** en una pantalla ancha una barra abajo queda lejos del pulgar y roba
una franja de alto que el contenido sí aprovecha. Los dos paneles no inventan
pantallas: ponen juntas las que en teléfono se visitan una detrás de otra. El
panel maestro abre la primera materia si no hay selección, porque un panel
vacío con una lista al lado es una pregunta sin responder. Los 720 del ancho
de contenido y los 380 del panel maestro son criterio propio; los cortes no.

La mascota no crece con la pantalla: se queda al tamaño del contrato y la
columna se centra. Una mascota gigante deja de ser compañía y pasa a ser
decoración.

El lienzo con los dos layouts de tablet, la hoja de poses y la tabla de
movimiento vive en
`https://claude.ai/code/artifact/4902e94d-fe07-41d3-9d0b-0bb1fb685914`.

## 22. Cuatro transiciones de pantalla y cinco micro-movimientos de mascota

**Prototipo:** la tabla de movimiento (1f) tiene catorce filas. Ninguna habla
de cambiar de pantalla, y de la mascota solo nombra parpadeo, respiración y
rodada.

**Desviación:** se añaden al bloque `motion.spec` del contrato, marcadas
`gap-fill`:

| Animación | Qué hace | Duración |
|---|---|---|
| `routeTransition` | Toda ruta entra con opacidad y 8 px de subida | `hero` (340) |
| `cardSwitch` | Las cards de Hoy se cruzan: la saliente sube y se va, la entrante sube y llega | `base` (300) |
| `paneReveal` | El panel de detalle de tablet entra igual al cambiar de materia | `base` (300) |
| `railIndicator` | El indicador del riel viaja; no parpadea | 220 |
| `mascotEnter` | Una vez: escala 0,6 → 1 con easeOutBackBounce | 480 |
| `mascotSquash` | Rodando se aplasta y estira dos veces por vuelta | 400 |
| `mascotSleep` | Dormido respira hacia abajo (1 → 0,985) y suelta tres «z» | 2 400 |
| `mascotGlance` | Examinando barre la mirada ±1,2 px y el monóculo destella | 1 800 |
| `mascotWobble` | Confundido bambolea el monóculo ±4°; la cabeza no | 3 000 |

Las amplitudes viven en `mascot.*` del contrato (`enterScale`, `sleepScale`,
`glanceOffset`, `wobbleDegrees`, `squashScale`); el painter las cita, no las
inventa.

**Razón:** una animación nueva entra solo si contesta «¿qué acaba de pasar?».
Las de pantalla dicen «cambiaste de sitio» y sustituyen al deslizamiento
lateral de Android, que arrastra 400 ms y no existe en el prototipo. Las de
mascota dicen «sigo aquí» y solo viven donde el contrato ya la permite, que
son las pantallas sin contenido que leer. Bajo reduced-motion las de pantalla
se quedan en el fade de 180 ms y las de mascota se congelan en el primer
fotograma; la entrada se queda en un fade sin escala.

## 23. El PDF se lee en el teléfono; el texto, a veces, sale

**Prototipo:** A2 promete «Todo se lee en el teléfono. Nada se sube» y A1
«El PDF no sale de tu teléfono». El brief, a la vez, pide una clave de la API
de Anthropic para el parseo.

**Desviación:** dos pasadas. La primera es un parser heurístico en Dart puro
(`lib/domain/import/schedule_parser.dart`, doce tests) que corre siempre y
cubre los tres layouts habituales: una fila por clase, nombre arriba y horario
abajo, encabezado de día. La segunda, solo si hay
`--dart-define=ANTHROPIC_API_KEY`, manda **el texto extraído** —nunca el
archivo— a `claude-opus-5` con salida estructurada por esquema JSON y se
queda con su lectura si trae algo. Si la API falla o no hay red, la app sigue
con lo heurístico: el importador no depende de la red para funcionar.

El pie de A2 dice la verdad según el caso: sin clave, el texto del prototipo;
con clave, «El archivo no sale de tu teléfono. El texto sí: lo lee Claude para
armar el horario» (`pdfPicker.footerApi`, gap-fill).

**Razón:** las dos frases del prototipo eran ciertas a la vez solo si nada
salía del teléfono, y con eso los PDF raros no se leen. Se prefirió decir
exactamente qué sale y cuándo antes que dejar una promesa falsa en pantalla.
La extracción de texto sí es local (Syncfusion, Dart puro, en un isolate) y
es lo que distingue el caso «escaneado como imagen» de A5.

La clave embebida por `dart-define` es la del brief y sirve para un uso
personal; una distribución pública tendría que pasar por un servidor propio.
Queda anotado en `ESTADO.md` como deuda.

## 24. A3 revela las filas en cascada aunque el parser sea instantáneo

**Prototipo:** A3 es una lista que va apareciendo fila a fila con «Detectando
filas · 3 de 12» y Erizógenes examinando.

**Desviación:** la heurística resuelve en milisegundos; se ejecuta por tramos
—veinte pasos, `MotionStagger.pdfRows` entre uno y otro— y cada tramo emite
lo encontrado hasta ahí. Las filas entran con la cascada del PDF (80 ms, 8 px).
Con clave de API, después llega «Ordenando lo que encontré» mientras responde
Claude, con la barra en indeterminado.

**Razón:** enseñar qué se va encontrando es lo que hace revisable el
resultado antes de A4, y la persona necesita ver que la app está leyendo *su*
horario y no cargando algo genérico. Es la única espera artificial de la app
y dura como mucho un segundo y medio.

## 25. A4 corrige en sitio y dice por qué duda

**Prototipo:** A4 tiene una insignia «Revisa esto» y el subtítulo «Dos me
dejaron dudando».

**Desviación:** cada duda tiene su motivo en texto (`doubtName`, `doubtDays`,
`doubtRange`, `doubtNamePrev`, gap-fill) y corregir el campo la retira. El
subtítulo cambia con el conteo real: ninguna, una, dos (el del prototipo) o
«{n} me dejaron dudando». El horario se edita por chip con el mismo selector
de día y hora del formulario de clase (`session_fields.dart`, compartido).
«Confirmar {n} clases» cuenta sesiones, no materias, y se deshabilita hasta
que toda materia tenga nombre y toda sesión tenga día.

**Razón:** una insignia sin motivo obliga a releer toda la fila. Y el número
del prototipo era el de su maqueta.

## 26. La bienvenida es la portada mientras no haya datos

**Prototipo:** A1 con marca, lema, dos CTA y pie de privacidad.

**Desviación:** no hay bandera «ya vi el onboarding». La app arranca en A1
cuando no existe ninguna materia y en el shell cuando existe al menos una;
borrar la última devuelve a A1. Tampoco hay «saltar».

**Razón:** las dos salidas de A1 son las dos únicas formas de meter datos, y
sin datos el shell entero son estados vacíos. Una columna nueva en la BD para
recordar algo que los datos ya dicen sería una migración por una bandera.

---

## Lo que sigue sin especificación visual

Único hueco abierto de los nueve detectados; el de las pantallas de captura
manual se resolvió en el §9. Las Fases 4 y 6 siguen necesitando diseño antes de
implementarse:

- Pre-marcado por geofence y la pregunta de fin de día.
- Permiso de ubicación denegado.
- Notificación programada y su escalado a alerta urgente.
- Estadísticas de fin de semestre.
