extends CharacterBody2D

var bala_scene = preload("res://Scenes/Characteres/NPC/NPC_nvl2/Proyectil_C++.tscn")

enum Estado { PATRULLA, ATAQUE }
var estado_actual = Estado.PATRULLA

@export var velocidad = 50.0
var direccion = 1 

@onready var sprite = $AnimatedSprite2D
@onready var ray_suelo = $RayCast2D_suelo
@onready var ray_muro = $RayCast2D_muro
@onready var timer_disparo = $Timer
@onready var marker_disparo = $Marker2D

func _ready():
	$Area2D.body_entered.connect(_al_ver_jugador)
	$Area2D.body_exited.connect(_al_perder_jugador)
	
	if timer_disparo.timeout.is_connected(_on_timer_timeout) == false:
		timer_disparo.timeout.connect(_on_timer_timeout)

func _physics_process(delta):
	# Gravedad simple (opcional, ayuda a que no floten si hay desniveles)
	if not is_on_floor():
		velocity += get_gravity() * delta

	if estado_actual == Estado.PATRULLA:
		comportamiento_patrulla(delta)
	elif estado_actual == Estado.ATAQUE:
		comportamiento_ataque()
	
	move_and_slide()

func comportamiento_patrulla(delta):
	velocity.x = direccion * velocidad
	sprite.play("walk") 
	
	### CORRECCIÓN 1: ANTI-MOONWALK ###
	# Forzamos que la vista coincida SIEMPRE con la velocidad
	if velocity.x > 0:
		scale.x = abs(scale.x) * 1 # Mirar derecha
	elif velocity.x < 0:
		scale.x = abs(scale.x) * -1 # Mirar izquierda
	
	if not ray_suelo.is_colliding() or ray_muro.is_colliding():
		girar()

func comportamiento_ataque():
	velocity.x = 0
	sprite.play("disparo")

func girar():
	direccion *= -1
	
	### CORRECCIÓN 2: ANTI-GLITCH ###
	# Empujamos al NPC un poquito lejos del borde/pared para que el RayCast
	# deje de detectar el peligro inmediatamente.
	position.x += direccion * 10 

# --- SEÑALES Y DISPARO (Esto estaba bien) ---

func _al_ver_jugador(body):
	# Usamos grupos para asegurar detección
	if body.name == "Esperancito" or body.is_in_group("jugador"):
		estado_actual = Estado.ATAQUE
		timer_disparo.start()

func _al_perder_jugador(body):
	if body.name == "Esperancito" or body.is_in_group("jugador"):
		estado_actual = Estado.PATRULLA
		timer_disparo.stop()

func _on_timer_timeout():
	if estado_actual == Estado.ATAQUE:
		var bala = bala_scene.instantiate()
		bala.global_position = marker_disparo.global_position
		
		# Usamos scale.x para la dirección de la bala
		if scale.x > 0: 
			bala.direccion = Vector2.RIGHT
		else:
			bala.direccion = Vector2.LEFT
			
		get_parent().add_child(bala)
