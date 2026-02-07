extends Control

# Ruta a tu pantalla de carga (o directo al nivel 1 si prefieres)
var siguiente_escena = "res://Scenes/Screens/screeen_1.tscn"

# Referencias
@onready var imagen_rect = $ImagenHistoria
@onready var texto_label = $PanelTexto/MarginContainer/TextoHistoria
@onready var icono_carga = $IconoCarga

# Variables de control
var indice_actual = 0
var historia = [] # Aquí guardaremos los datos

func _ready():
	# --- CONFIGURACIÓN DE LA HISTORIA ---
	icono_carga.visible = false
	
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
	# Detectar clic o tecla para avanzar
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interactuar") or Input.is_action_just_pressed("attack"):
		avanzar_historia()

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
		texto_label.visible_ratio = 1.0
		return

	# Si ya se mostró todo, avanzamos al siguiente índice
	indice_actual += 1
	
	if indice_actual < historia.size():
		mostrar_diapositiva()
	else:
		# ¡FIN DE LA HISTORIA! Cambiamos de escena
		icono_carga.visible = true
		if icono_carga is AnimatedSprite2D:
			icono_carga.play("default")
		cambiar_a_juego()

func cambiar_a_juego():
	
	get_tree().change_scene_to_file(siguiente_escena)
