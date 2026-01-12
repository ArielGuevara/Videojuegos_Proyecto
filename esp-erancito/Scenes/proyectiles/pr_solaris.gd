extends Area2D

var velocidad = 400
var direccion = Vector2.LEFT # Por defecto va a la izquierda
var damage = 20

func _process(delta):
	position += direccion * velocidad * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Verificamos si el cuerpo tiene la función 'take_damage'
		if body.has_method("take_damage"):
			# Pasamos el daño y la posición del proyectil (para el empujón)
			body.take_damage(damage, global_position)
			print("¡Bala impactó al jugador!")
		queue_free() # El proyectil se destruye al impactar
		
	elif not body.is_in_group("enemy"): 
		queue_free() # Chocó con pare

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free() # Limpiar memoria si sale de pantalla
