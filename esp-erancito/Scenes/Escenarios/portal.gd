extends Node2D

var send_player_to = Vector2()
@export var group = 1

var player_in_portal: Node2D = null
@onready var label_mensaje = $LabelMensaje

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var portals = get_tree().get_nodes_in_group("portal")
	for i in range (portals.size()):
		if portals[i].position != position:
			if portals[i].group == self.group:
				send_player_to = portals[i].position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_in_portal != null and Input.is_action_just_pressed("interactuar"):
		teleport_player()

# Función auxiliar para realizar el viaje
func teleport_player():
	if player_in_portal:
		player_in_portal.position = send_player_to
		# Opcional: Resetear estados o reproducir sonido aquí

func _on_area_teletransport_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		# En lugar de moverlo, guardamos quién es
		player_in_portal = area.get_parent()
		label_mensaje.visible = true 
		$AnimationPlayer.play("float")
		



func _on_area_teletransport_area_exited(area: Area2D) -> void:
	if area.get_parent() == player_in_portal:
		player_in_portal = null
		label_mensaje.visible = false
		$AnimationPlayer.stop()
