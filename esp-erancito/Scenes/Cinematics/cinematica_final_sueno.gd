extends Control

@onready var label_texto: Label = $PanelTexto/MarginContainer/LabelTexto
@onready var imagen_sleeping: TextureRect = $ImagenSleeping

const RUTA_CREDITOS := "res://Scenes/Menus/creditos.tscn"

var _diapositivas := []
var _indice_actual := 0

func _ready() -> void:
	# Definimos las dos diapositivas finales:
	# 1) Esperancito durmiendo
	# 2) Profesor en clase con regaño
	_diapositivas = [
		{
			"texto": "Estás despertando del sueño...",
			"imagen": preload("res://Assets_Secenes/Cinematic/4-sleeping.png")
		},
		{
			"texto": "Atiende ESPErancito, anda a lavarte la cara, este no es el Instituto Gotitas del saber.",
			"imagen": preload("res://Assets_Secenes/Cinematic/2-inClass.png")
		}
	]
	
	_indice_actual = 0
	_mostrar_diapositiva_actual()


func _unhandled_input(event: InputEvent) -> void:
	# La barra espaciadora está mapeada a 'ui_accept' por defecto en Godot.
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		_avanzar_o_salir()


func _avanzar_o_salir() -> void:
	_indice_actual += 1
	if _indice_actual < _diapositivas.size():
		_mostrar_diapositiva_actual()
	else:
		_ir_a_creditos()


func _mostrar_diapositiva_actual() -> void:
	if _indice_actual >= 0 and _indice_actual < _diapositivas.size():
		var datos = _diapositivas[_indice_actual]
		if label_texto:
			label_texto.text = datos["texto"]
		if imagen_sleeping:
			imagen_sleeping.texture = datos["imagen"]


func _ir_a_creditos() -> void:
	get_tree().change_scene_to_file(RUTA_CREDITOS)
