extends Area2D

var velocidad = 400
var direccion = Vector2.LEFT 
var damage = 20
var reflected = false # Nueva variable: ¿Ya fue reflejado?

func _process(delta):
	position += direccion * velocidad * delta

func _on_body_entered(body):
	# CASO 1: YA FUE REFLEJADO (Ahora busca matar enemigos)
	if reflected:
		if body.is_in_group("enemy"):
			# Si el enemigo tiene función de daño, lo lastimamos
			if body.has_method("take_damage"):
				body.take_damage(damage) # Le devolvemos su propio daño
			queue_free()
		elif not body.is_in_group("player"): # Choca con pared
			queue_free()
		return # Terminamos aquí para no hacer daño al jugador

	# CASO 2: COMPORTAMIENTO NORMAL (Busca matar al jugador)
	if body.is_in_group("player"):
		var bloqueo_exitoso = false
		
		# Solo intentamos calcular si el jugador está intentando bloquear
		if body.get("is_blocking"):
			# 1. Obtenemos hacia dónde mira el jugador
			# Asumimos que el nodo del sprite se llama "animaciones" como en tu script
			var sprite_jugador = body.get_node("animaciones")
			var mira_izquierda = sprite_jugador.flip_h
			
			# 2. Calculamos dónde está la bala respecto al jugador
			# Si (bala.x - jugador.x) es positivo, la bala está a la derecha
			var diferencia_x = global_position.x - body.global_position.x
			
			# 3. Verificamos coincidencia
			if mira_izquierda and diferencia_x < 0:
				# Mira izq y bala viene de la izq
				bloqueo_exitoso = true
			elif not mira_izquierda and diferencia_x > 0:
				# Mira der y bala viene de la der
				bloqueo_exitoso = true
				
		# --- RESULTADO FINAL ---
		if bloqueo_exitoso:
			reflexion_parry()
		else:
			# Si no bloquea, O si bloquea pero le dimos por la espalda -> DAÑO
			if body.has_method("take_damage"):
				body.take_damage(damage, global_position)
			queue_free()
			
	elif not body.is_in_group("enemy"): 
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

# Función para invertir el proyectil
func reflexion_parry():
	reflected = true
	direccion *= -1 # Invierte la dirección (Izquierda <-> Derecha)
	velocidad *= 1.5 # ¡Premio! Devuélvelo más rápido
	
	# Feedback visual (Opcional): Voltear el sprite o cambiar color
	rotation_degrees += 180 
	modulate = Color(0, 1, 1) # Se pone color cyan brillante
	
	print("¡PARRY EXITOSO!")
