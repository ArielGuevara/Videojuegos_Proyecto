extends Control


var escena_nivel_1 = "res://Scenes/Cinematics/cinematicaInicial.tscn" 
var cargando = false
@onready var music = $MusicMenu

@onready var icono_carga = $IconoCarga
@onready var boton_jugar = $VBoxContainer/BotonJugar
@onready var boton_salir = $VBoxContainer/BotonSalir

func _ready():
	# Nos aseguramos de que el ratón sea visible (por si lo ocultaste en el juego)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	icono_carga.visible = false
	
	# Conectamos las señales de los botones mediante código (es más limpio)
	# O puedes hacerlo manual desde la pestaña Nodos si prefieres.
	$VBoxContainer/BotonJugar.pressed.connect(_on_jugar_pressed)
	$VBoxContainer/BotonSalir.pressed.connect(_on_salir_pressed)
	
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
	
func _on_salir_pressed():
	# Cierra el juego
	get_tree().quit()
