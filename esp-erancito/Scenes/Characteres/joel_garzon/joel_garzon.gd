extends CharacterBody2D

# --- CONFIGURACIÓN ---
@export var max_health = 500
@export var speed_normal = 150
@export var speed_dash = 500
@export var damage_dash = 20
# CAMBIO 1: Reducimos la distancia mínima para que no huya tan rápido
@export var distancia_minima = 80 
@export var distancia_maxima = 500

# --- ESCENAS DE LOS MINIONS ---
@export var escena_pi: PackedScene
@export var escena_sumatoria: PackedScene
@export var escena_integral: PackedScene

# --- REFERENCIAS ---
@onready var graficos = $Graficos
@onready var anim = $Graficos/AnimatedSprite2D
@onready var punto_spawn = $Graficos/PuntoSpawn
@onready var timer_spawn = $TimerSpawn
@onready var timer_embestida = $TimerEmbestida
@onready var barra_vida = $CanvasLayer/BarraVida
@onready var collision_shape = $CollisionShape2D
@onready var tag_life = $CanvasLayer/Label

# CAMBIO 2: Nueva referencia al sensor trasero
# Asegúrate de haber creado el nodo RayAtras dentro de Graficos
@onready var ray_atras = $Graficos/RayAtras 

# --- ESTADOS ---
enum Estado { IDLE, KITING, SUMMONING, DASHING, DEAD, STUNNED }
var estado_actual = Estado.IDLE

var current_health = 0
var target_player = null
var direction = 1
var dash_direction = Vector2.ZERO 
var color_base = Color(1, 1, 1)

func _ready():
	add_to_group("boss")
	add_to_group("enemy")
	
	current_health = max_health
	barra_vida.max_value = max_health
	barra_vida.value = current_health
	barra_vida.visible = false 
	tag_life.visible = false
	
	anim.play("idle")

func _physics_process(delta):
	if estado_actual == Estado.DEAD: 
		if not is_on_floor(): velocity += get_gravity() * delta
		move_and_slide()
		return

	# Gravedad estándar
	if not is_on_floor():
		velocity += get_gravity() * delta

	match estado_actual:
		Estado.DASHING:
			procesar_embestida(delta)
		Estado.SUMMONING:
			velocity.x = 0
		Estado.STUNNED:
			velocity.x = move_toward(velocity.x, 0, 10)
		_:
			if target_player: 
				comportamiento_kiting(delta)
			else:
				velocity.x = move_toward(velocity.x, 0, speed_normal * delta)
			
	move_and_slide()
	
	if estado_actual == Estado.DASHING:
		verificar_colision_con_jugador()

# --- LÓGICA DE MOVIMIENTO (Kiting) MEJORADA ---
func comportamiento_kiting(delta):
	var dist_x = abs(global_position.x - target_player.global_position.x)
	var dir_x = sign(target_player.global_position.x - global_position.x)
	
	# Orientación visual (Mirar siempre al jugador)
	if dir_x != 0:
		direction = dir_x
		actualizar_orientacion()

	if dist_x > distancia_maxima:
		# Jugador lejos -> Acercarse
		velocity.x = dir_x * speed_normal
		anim.play("walk")
		
	elif dist_x < distancia_minima:
		# Jugador cerca -> Intentar Huir
		
		# CAMBIO 3: PREGUNTAR AL SENSOR TRASERO ANTES DE MOVERSE
		# Como el RayAtras está en el talón, si no detecta suelo, 
		# significa que hay un precipicio detrás.
		if ray_atras.is_colliding():
			velocity.x = -dir_x * speed_normal # Huir (Retroceder)
			anim.play("walk") # O animación de caminar hacia atrás
		else:
			# Si hay precipicio, nos plantamos firmes y no retrocedemos más
			velocity.x = 0
			anim.play("idle")
			
	else:
		# Distancia ideal -> Mantener posición
		velocity.x = move_toward(velocity.x, 0, speed_normal * delta)
		anim.play("idle")

func actualizar_orientacion():
	if direction == 1:
		graficos.scale.x = 1
	else:
		graficos.scale.x = -1

# ... (EL RESTO DEL SCRIPT SIGUE EXACTAMENTE IGUAL ABAJO) ...
# Copia aquí el resto de tus funciones: embestida, spawn, daño, recibir_impacto, etc.
# No olvides mantener la función recibir_impacto_simbolo tal cual la tenías.

# ---------------- SECCIÓN DE PEGAR LO DEMÁS ---------------- 
# (Solo pongo el inicio de las funciones para que te ubiques, pero usa tu código anterior para rellenar)

func _on_timer_embestida_timeout():
	if not target_player or estado_actual == Estado.DEAD or estado_actual == Estado.SUMMONING: return
	if randf() < 0.3: iniciar_embestida()

func iniciar_embestida():
	estado_actual = Estado.DASHING
	anim.play("run")
	var dir = (target_player.global_position - global_position).normalized()
	dash_direction = Vector2(sign(dir.x), 0)
	if dash_direction == Vector2.ZERO: dash_direction = Vector2(direction, 0)
	velocity.y = -200 
	await get_tree().create_timer(1.0).timeout
	if estado_actual == Estado.DASHING: estado_actual = Estado.IDLE

func procesar_embestida(delta):
	velocity.x = dash_direction.x * speed_dash

func verificar_colision_con_jugador():
	for i in get_slide_collision_count():
		var colision = get_slide_collision(i)
		var collider = colision.get_collider()
		if collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage_dash, global_position)
				estado_actual = Estado.IDLE
				velocity.x = -dash_direction.x * 200

func _on_timer_spawn_timeout():
	if not target_player or estado_actual != Estado.IDLE: return
	estado_actual = Estado.SUMMONING
	velocity.x = 0
	var probabilidad = randi() % 100 
	var escena_a_invocar = null
	if probabilidad < 50: 
		anim.play("atack_pi")
		escena_a_invocar = escena_pi
	elif probabilidad < 70: 
		anim.play("atack_sumatoria")
		escena_a_invocar = escena_sumatoria
	elif probabilidad < 80: 
		anim.play("atack_integral")
		escena_a_invocar = escena_integral
	else:
		estado_actual = Estado.IDLE
		return
	await get_tree().create_timer(0.5).timeout 
	if escena_a_invocar and estado_actual != Estado.DEAD: invocar_enemigo(escena_a_invocar)
	await anim.animation_finished
	if estado_actual != Estado.DEAD: estado_actual = Estado.IDLE

func invocar_enemigo(escena: PackedScene):
	if not escena: return
	var nuevo = escena.instantiate()
	get_parent().add_child(nuevo)
	nuevo.global_position = punto_spawn.global_position

func take_damage(amount, _source_pos = Vector2.ZERO):
	if estado_actual == Estado.DEAD: return
	current_health -= amount
	barra_vida.value = current_health
	modulate = Color(1, 0, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", color_base, 0.1)
	if current_health <= 0: die()

func recibir_impacto_simbolo(tipo_recibido):
	var dano_recibido = 0
	match tipo_recibido:
		0: dano_recibido = 50 
		1: 
			dano_recibido = 30
			aplicar_congelamiento()
		2: 
			dano_recibido = 80
			aplicar_knockback()
	take_damage(dano_recibido)

func aplicar_congelamiento():
	color_base = Color(0.3, 0.3, 1) 
	modulate = color_base 
	var velocidad_original = speed_normal
	speed_normal = 20 
	await get_tree().create_timer(3.0).timeout
	if estado_actual != Estado.DEAD:
		speed_normal = velocidad_original
		color_base = Color(1, 1, 1) 
		modulate = color_base

func aplicar_knockback():
	var estado_anterior = estado_actual
	estado_actual = Estado.STUNNED 
	velocity.x = -direction * 400 
	velocity.y = -150 
	anim.play("idle") 
	await get_tree().create_timer(0.5).timeout
	if estado_actual != Estado.DEAD: estado_actual = Estado.IDLE

func die():
	estado_actual = Estado.DEAD
	anim.play("die")
	velocity.x = 0
	
	# Detener timers
	timer_spawn.stop()
	timer_embestida.stop()
	
	barra_vida.visible = false
	tag_life.visible = false
	
	collision_layer = 0 
	collision_mask = 1 # Asegúrate que la máscara 1 sea el suelo en tu proyecto
	
	await anim.animation_finished
	queue_free()

func _on_area_deteccion_body_entered(body):
	if body.is_in_group("player"):
		target_player = body
		barra_vida.visible = true 
		tag_life.visible = true
		timer_spawn.start()
		timer_embestida.start()

func _on_area_deteccion_body_exited(body):
	if body == target_player:
		target_player = null
		barra_vida.visible = false 
		tag_life.visible = false
		timer_spawn.stop()
		timer_embestida.stop()
		velocity.x = 0
		if estado_actual != Estado.DEAD:
			estado_actual = Estado.IDLE
			anim.play("idle")
