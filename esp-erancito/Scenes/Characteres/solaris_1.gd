extends CharacterBody2D

# --- CONFIGURACIÓN ---
@export var max_health = 200
@export var speed = 100
@export var damage_touch = 10 
@export var projectile_scene: PackedScene 
@export var safe_distance = 150

#--------VARIABLES DE ATAUQE-----------
var is_dashing = false 
var dash_speed = 400   
var dash_duration = 0.5 

# --- ESTADOS ---
var current_health = 0
var direction = 1 
var is_enraged = false 
var target_player = null 

# --- NUEVA VARIABLE PARA EL DAÑO CONTINUO ---
var player_in_contact = null # Guardará al jugador si lo estamos tocando

# Referencias
@onready var anim = $AnimatedSprite2D
@onready var timer_ataque = $TimerAtaque 
@onready var punto_disparo = $PuntoDeDisparo 
@onready var ray_suelo = $RaySuelo
@onready var ray_muro = $RayMuro

func _ready():
	current_health = max_health
	anim.play("walk") 
	
	if timer_ataque.is_stopped():
		timer_ataque.start()

func _physics_process(delta):
	# 1. Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# --- NUEVO: Procesar daño por contacto en cada frame ---
	if player_in_contact and current_health > 0:
		# Intentamos dañar al jugador constantemente.
		# El script del jugador se encargará de rechazar el daño si está invulnerable.
		if player_in_contact.has_method("take_damage"):
			player_in_contact.take_damage(damage_touch, global_position)
	# -----------------------------------------------------

	# --- MODIFICACION DASH ---
	if is_dashing:
		velocity.x = direction * dash_speed
		move_and_slide()
		return 

	# 2. Si está en animación de crecer o atacar, no se mueve
	if anim.animation == "grow_up" and anim.is_playing():
		return
	if anim.animation == "attack" and anim.is_playing():
		velocity.x = 0 
		move_and_slide()
		return

	# 3. Lógica de Movimiento
	if target_player:
		perseguir_jugador()
	else:
		patrullar()
		velocity.x = direction * speed
	
	if velocity.x != 0 and (anim.animation != "attack" or not anim.is_playing()):
		anim.play("run" if is_enraged else "walk")
		
	move_and_slide()    

#----- ATAQUES ------
func iniciar_ataque_normal():
	anim.play("attack")
	call_deferred("lanzar_proyectil")
	
func iniciar_rafaga():
	anim.play("attack") 
	lanzar_proyectil()
	await get_tree().create_timer(0.3).timeout 
	
	if current_health > 0:
		anim.frame = 0 
		lanzar_proyectil()
		await get_tree().create_timer(0.3).timeout
	
	if current_health > 0:
		anim.frame = 0
		lanzar_proyectil()
		
func iniciar_embestida():
	modulate = Color(1, 0, 0) 
	velocity.x = 0
	await get_tree().create_timer(0.3).timeout
	
	if current_health > 0 and target_player:
		is_dashing = true
		anim.play("run" if is_enraged else "walk") 
		perseguir_jugador() 
		await get_tree().create_timer(dash_duration).timeout
		is_dashing = false
		modulate = Color(1, 1, 1) 
		velocity.x = 0 

# --- COMPORTAMIENTOS ---
func elegir_ataque():
	var dado = randf_range(0, 100)
	if dado < 50:
		iniciar_embestida()
	elif dado < 80:
		iniciar_rafaga()
	else:
		iniciar_ataque_normal()
		

func patrullar():
	if ray_muro.is_colliding() or not ray_suelo.is_colliding():
		cambiar_direccion()

func ray_muro_atras_detecta() -> bool:
	var vector_original = ray_muro.target_position
	ray_muro.target_position *= -1 
	ray_muro.force_raycast_update() 
	var colisiona = ray_muro.is_colliding()
	ray_muro.target_position = vector_original 
	return colisiona

func ray_suelo_atras_detecta() -> bool:
	var pos_original = ray_suelo.position.x
	ray_suelo.position.x *= -1 
	ray_suelo.force_raycast_update()
	var colisiona = ray_suelo.is_colliding()
	ray_suelo.position.x = pos_original 
	return colisiona

func perseguir_jugador():
	var diferencia = target_player.position.x - position.x
	var distancia_absoluta = abs(diferencia)
	var direccion_jugador = sign(diferencia) 
	
	if direccion_jugador > 0:
		anim.flip_h = false 
		punto_disparo.position.x = abs(punto_disparo.position.x)
		ray_suelo.position.x = abs(ray_suelo.position.x)
		ray_muro.target_position.x = abs(ray_muro.target_position.x)
		direction = 1 
	elif direccion_jugador < 0:
		anim.flip_h = true 
		punto_disparo.position.x = -abs(punto_disparo.position.x)
		ray_suelo.position.x = -abs(ray_suelo.position.x)
		ray_muro.target_position.x = -abs(ray_muro.target_position.x)
		direction = -1

	if distancia_absoluta > safe_distance:
		velocity.x = direction * speed
	elif distancia_absoluta < (safe_distance - 20): 
		var es_seguro_retroceder = not ray_muro_atras_detecta() and ray_suelo_atras_detecta()
		if es_seguro_retroceder:
			velocity.x = -direction * speed 
		else:
			velocity.x = 0 
	else:
		velocity.x = 0

func cambiar_direccion():
	direction *= -1 
	anim.flip_h = (direction == -1)
	ray_suelo.position.x *= -1
	ray_muro.target_position.x *= -1 
	punto_disparo.position.x = abs(punto_disparo.position.x) * direction

# --- COMBATE ---
func _on_timer_ataque_timeout():
	if current_health <= 0:
		return
	if target_player:
		elegir_ataque()

func lanzar_proyectil():
	var proyectil = projectile_scene.instantiate()
	get_parent().add_child(proyectil)
	proyectil.global_position = punto_disparo.global_position
	if target_player:
		var dir = (target_player.global_position - global_position).normalized()
		proyectil.direccion = dir
	else:
		proyectil.direccion = Vector2(direction, 0)

# --- DAÑO Y FASES ---
func take_damage(amount):
	current_health -= amount
	modulate = Color(10,10,10) 
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1), 0.1)
	
	if current_health <= 0:
		die()
	elif current_health <= (max_health / 2) and not is_enraged:
		activar_fase_2()

func activar_fase_2():
	is_enraged = true
	anim.play("grow_up")
	speed += 50 
	timer_ataque.wait_time = 1.0 

func die():
	timer_ataque.stop() 
	target_player = null 
	anim.play("desappearing")
	set_physics_process(false)
	$CollisionShape2D.call_deferred("set_disabled", true) 
	await anim.animation_finished
	queue_free()

# --- SEÑALES DE VISIÓN ---
func _on_area_deteccion_body_entered(body):
	if body.is_in_group("player"):
		target_player = body

func _on_area_deteccion_body_exited(body):
	if body == target_player:
		target_player = null
		if anim.animation == "attack":
			anim.play("run" if is_enraged else "walk")

# --- DAÑO POR CONTACTO ---

# 1. Cuando entras: Guardamos la referencia
func _on_hitbox_body_entered(body):
	if current_health <= 0: return
	
	if body.is_in_group("player"):
		player_in_contact = body # Guardamos al jugador en la variable

# 2. Cuando sales: Borramos la referencia (¡IMPORTANTE CONECTAR ESTA SEÑAL!)
func _on_hitbox_body_exited(body):
	if body == player_in_contact:
		player_in_contact = null # Ya no lo estamos tocando

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		anim.play("run" if is_enraged else "walk")
