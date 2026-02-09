extends Control

# Ruta a tu pantalla de carga (o directo al nivel 1 si prefieres)
var siguiente_escena = "res://Scenes/Screens/screeen_1.tscn"

# Referencias
@onready var imagen_rect = $ImagenHistoria
@onready var texto_label = $PanelTexto/MarginContainer/TextoHistoria
@onready var icono_carga = $IconoCarga
@onready var musica_cinema = $MusicaCinema
@onready var barra_skip = $BarraSkip

# Variables de control
var tiempo_presionado = 0.0
const TIEMPO_PARA_SALTAR = 1.5
var indice_actual = 0
var historia = [] # Aquí guardaremos los datos
var cargando_nivel = false

func _ready():
	# --- CONFIGURACIÓN DE LA HISTORIA ---
	icono_carga.visible = false
	barra_skip.visible = false
	musica_cinema.play()
	
	historia = [
		{
			"texto": "Esperancito, un estudiante de la ESPE, se encuentra en la ultima semana de exámenes, tiene varios días trasnochado, va con lo justo para sus pasajes, pero con la ilusión de que esto es parte del camino que lo formara como un gran profesional.",
			"imagen": preload("res://Assets_Secenes/Cinematic/1-waiting-class.png") # <--- CAMBIA ESTO POR TUS IMÁGENES
		},
		{
			"texto": "En su clase de Ecuaciones Diferenciales, tiene un profesor muy egocéntrico, quien se la pasa criticando y menospreciando el esfuerzo de sus estudiantes. Esperancito estresado por saber que es su segunda matrícula y que este profesor no da segundas oportunidades trata de buscar la respuesta de como ser el mejor en la universidad.",
			"imagen": preload("res://Assets_Secenes/Cinematic/2-inClass.png")
		},
		{
			"texto": "Pero las noches de desvelo le pasan factura y sin darse cuenta sus ojos se van cerrando leeentaamente... mientras en su mente sigue preguntandose ¿Cuál es el secreto para graduarse con el mayor exito?",
			"imagen": preload("res://Assets_Secenes/Cinematic/3-somnolent.png")
		},
		{
			"texto": "Hasta que se queda dormido, y antes de adentrarse en un sueño profundo se escucha muy tenue pero de forma despectiva como el profesor dice: ''Eso debieron aprenderlo en el prematernal!'' ",
			"imagen": preload("res://Assets_Secenes/Cinematic/4-sleeping.png")
		},
		{
			"texto": "-¿Qué hora es? ¿Dónde estoy? ¿A donde fueron todos?
Esperancito no sabe donde está, todo es tan confuso y raro, pues mira niebla a su alrededor, eso no tiene sentido.",
			"imagen": preload("res://Assets_Secenes/Cinematic/5-wakeUp.png")
		},
		{
			"texto": "De repente parece abrirse un agujero en el suelo a donde es succionado nuestro protagonista, grita desesperado, pero no hay nadie que lo escuche, ¿O si?
Al fondo se ve una luz donde parece verse... ¿El sello del bloque B? ¿El mismo que si pisas pierdes el semestre?",
			"imagen": preload("res://Assets_Secenes/Cinematic/6-falling.png")
		},
	]
	
	# Cargar la primera diapositiva
	mostrar_diapositiva()

func _process(delta):
	# Si ya estamos cargando, ignoramos todo input
	if cargando_nivel: return
	# --- LÓGICA DE SALTAR CINEMÁTICA (MANTENER) ---
	if Input.is_action_pressed("ui_accept"): # O "skip" si creas esa acción
		tiempo_presionado += delta
		barra_skip.visible = true
		barra_skip.value = (tiempo_presionado / TIEMPO_PARA_SALTAR) * 100
		
		# Si se completó el tiempo...
		if tiempo_presionado >= TIEMPO_PARA_SALTAR:
			saltar_cinematica_completa()
	else:
		# Si suelta la tecla, reseteamos
		if tiempo_presionado > 0:
			tiempo_presionado -= delta * 2 # Baja el doble de rápido (efecto visual agradable)
			if tiempo_presionado < 0: tiempo_presionado = 0
			barra_skip.value = (tiempo_presionado / TIEMPO_PARA_SALTAR) * 100
		
		# Ocultamos la barra si está vacía
		if tiempo_presionado <= 0:
			barra_skip.visible = false

	# --- LÓGICA DE AVANZAR TEXTO (UN CLIC) ---
	# Usamos is_action_just_pressed para avanzar normal (clic a clic)
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		avanzar_historia()

# --- NUEVA FUNCIÓN PARA EL SKIP ---
func saltar_cinematica_completa():
	cargando_nivel = true
	barra_skip.visible = false # Ocultamos la barra
	musica_cinema.stop() # Paramos la música si quieres
	
	# Llamamos directamente a la carga
	iniciar_carga()

func mostrar_diapositiva():
	# Verificamos que el índice sea válido
	if indice_actual < historia.size():
		var datos = historia[indice_actual]
		
		# Texto alineado a la izquierda para que no se mueva: solo se revela como si avanzara el cursor
		texto_label.text = datos["texto"]
		
		# Cambiamos la imagen
		imagen_rect.texture = datos["imagen"]
		
		# Mensaje fijo: texto oculto al inicio; esperamos un frame para que el layout sea fijo
		texto_label.visible_ratio = 0.0
		await get_tree().process_frame
		# Ajustar altura del recuadro al contenido del texto (márgenes 16+16 + contenido)
		var panel = $PanelTexto
		panel.custom_minimum_size.y = texto_label.get_content_height() + 32
		# Efecto de escritura: se va revelando como si se escribiera, sin que se mueva nada
		var tween = create_tween()
		tween.tween_property(texto_label, "visible_ratio", 1.0, 4.0)

func avanzar_historia():
	# Si el texto aún se está escribiendo, lo mostramos completo de golpe
	if texto_label.visible_ratio < 1.0:
		var tween = get_tree().create_tween() # Matamos el tween anterior si existe
		tween.kill()
		texto_label.visible_ratio = 1.0
		return

	# Si ya se mostró todo, avanzamos al siguiente índice
	indice_actual += 1
	
	if indice_actual < historia.size():
		mostrar_diapositiva()
	else:
		# ¡FIN DE LA HISTORIA!
		iniciar_carga() # Llamamos a una función nueva

func iniciar_carga():
	cargando_nivel = true # Candado de seguridad
	icono_carga.visible = true
	if icono_carga is AnimatedSprite2D:
		icono_carga.play("default")
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	cambiar_a_juego()

func cambiar_a_juego():
	get_tree().change_scene_to_file(siguiente_escena)
