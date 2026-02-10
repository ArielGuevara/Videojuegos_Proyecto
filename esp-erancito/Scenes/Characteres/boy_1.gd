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
var is_knocked_back = false # Variable de control para el empuje

# --- VARIABLES DE VIDA ---
var max_health = 100
var current_health = 100
var is_invulnerable = false 

var distancia_ataque: float = 57.5
var respawn_position: Vector2

# --- CONFIGURACIÓN DE AGACHARSE ---
var stand_size_y: float = 0.0 
var stand_pos_y: float = 0.0 
var crouch_offset: float = 0.0 

@export var damage_amount = 20 
@export var limite_caida = 1000

# Referencias
@onready var invul_timer = $InvulnerabilityTimer
@onready var health_bar = $CanvasLayer/BarraVida
@onready var collision_shape = $CollisionShape2D

@onready var graficos = $Graficos 
@onready var anim = $Graficos/animaciones # <--- Actualizado
@onready var area_ataque = $Graficos/AreaAtaque # <--- Actualizado
@onready var ataque_colision = $Graficos/AreaAtaque/CollisionShape2D # <--- Actualizado
@onready var ray_techo = $Graficos/RayTecho # <--- Actualizadones 

func _ready():
	respawn_position = global_position # El inicio del nivel es el primer checkpoint
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
	
	# Gravedad (Siempre aplica, incluso si te empujan)
	if not is_on_floor():
		if not leaved_floor:
			$coyote_timer.start()
			leaved_floor = true
		velocity += get_gravity() * delta
		
	if global_position.y > limite_caida:
		current_health = 0 # Aseguramos que la vida sea 0
		die() # Llamamos a la función de muerte que ya tienes
		return # Salimos para no procesar más movimiento

	# --- 1. MODIFICACIÓN CRÍTICA: KNOCKBACK ---
	# Si estamos siendo empujados, ignoramos los Inputs del jugador
	if is_knocked_back:
		move_and_slide()
		return # <-- "return" aquí evita que el código de abajo (caminar/saltar) se ejecute
	# ------------------------------------------
	
	# Chequeos de seguridad (anti-bug)
	if is_blocking and anim.animation != "protected":
		is_blocking = false
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
		return 
	
	if is_on_floor():
		leaved_floor = false
		had_jump = false

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
			print("🗡️ ESPERANCITO: ¡Iniciando ataque!")
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
	
	# Romper estados
	if is_blocking: is_blocking = false
	if attacking: 
		attacking = false
		ataque_colision.disabled = true

	current_health -= amount
	if health_bar:
		health_bar.value = current_health
	
	if current_health <= 0:
		die()
	else:
		get_hurt_feedback()
		# --- MODIFICACIÓN 3: ELIMINAR LLAMADA AUTOMÁTICA ---
		# Eliminé "apply_knockback(source_position)" de aquí.
		# ¿Por qué? Porque el script del Enemigo Sumatoria ya calcula la fuerza
		# y llama a "apply_knockback" explícitamente después de "take_damage".
		# Si lo dejamos aquí, daría error de tipos (Vector vs Position).

func get_hurt_feedback():
	is_invulnerable = true
	invul_timer.start()
	modulate = Color(1, 0, 0)

# --- 2. MODIFICACIÓN: FUNCIÓN DE EMPUJE CORRECTA ---
func apply_knockback(fuerza_vector: Vector2):
	# 1. Aplicamos la velocidad directa (el golpe)
	velocity = fuerza_vector
	
	# 2. Bloqueamos el control
	is_knocked_back = true
	
	# 3. Importante: no usamos move_and_slide aquí porque _physics_process
	# lo hará en el siguiente frame, pero si quieres efecto inmediato:
	move_and_slide()
	
	# 4. Esperamos un poco antes de devolver el control
	await get_tree().create_timer(0.3).timeout
	
	# 5. Devolvemos control
	is_knocked_back = false
# ---------------------------------------------------

func die():
	anim.play("dead")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	is_invulnerable = true
	
	# (Puedes usar anim.animation_finished si prefieres esperar a que termine la animación exacta)
	await get_tree().create_timer(1.5).timeout 
	# --- RESPAWN (REVIVIR) ---
	# 1. Teletransportar al último checkpoint
	global_position = respawn_position
	
	# 2. Restaurar vida y variables
	current_health = max_health
	if health_bar:
		health_bar.value = current_health
	
	# 3. Resetear estados negativos
	is_knocked_back = false
	attacking = false
	is_blocking = false
	
	# 4. Reactivar físicas y colisiones
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	
	# 5. Dar un momento de invulnerabilidad al revivir (opcional pero recomendado)
	anim.play("appearing") # O "idle_first" si prefieres
	await get_tree().create_timer(1.0).timeout
	is_invulnerable = false

# --- ANIMACIONES ---
func decide_animation():
	if current_health <= 0: return
	if not appeared: return
	
	# Si estás siendo empujado, podrías poner una animación de daño (opcional)
	if is_knocked_back:
		# anim.play("hurt") # Si tienes animación de herido, ponla aquí
		return

	if is_blocking:
		anim.play("protected")
		return
	
	if attacking: 
		return

	if is_crouching:
		anim.play("crouch")
		return
		
	if velocity.y < 0:
		anim.play("jump_first")
		return 

	if velocity.x == 0:
		anim.play("idle_first")
	else:
		if velocity.x < 0:
			graficos.scale.x = -1 
		elif velocity.x > 0:
			# Mirar derecha: Escala normal
			graficos.scale.x = 1
			
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
			body.take_damage(damage_amount, global_position)
		else:
			print("❌ NO tiene método take_damage")  # ⬅ AGREGAR
	else:
		print("❌ NO está en grupo 'enemy'")  # ⬅ AGREGAR

# Funciones de los NPC 
func congelar(tiempo):
	set_physics_process(false) # Detiene el movimiento
	modulate = Color(0, 0, 1) # Se pone azul
	anim.pause() # Pausa la animación
	
	await get_tree().create_timer(tiempo).timeout
	
	set_physics_process(true)
	modulate = Color(1, 1, 1)
	anim.play()

func actualizar_checkpoint(nueva_posicion: Vector2):
	respawn_position = nueva_posicion
	print("Checkpoint guardado en: ", respawn_position)
