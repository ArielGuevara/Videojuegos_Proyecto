extends Control


var escena_nivel_1 = "res://Scenes/Cinematics/cinematicaInicial.tscn" 
var escena_creditos = "res://Scenes/Menus/creditos.tscn"
var cargando = false
var musica_activada = true

@onready var music = $MusicMenu
@onready var icono_carga = $IconoCarga
@onready var boton_jugar = $VBoxContainer/BotonJugar
@onready var boton_creditos = $VBoxContainer/BotonCreditos 
@onready var boton_salir = $VBoxContainer/BotonSalir
@onready var boton_musica = $VBoxContainer/BotonMusica
@onready var panel_controles = $PanelControles

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	icono_carga.visible = false
	panel_controles.visible = false
	
	$VBoxContainer/BotonJugar.pressed.connect(_on_jugar_pressed)
	$VBoxContainer/BotonControles.pressed.connect(_on_controles_pressed)
	$VBoxContainer/BotonCreditos.pressed.connect(_on_creditos_pressed)
	$VBoxContainer/BotonMusica.pressed.connect(_on_musica_pressed)
	$VBoxContainer/BotonSalir.pressed.connect(_on_salir_pressed)
	$PanelControles/MarginContainer/VBox/BotonVolver.pressed.connect(_on_volver_controles_pressed)
	
	actualizar_texto_musica()
	music.stream_paused = not musica_activada
	music.play()

func _on_jugar_pressed():
	boton_jugar.disabled = true
	
	icono_carga.visible = true
	if icono_carga is AnimatedSprite2D:
		icono_carga.play("default") # Reproduce la animación
		
	# Iniciar la carga en SEGUNDO PLANO
	cargando = true
	ResourceLoader.load_threaded_request(escena_nivel_1)
	
func _process(delta):
	# Si no estamos cargando, no hacemos nada
	if not cargando:
		return
	
	# 4. Consultar el estado de la carga
	var estado = ResourceLoader.load_threaded_get_status(escena_nivel_1)
	
	match estado:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Aquí sigue cargando, el icono se sigue moviendo...
			pass
			
		ResourceLoader.THREAD_LOAD_LOADED:
			# ¡CARGA COMPLETA!
			cargando = false
			# Obtenemos la escena ya cargada de la memoria
			var escena_lista = ResourceLoader.load_threaded_get(escena_nivel_1)
			# Cambiamos a la escena empaquetada (PackedScene)
			get_tree().change_scene_to_packed(escena_lista)
			
		ResourceLoader.THREAD_LOAD_FAILED:
			print("Error al cargar el nivel")
			cargando = false
			boton_jugar.disabled = false # Reactivar botón si falla
			icono_carga.visible = false
	
func _on_controles_pressed():
	# Al seleccionar Controles se muestra u oculta el recuadro (toggle)
	panel_controles.visible = not panel_controles.visible

func _on_volver_controles_pressed():
	panel_controles.visible = false

func _on_musica_pressed():
	musica_activada = not musica_activada
	music.stream_paused = not musica_activada
	actualizar_texto_musica()

func actualizar_texto_musica():
	if musica_activada:
		boton_musica.text = "MUSICA: ON"
	else:
		boton_musica.text = "MUSICA: OFF"
func _on_creditos_pressed():
	get_tree().change_scene_to_file(escena_creditos)

func _on_salir_pressed():
	get_tree().quit()
