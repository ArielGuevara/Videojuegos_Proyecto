extends CanvasLayer

@onready var etiqueta = $Label # Asegúrate de arrastrar tu nodo Label aquí

var total_items = 0
var items_recogidos = 0

func _ready():
	# 1. AUTOMATIZACIÓN: Contamos cuántos nodos hay en el grupo "historias" al inicio
	total_items = get_tree().get_nodes_in_group("historias").size()
	
	# 2. Actualizamos el texto inicial
	actualizar_marcador()

func actualizar_marcador():
	etiqueta.text = "Pistas: " + str(items_recogidos) + " / " + str(total_items)

# Esta función la llamará el item cuando lo toques
func sumar_item():
	items_recogidos += 1
	actualizar_marcador()
