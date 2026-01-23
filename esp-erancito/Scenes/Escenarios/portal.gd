extends Node2D

@export var group = 1

# En lugar de guardar solo la posición (Vector2), guardamos el NODO entero
# para poder pedirle que reproduzca su animación de salida.
var destination_portal: Node2D = null 

var player_in_portal: Node2D = null
var is_teleporting = false # Para evitar que actives el portal 2 veces o mientras viajas

@onready var label_mensaje = $LabelMensaje
@onready var anim_float = $AnimationPlayer
@onready var ascensor_sprite = $Ascensor # Tu AnimatedSprite2D

func _ready() -> void:
	# Buscamos el otro portal del mismo grupo
	var portals = get_tree().get_nodes_in_group("portal")
	for portal in portals:
		# Si es del mismo grupo y NO soy yo mismo... es mi destino
		if portal.group == group and portal != self:
			destination_portal = portal
			break

func _process(delta: float) -> void:
	# Verificamos que haya jugador, que pulsó E, que no se esté teletransportando ya, y que exista destino
	if player_in_portal != null and Input.is_action_just_pressed("interactuar") and not is_teleporting and destination_portal:
		iniciar_secuencia_teletransporte()

# --- SECUENCIA DE SALIDA (Origen) ---
func iniciar_secuencia_teletransporte():
	is_teleporting = true
	label_mensaje.visible = false
	
	# 1. Congelar al jugador (para que no se mueva durante la animación)
	player_in_portal.set_physics_process(false)
	
	# 2. Reproducir animación de entrada en ESTE ascensor
	# Asegúrate de tener una animación llamada "entrada" o cambia el nombre aquí
	ascensor_sprite.play("entrada") 
	
	# 3. Ocultar al jugador (puedes ajustar el tiempo con un timer si quieres que sea a mitad de anim)
	player_in_portal.visible = false
	
	# 4. Esperar a que termine la animación del sprite
	await ascensor_sprite.animation_finished
	
	# 5. Teletransportar (Mover el nodo del jugador)
	# Guardamos una referencia temporal porque al moverlo, saldrá del area y 'player_in_portal' podría volverse null
	var jugador_viajero = player_in_portal 
	jugador_viajero.global_position = destination_portal.global_position
	
	# 6. Llamar al OTRO portal para que haga la secuencia de llegada
	destination_portal.recibir_jugador(jugador_viajero)
	
	# Resetear estado local
	is_teleporting = false
	player_in_portal = null # El jugador ya se fue

# --- SECUENCIA DE LLEGADA (Destino) ---
func recibir_jugador(jugador: Node2D):
	# Esta función la llama el portal de origen, pero se ejecuta en el de DESTINO
	
	# Aseguramos que llegue oculto y congelado
	jugador.visible = false
	jugador.set_physics_process(false)
	
	# 1. Reproducir animación de cierre/salida
	# Asegúrate de tener una animación llamada "salida" o "close"
	ascensor_sprite.play("salida")
	
	# 2. Esperar a que termine
	await ascensor_sprite.animation_finished
	
	# 3. Aparecer al jugador y descongelarlo
	jugador.visible = true
	jugador.set_physics_process(true)
	
	# Opcional: Dejar el ascensor en estado normal
	ascensor_sprite.play("default") 

# --- SEÑALES DEL ÁREA ---
func _on_area_teletransport_area_entered(area: Area2D) -> void:
	# Verificamos el padre (el CharacterBody2D del jugador)
	var cuerpo = area.get_parent()
	if cuerpo.is_in_group("player"):
		player_in_portal = cuerpo
		label_mensaje.visible = true 
		anim_float.play("float")

func _on_area_teletransport_area_exited(area: Area2D) -> void:
	var cuerpo = area.get_parent()
	if cuerpo == player_in_portal:
		# Si se va caminando (no por teletransporte), limpiamos
		if not is_teleporting: 
			player_in_portal = null
		
		label_mensaje.visible = false
		anim_float.stop()
