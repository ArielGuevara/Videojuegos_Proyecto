extends Area2D

@export var velocidad = 400
var direccion = Vector2.RIGHT # Por defecto derecha

func _physics_process(delta):
	# Movemos en la dirección que nos dio el enemigo
	position += direccion * velocidad * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("jugador"): 
		# body.take_damage() # Descomenta si tu jugador tiene vida
		queue_free()
	elif body.name != "enemigo_c++": # Evitamos que explote al salir del cañón
		queue_free()
