extends Control

# Ruta a tu pantalla de carga (o directo al nivel 1 si prefieres)
var siguiente_escena = "res://Scenes/Escenarios/escenario_1.tscn"

# Referencias
@onready var imagen_rect = $ImagenHistoria
@onready var texto_label = $PanelTexto/TextoHistoria

# Variables de control
var indice_actual = 0
var historia = [] # Aquí guardaremos los datos

func _ready():
	# --- CONFIGURACIÓN DE LA HISTORIA ---
	# Aquí es donde vas a "acoplar" tus imágenes generadas.
	# Copia y pega este bloque para cada "diapositiva" de tu historia.
	
	historia = [
		{
			"texto": "Esperancito, un estudiante de la ESPE, se encuentra en la ultima semana de exámenes, tiene varios días trasnochado, va con lo justo para sus pasajes, pero con la ilusión de que esto es parte del camino que lo formara como un gran profesional.",
			"imagen": preload("res://Assets_Secenes/Cinematic/1-waiting-class.png") # <--- CAMBIA ESTO POR TUS IMÁGENES
		},
		{
			"texto": "En su clase de Ecuaciones Diferenciales, tiene un profesor muy egocéntrico, quien se la pasa criticando y menospreciando el esfuerzo de sus estudiantes. Esperancito estresado por saber que es su segunda matricula y que este profesor no da segundas oportunidades trata de buscar la respuesta de como ser el mejor en la universidad.",
			"imagen": preload("res://Assets_Secenes/Cinematic/2-inClass.png")
		},
		{
			"texto": "",
			"imagen": preload("res://Assets_Secenes/Cinematic/3-somnolent.png")
		},
		{
			"texto": "Confundido, Esperancito escucha una voz que resuena desde la oscuridad.",
			"imagen": preload("res://Assets_Secenes/Cinematic/4-sleeping.png")
		},
		{
			"texto": "Al abrir los ojos, sigue en el bloque B, pero la luz es tenue y una niebla cubre el suelo.",
			"imagen": preload("res://Assets_Secenes/Cinematic/5-wakeUp.png")
		},
		{
			"texto": "Al abrir los ojos, sigue en el bloque B, pero la luz es tenue y una niebla cubre el suelo.",
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
		
		# Cambiamos el texto
		texto_label.text = datos["texto"]
		
		# Cambiamos la imagen
		imagen_rect.texture = datos["imagen"]
		
		# EFECTO MÁQUINA DE ESCRIBIR (Opcional pero recomendado)
		texto_label.visible_ratio = 0
		var tween = create_tween()
		tween.tween_property(texto_label, "visible_ratio", 1.0, 4.0) # Tarda 2 segundos en escribir

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
		cambiar_a_juego()

func cambiar_a_juego():
	get_tree().change_scene_to_file(siguiente_escena)
