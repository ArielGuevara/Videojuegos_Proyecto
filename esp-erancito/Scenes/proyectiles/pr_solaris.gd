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
			if body.has_method("take_damage"):
				body.take_damage(damage)
			queue_free()
		elif not body.is_in_group("player"): 
			queue_free()
		return

	# CASO 2: COMPORTAMIENTO NORMAL (Busca matar al jugador)
	if body.is_in_group("player"):
		var bloqueo_exitoso = false
		
		# Solo calculamos si el jugador está bloqueando
		if body.get("is_blocking"):
			
			# --- CORRECCIÓN AQUÍ ---
			# 1. Obtenemos el nodo contenedor que tiene la escala
			var graficos = body.get_node("Graficos")
			
			# 2. Determinamos si mira a la izquierda basándonos en la escala
			# Si la escala es -1, mira a la izquierda. Si es 1, mira a la derecha.
			var mira_izquierda = graficos.scale.x < 0
			# -----------------------
			
			# 3. Calculamos dónde está la bala respecto al jugador
			var diferencia_x = global_position.x - body.global_position.x
			
			# 4. Verificamos coincidencia
			if mira_izquierda and diferencia_x < 0:
				# Mira izq y bala viene de la izq (diferencia negativa) -> BLOQUEA
				bloqueo_exitoso = true
			elif not mira_izquierda and diferencia_x > 0:
				# Mira der y bala viene de la der (diferencia positiva) -> BLOQUEA
				bloqueo_exitoso = true
				
		# --- RESULTADO FINAL ---
		if bloqueo_exitoso:
			reflexion_parry()
		else:
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
	
