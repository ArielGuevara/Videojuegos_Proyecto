extends CharacterBody2D

const SPEED = 300.0
const RUN_SPEED = 500.0
const JUMP_VELOCITY = -400.0

# --- ESTADOS ---
var appeared: bool = false
var attacking: bool = false
var is_crouching: bool = false 
var leaved_floor: bool = false
var had_jump: bool = false
var is_blocking: bool = false 

# --- VARIABLES DE VIDA ---
var max_health = 500
var current_health = 500
var is_invulnerable = false 

var distancia_ataque: float = 57.5

# --- CONFIGURACIÓN DE AGACHARSE ---
var stand_size_y: float = 0.0 
var stand_pos_y: float = 0.0 
var crouch_offset: float = 0.0 

@export var damage_amount = 20 

# Referencias
@onready var invul_timer = $InvulnerabilityTimer
@onready var health_bar = $CanvasLayer/BarraVida
@onready var collision_shape = $CollisionShape2D
@onready var ray_techo = $RayTecho 
@onready var ataque_colision = $AreaAtaque/CollisionShape2D 
@onready var area_ataque = $AreaAtaque 
# Referencia corta al AnimatedSprite para escribir menos
@onready var anim = $animaciones 

func _ready():
	current_health = max_health
	anim.play("appearing")
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	if collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
		if collision_shape.shape is RectangleShape2D:
			stand_size_y = collision_shape.shape.size.y
		elif collision_shape.shape is CapsuleShape2D:
			stand_size_y = collision_shape.shape.height
		stand_pos_y = collision_shape.position.y
		crouch_offset = stand_size_y * 0.5 
		
	if ataque_colision:
		ataque_colision.disabled = true

func _physics_process(delta: float) -> void:
	if current_health <= 0: return
	
	# 1. Si la variable dice que bloqueas, pero la animación NO es 'protected'...
	#    Significa que te quedaste bugeado. ¡Libera al jugador!
	if is_blocking and anim.animation != "protected":
		is_blocking = false
	
	# 2. Si la variable dice que atacas, pero la animación NO es 'attack_1'...
	#    ¡Libera al jugador y apaga el daño!
	if attacking and anim.animation != "attack_1":
		attacking = false
		ataque_colision.disabled = true

	# --- LÓGICA DE PARRY ---
	if Input.is_action_just_pressed("cover") and is_on_floor() and not is_blocking:
		if attacking:
			attacking = false
			ataque_colision.disabled = true 
		
		is_blocking = true
		anim.play("protected")
	
	if is_blocking:
		velocity.x = 0
		move_and_slide()
		return # Aquí es donde se atascaba antes
	
	if is_on_floor():
		leaved_floor = false
		had_jump = false
	
	# Gravedad
	if not is_on_floor():
		if not leaved_floor:
			$coyote_timer.start()
			leaved_floor = true
		velocity += get_gravity() * delta

	# --- LOGICA DE AGACHARSE ---
	if Input.is_action_pressed("ui_down") and is_on_floor():
		if not is_crouching:
			start_crouch()
	else:
		if is_crouching:
			if not ray_techo.is_colliding():
				stop_crouch()

	# --- SALTO Y ATAQUE ---
	if not is_crouching:
		if Input.is_action_just_pressed("ui_accept") and right_to_jump():
			velocity.y = JUMP_VELOCITY
		
		if Input.is_action_just_pressed("attack") and not attacking:
			attacking = true
			anim.play("attack_1")
			ataque_colision.disabled = false
			return 

	# --- MOVIMIENTO ---
	var direction := Input.get_axis("ui_left", "ui_right")
	var actual_speed := SPEED

	if Input.is_action_pressed("run_modifier") and direction != 0:
		actual_speed = RUN_SPEED

	if is_crouching:
		actual_speed = 0 
		velocity.x = 0   
	elif direction and not attacking: 
		velocity.x = direction * actual_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	decide_animation()

# --- FUNCIONES AUXILIARES ---
func start_crouch():
	is_crouching = true
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size.y = stand_size_y - crouch_offset
	elif collision_shape.shape is CapsuleShape2D:
		collision_shape.shape.height = stand_size_y - crouch_offset
	collision_shape.position.y = stand_pos_y + (crouch_offset / 2)

func stop_crouch():
	is_crouching = false
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size.y = stand_size_y
	elif collision_shape.shape is CapsuleShape2D:
		collision_shape.shape.height = stand_size_y
	collision_shape.position.y = stand_pos_y

func take_damage(amount: int, source_position: Vector2):
	if is_invulnerable or current_health <= 0:
		return
	
	# ### NUEVO: ROMPER ESTADOS AL RECIBIR DAÑO ###
	# Si te pegan, dejas de bloquear y de atacar inmediatamente.
	if is_blocking: is_blocking = false
	if attacking: 
		attacking = false
		ataque_colision.disabled = true
	# ---------------------------------------------

	current_health -= amount
	if health_bar:
		health_bar.value = current_health
	
	if current_health <= 0:
		die()
	else:
		get_hurt_feedback()
		apply_knockback(source_position)

func get_hurt_feedback():
	is_invulnerable = true
	invul_timer.start()
	modulate = Color(1, 0, 0)

func apply_knockback(source_pos):
	var knockback_dir = (global_position - source_pos).normalized()
	velocity = knockback_dir * 300
	velocity.y = -200 

func die():
	anim.play("dead")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

# --- ANIMACIONES ---
func decide_animation():
	if current_health <= 0: return
	if not appeared: return
	
	# Los returns aquí son importantes, pero gracias al "Auto-Curación" del principio
	# ya no son peligrosos.
	if is_blocking:
		anim.play("protected")
		return
	
	if attacking: 
		return

	if is_crouching:
		anim.play("crouch")
		return
		
	if anim.flip_h == true:
		area_ataque.position.x = -distancia_ataque
	else:
		area_ataque.position.x = distancia_ataque
	
	if velocity.y < 0:
		anim.play("jump_first")
		return 

	if velocity.x == 0:
		anim.play("idle_first")
	else:
		if velocity.x < 0:
			anim.flip_h = true
		elif velocity.x > 0:
			anim.flip_h = false
			
		if abs(velocity.x) > SPEED:
			anim.play("run_first")
		else:
			anim.play("walk_first")

func right_to_jump():
	if had_jump: return false
	if is_on_floor(): 
		had_jump = true
		return true
	elif not $coyote_timer.is_stopped(): 
		had_jump = true
		return true

func _on_animaciones_animation_finished() -> void:
	if anim.animation == "appearing":
		appeared = true
	
	# Reiniciamos estados cuando las animaciones terminan legítimamente
	if anim.animation == "attack_1":
		anim.play("idle_first")
		attacking = false
		ataque_colision.disabled = true
	
	if anim.animation == "protected":
		is_blocking = false
		anim.play("idle_first")

func _on_coyote_timer_timeout() -> void:
	pass

func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
	modulate = Color(1, 1, 1)

func _on_area_ataque_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
