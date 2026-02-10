extends CanvasLayer

@onready var texto_label = $Panel/Label
@onready var panel = $Panel
@onready var fondo = $ColorRect

func _ready():
	# Al iniciar, escondemos todo
	ocultar_interfaz()

func mostrar_historia(frase: String):
	texto_label.text = frase
	visible = true
	get_tree().paused = true # PAUSA EL JUEGO

func ocultar_interfaz():
	visible = false
	get_tree().paused = false # REANUDA EL JUEGO

func _on_button_pressed():
	ocultar_interfaz()
