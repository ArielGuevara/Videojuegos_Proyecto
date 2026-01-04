extends CharacterBody2D


const SPEED = 300.0
const RUN_SPEED = 500.0
const JUMP_VELOCITY = -400.0
var appeared:bool = false
var attacking:bool = false
var leaved_floor: bool = false
var had_jump: bool = false


func _ready():
	$animaciones.play("appearing")


func _physics_process(delta: float) -> void:
	
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
