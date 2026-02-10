extends Area2D

@export var velocidad = 400
@export var dano = 10 

var direccion = Vector2.RIGHT 
var reflejado = false # <--- Nueva variable para saber si ya rebotó

func _physics_process(delta):
	position += direccion * velocidad * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	
	# --- CASO A: LA BALA YA FUE REFLEJADA (Ahora mata enemigos) ---
	if reflejado:
		# Si toca al enemigo original o a cualquier otro enemigo
		if body.is_in_group("enemigo") or body.name == "enemigo_c++":
			if body.has_method("take_damage"):
				body.take_damage(dano * 2) # ¡Le hacemos doble daño por el parry!
			queue_free()
		# Si toca al jugador de nuevo, lo ignoramos (no se hace daño a sí mismo)
		return

	# --- CASO B: COMPORTAMIENTO NORMAL (Busca matar al jugador) ---
	if body.name == "boy_1" or body.is_in_group("jugador"):
		
		# 1. VERIFICAR BLOQUEO
		if body.get("is_blocking"):
			var graficos = body.get_node_or_null("Graficos")
			if graficos:
				var mira_derecha = graficos.scale.x > 0
				var bala_va_derecha = direccion.x > 0
				
				# ¿Está bloqueando en la dirección correcta?
				# (Si bala va a derecha, jugador debe mirar izquierda para bloquear de frente)
				# (Si bala va a izquierda, jugador debe mirar derecha)
				var bloqueo_exitoso = (bala_va_derecha and not mira_derecha) or (not bala_va_derecha and mira_derecha)
				
				if bloqueo_exitoso:
					activar_reflejo()
					return # ¡IMPORTANTE! Salimos aquí para no hacer daño

		# 2. APLICAR DAÑO (Si no bloqueó)
		if body.has_method("take_damage"):
			body.take_damage(dano, global_position)
			if body.has_method("apply_knockback"):
				var fuerza = direccion.normalized() * 300
				fuerza.y = -150
				body.apply_knockback(fuerza)
		
		queue_free()
		
	# Si choca con pared o suelo (y no ha sido reflejado)
	elif not body.is_in_group("enemigo") and body.name != "enemigo_c++":
		queue_free()

func activar_reflejo():
	reflejado = true
	
	# 1. Invertimos la dirección
	direccion = direccion * -1 
	
	# 2. Aumentamos velocidad (Premio por habilidad)
	velocidad *= 1.5 
	
	# 3. Giramos visualmente la bala 180 grados
	rotation_degrees += 180 
	
	# 4. Cambiamos color para que se vea que ahora es "poderosa"
	modulate = Color(0, 1, 1) # Cyan brillante (o el color que quieras)
	
	print("¡PARRY! Bala devuelta al enemigo")
