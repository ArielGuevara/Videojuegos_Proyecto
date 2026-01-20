extends Control


var escena_nivel_1 = "res://Scenes/Screens/screeen_1.tscn" 
@onready var music = $MusicMenu

func _ready():
	# Nos aseguramos de que el ratón sea visible (por si lo ocultaste en el juego)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Conectamos las señales de los botones mediante código (es más limpio)
	# O puedes hacerlo manual desde la pestaña Nodos si prefieres.
	$VBoxContainer/BotonJugar.pressed.connect(_on_jugar_pressed)
	$VBoxContainer/BotonSalir.pressed.connect(_on_salir_pressed)
	
	music.play()

func _on_jugar_pressed():
	# Cambia a la escena del juego
	get_tree().change_scene_to_file(escena_nivel_1)

func _on_salir_pressed():
	# Cierra el juego
	get_tree().quit()
