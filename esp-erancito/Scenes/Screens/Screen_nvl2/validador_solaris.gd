extends Area2D

# --- ARRASTRA AQUÍ A SOLARIS DESDE EL ÁRBOL DE NODOS ---
@export var jefe_solaris : CharacterBody2D 

func _ready():
	# Conectamos la señal si no lo has hecho en el editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Verificamos si es el jugador
	if body.name == "boy1" or body.is_in_group("player"):
		verificar_requisitos(body)

func verificar_requisitos(jugador):
	# 1. Contamos los ítems del grupo "historias"
	var items_restantes = get_tree().get_nodes_in_group("historias").size()
	
	print("Items restantes: ", items_restantes)
	
	if items_restantes == 0:
		# --- CASO DE ÉXITO ---
		permitir_paso()
	else:
		# --- CASO DE FALLO ---
		rechazar_jugador(jugador, items_restantes)

func permitir_paso():
	print("¡REQUISITOS CUMPLIDOS! Iniciando batalla...")
	
	# 1. Despertamos al jefe (usando la función que creamos antes)
	if jefe_solaris and jefe_solaris.has_method("activar_jefe"):
		jefe_solaris.activar_jefe()
	
	# 2. Eliminamos este validador para que el jugador pueda caminar libremente
	queue_free()

func rechazar_jugador(jugador, cantidad):
	print("¡ALTO! Te faltan " + str(cantidad) + " sabidurías.")
	
	# Usamos la función apply_knockback de tu personaje 'Esperancito'/'boy1'
	if jugador.has_method("apply_knockback"):
		# Vector2(-500, -200) significa: Empuje fuerte a la IZQUIERDA y un poquito hacia ARRIBA
		jugador.apply_knockback(Vector2(-500, -200))
