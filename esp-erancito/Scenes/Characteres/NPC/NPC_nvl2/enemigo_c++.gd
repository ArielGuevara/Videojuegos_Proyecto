extends CharacterBody2D

# --- CONFIGURACIÓN ---
@export var velocidad = 100.0
@export var gravedad = 980.0
@export var escena_proyectil: PackedScene

# --- NODOS ---
@onready var anim = $AnimatedSprite2D
@onready var ray_suelo = $RayCast2D_suelo
@onready var ray_muro = $RayCast2D_muro
@onready var punto_disparo = $Marker2D
@onready var timer_disparo = $Timer 

# --- VARIABLES ---
enum Estado {PATRULLAR, DISPARAR, MORIR}
var estado_actual = Estado.PATRULLAR
var direccion = 1 
var puede_disparar = true 
var target_player = null 
var vida = 10 # La vida del enemigo

func _ready():
	timer_disparo.wait_time = 1.0
	timer_disparo.one_shot = true
	anim.play("patrullar")

func _physics_process(delta):
	if estado_actual == Estado.MORIR:
		return

	# 1. Gravedad
	if not is_on_floor():
		velocity.y += gravedad * delta

	# 2. MÁQUINA DE ESTADOS
	
	# Verificamos si la animación de disparo está activa REALMENTE
	var disparando_actualmente = (estado_actual == Estado.DISPARAR and anim.animation == "disparo" and anim.is_playing())
	
	if target_player:
		estado_actual = Estado.DISPARAR
		mirar_al_jugador()
	elif disparando_actualmente:
		# Si el jugador se fue pero estamos a mitad del disparo, terminamos de disparar
		estado_actual = Estado.DISPARAR
		velocity.x = 0 
	else:
		estado_actual = Estado.PATRULLAR

	# 3. COMPORTAMIENTO
	match estado_actual:
		Estado.PATRULLAR:
			comportamiento_patrullar()
		Estado.DISPARAR:
			comportamiento_disparar()

	move_and_slide()

# --- LÓGICA DE MOVIMIENTO ---

func mirar_al_jugador():
	if target_player == null: return

	var diferencia = target_player.global_position.x - global_position.x
	
	if diferencia > 0 and direccion == -1:
		cambiar_direccion(1)
	elif diferencia < 0 and direccion == 1:
		cambiar_direccion(-1)

func cambiar_direccion(nueva_dir):
	direccion = nueva_dir
	anim.flip_h = (direccion == -1)
	
	ray_suelo.position.x = abs(ray_suelo.position.x) * direccion
	ray_muro.target_position.x = abs(ray_muro.target_position.x) * direccion
	punto_disparo.position.x = abs(punto_disparo.position.x) * direccion

func comportamiento_patrullar():
	velocity.x = velocidad * direccion
	anim.play("patrullar")

	if is_on_floor():
		if ray_muro.is_colliding() or not ray_suelo.is_colliding():
			cambiar_direccion(direccion * -1)

func comportamiento_disparar():
	velocity.x = 0 
	
	# -- CORRECCIÓN AQUÍ --
	if not puede_disparar:
		if anim.animation != "disparo":
			if anim.animation != "patrullar":
				anim.play("patrullar")
				anim.stop() 
				anim.frame = 0
		return

	# Si llegamos aquí, es porque puede_disparar es TRUE.
	# Disparamos sin condiciones para desatascar la animación si hace falta.
	anim.play("disparo")
	puede_disparar = false

# --- COMBATE ---

func instanciar_proyectil():
	if escena_proyectil:
		var bala = escena_proyectil.instantiate()
		get_parent().add_child(bala)
		bala.global_position = punto_disparo.global_position
		
		if "direccion" in bala:
			bala.direccion = Vector2(direccion, 0)
		
		if direccion == -1:
			bala.rotation_degrees = 180
		else:
			bala.rotation_degrees = 0

# --- SEÑALES ---

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "disparo":
		instanciar_proyectil()
		timer_disparo.start()
		
		# Forzamos visualmente el cambio a patrulla para evitar bloqueos
		anim.play("patrullar") 
		
	elif anim.animation == "morir":
		queue_free()

func _on_timer_timeout():
	puede_disparar = true

# --- SEÑALES DEL AREA ---

func _on_area_deteccion_body_entered(body):
	if body.name == "boy1" or body.is_in_group("player"):
		target_player = body

func _on_area_deteccion_body_exited(body):
	if body == target_player:
		target_player = null

func take_damage(cantidad):
	vida -= cantidad
	modulate = Color(1, 0, 0) # Se pone rojo al recibir daño
	
	# Efecto visual rápido de parpadeo
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1), 0.2)
	
	if vida <= 0:
		morir()

func morir():
	estado_actual = Estado.MORIR
	anim.play("morir")
	# El queue_free() ya está en tu señal _on_animated_sprite_2d_animation_finished
