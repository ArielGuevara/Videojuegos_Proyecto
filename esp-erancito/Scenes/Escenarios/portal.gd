extends Node2D

var send_player_to = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var portals = get_tree().get_nodes_in_group("portal")
	for i in range (portals.size()):
		if portals[i].position != position:
			print("El portal con posicion ", position, " a detectado el otro poportal con posicion ", portals[i]. position)
			send_player_to = portals[i].position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_teletransport_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		area.get_parent().position = send_player_to
