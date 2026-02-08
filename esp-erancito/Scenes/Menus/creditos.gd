extends Control

const RUTA_MENU_PRINCIPAL = "res://Scenes/Menus/menu_principal.tscn"

@onready var animation_player = $AnimationPlayer
@onready var boton_volver = $BotonVolver
@onready var musica = $MusicaCreditos

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Conectar el botón de volver
	boton_volver.pressed.connect(_on_volver_pressed)
	
	# Iniciar la animación automáticamente
	animation_player.play("scroll_creditos")
	
	# Cuando termine la animación, podemos reiniciarla o hacer algo
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# Reproducir música
	if musica:
		musica.play()

func _on_volver_pressed():
	get_tree().change_scene_to_file(RUTA_MENU_PRINCIPAL)

func _on_animation_finished(anim_name):
	# Cuando terminen los créditos, esperar 2 segundos y volver al menú
	if anim_name == "scroll_creditos":
		await get_tree().create_timer(2.0).timeout
		_on_volver_pressed()

# También permitir saltar los créditos con ESC o Enter
func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_on_volver_pressed()
