extends CanvasLayer

# Referencias
@onready var panel_principal = $PanelPrincipal
@onready var panel_controles = $PanelControles
@onready var boton_controles = $PanelPrincipal/MarginContainer/VBox/BotonControles
@onready var boton_musica = $PanelPrincipal/MarginContainer/VBox/BotonMusica
@onready var boton_salir = $PanelPrincipal/MarginContainer/VBox/BotonSalir
@onready var boton_volver = $PanelControles/MarginContainer/VBox/BotonVolver

var musica_activada: bool = true
const RUTA_MENU_PRINCIPAL = "res://Scenes/Menus/menu_principal.tscn"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	panel_controles.visible = false

	boton_controles.pressed.connect(_on_controles_pressed)
	boton_musica.pressed.connect(_on_musica_pressed)
	boton_salir.pressed.connect(_on_salir_pressed)
	boton_volver.pressed.connect(_on_volver_pressed)
	actualizar_texto_musica()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("pause"):
		if panel_controles.visible:
			panel_controles.visible = false
			panel_principal.visible = true
		else:
			toggle_pausa()
		get_viewport().set_input_as_handled()

func toggle_pausa():
	if visible:
		cerrar_menu()
	else:
		abrir_menu()

func abrir_menu():
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	panel_principal.visible = true
	panel_controles.visible = false

func cerrar_menu():
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	visible = false

func _on_controles_pressed():
	panel_principal.visible = false
	panel_controles.visible = true

func _on_volver_pressed():
	panel_controles.visible = false
	panel_principal.visible = true

func _on_musica_pressed():
	musica_activada = not musica_activada
	actualizar_texto_musica()
	# Silenciar o activar todos los AudioStreamPlayer del grupo "music"
	for node in get_tree().get_nodes_in_group("music"):
		if node is AudioStreamPlayer:
			node.stream_paused = not musica_activada

func actualizar_texto_musica():
	if musica_activada:
		boton_musica.text = "Musica: ON"
	else:
		boton_musica.text = "Musica: OFF"

func _on_salir_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file(RUTA_MENU_PRINCIPAL)
