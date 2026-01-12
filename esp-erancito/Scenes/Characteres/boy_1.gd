extends CharacterBody2D


const SPEED = 300.0
const RUN_SPEED = 500.0
const JUMP_VELOCITY = -400.0
var appeared:bool = false
var attacking:bool = false
var leaved_floor: bool = false
var had_jump: bool = false
# ---  VARIABLES DE VIDA ---
var max_health = 100
var current_health = 100
var is_invulnerable = false # Para no recibir daño infinito

# Referencia al Timer
@onready var invul_timer = $InvulnerabilityTimer
@onready var health_bar = $CanvasLayer/BarraVida

func _ready():
	current_health = max_health
	$animaciones.play("appearing")
	
	# CONFIGURACIÓN INICIAL DE LA BARRA
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health


func _physics_process(delta: float) -> void:
	
	if current_health <= 0:
		return
	
	if is_on_floor():
		leaved_floor = false
		had_jump = false
	# Add the gravity.
	if not is_on_floor():
		if not leaved_floor:
			$coyote_timer.start()
			leaved_floor = true
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and right_to_jump():
		velocity.y = JUMP_VELOCITY
		
		# Detectar ataque
	if Input.is_action_just_pressed("attack") and not attacking:
		attacking = true
		$animaciones.play("attack_1")
		return  # No seguimos con el resto para no sobreescribir animación

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	var actual_speed := SPEED

	# Si Ctrl está presionado → correr
	if Input.is_action_pressed("run_modifier") and direction != 0:
		actual_speed = RUN_SPEED

	if direction:
		velocity.x = direction * actual_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	
	move_and_slide()
	decide_animation()
	#_on_animaciones_animation_finished()
	
# --- NUEVA FUNCIÓN: RECIBIR DAÑO ---
func take_damage(amount: int, source_position: Vector2):
	if is_invulnerable or current_health <= 0:
		print("El jugador es invulnerable, daño ignorado.")
		return
	current_health -= amount
	print("Vida bajó a: ", current_health)
	
	# ACTUALIZAR LA BARRA VISUALMENTE
	if health_bar:
		health_bar.value = current_health
		
	print("Vida restante: ", current_health)
	
	if current_health <= 0:
		die()
	else:
		get_hurt_feedback()
		apply_knockback(source_position)


func get_hurt_feedback():
	# Activar invulnerabilidad
	is_invulnerable = true
	invul_timer.start() 
	
	# Feedback visual: Parpadear en rojo
	modulate = Color(1, 0, 0) # Rojo puro
	
	# O reproducir animación de "hurt" si la tienes
	# $animaciones.play("hurt")

func apply_knockback(source_pos):
	# Calcular dirección contraria al golpe
	var knockback_dir = (global_position - source_pos).normalized()
	# Un pequeño empujón hacia arriba y atrás
	velocity = knockback_dir * 300
	velocity.y = -200 

func die():
	print("Jugador muerto")
	$animaciones.play("dead") # O tu animación de muerte
	# Aquí podrías reiniciar el nivel o mostrar pantalla de Game Over
	set_physics_process(false) # Desactivar controles
	
func decide_animation():
	if not appeared: return
	if attacking: return  
	# Eje de las x
	if velocity.x == 0:
		$animaciones.play("idle_first")
	elif velocity.x < 0:
		$animaciones.flip_h = true
		if abs(velocity.x) > SPEED:
			$animaciones.play("run_first")
		else:
			$animaciones.play("walk_first")
	elif velocity.x > 0:
		$animaciones.flip_h = false
		if abs(velocity.x) > SPEED:
			$animaciones.play("run_first")
		else:
			$animaciones.play("walk_first")
		
	#Eje de las Y
	if velocity.y > 0:
		$animaciones.play("idle_first")
	elif velocity.y < 0:
		$animaciones.play("jump_first")
		

func right_to_jump():
	if had_jump: return false
	if is_on_floor(): 
		had_jump = true
		return true
	elif not $coyote_timer.is_stopped(): 
		had_jump = true
		return true

func _on_animaciones_animation_finished() -> void:
	if $animaciones.animation == "appearing":
		appeared = true
	if $animaciones.animation == "attack_1":
		$animaciones.play("idle_first")
		attacking = false


func _on_coyote_timer_timeout() -> void:
	pass;


func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
	modulate = Color(1, 1, 1)
