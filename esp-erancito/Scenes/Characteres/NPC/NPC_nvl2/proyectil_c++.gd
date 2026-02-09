extends Area2D

@export var velocidad = 300.0
@export var damage = 10
var direccion = Vector2.RIGHT 
var reflejada = false 

func _ready():
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	body_entered.connect(_al_chocar)

func _physics_process(delta):
	position += direccion * velocidad * delta
	$Sprite2D.rotation += 10 * delta

func _al_chocar(body):
	# CASO 1: Choca con Esperancito
	if body.name == "Esperancito" and not reflejada:
		# --- AQUÍ ESTÁ LA CLAVE ---
		# Verificamos la variable 'is_blocking' que YA TIENES en tu script
		if body.get("is_blocking") == true:
			reflejar_proyectil() # <--- ¡Si bloquea, rebota!
		else:
			# Si no bloquea, le hacemos daño
			if body.has_method("take_damage"):
				body.take_damage(damage, global_position)
			queue_free() # La bala desaparece
	
	# CASO 2: Choca con el Enemigo (SÍ ha sido reflejada)
	elif body.is_in_group("enemigo") and reflejada:
		if body.has_method("morir"):
			body.morir()
		queue_free()
	
	# CASO 3: Paredes
	elif not body.is_in_group("jugador"):
		queue_free()

func reflejar_proyectil():
	if not reflejada:
		reflejada = true
		velocidad *= 1.5
		direccion *= -1 # Se devuelve
		modulate = Color(0, 1, 0) # Se pone verde
		# Cambiamos máscara para que atraviese al jugador y golpee al enemigo
		set_collision_mask_value(2, false) # Ignora capa 2 (Jugador)
		set_collision_mask_value(3, true)  # Golpea capa 3 (Enemigos)
		print("¡Parry realizado usando is_blocking!")
