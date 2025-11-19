extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var appeared:bool = false
var attacking:bool = false


func _ready():
	$animaciones.play("appearing")


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
		# Detectar ataque
	if Input.is_action_just_pressed("attack") and not attacking:
		attacking = true
		$animaciones.play("attack_1")
		return  # No seguimos con el resto para no sobreescribir animación

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
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
		$animaciones.play("idle")
	elif velocity.x < 0:
		$animaciones.flip_h = true
		$animaciones.play("walk")
	elif velocity.x > 0:
		$animaciones.flip_h = false
		$animaciones.play("walk")
		
	#Eje de las Y
	if velocity.y > 0:
		$animaciones.play("idle")
	elif velocity.y < 0:
		$animaciones.play("jump")
		

func _on_animaciones_animation_finished() -> void:
	print($animaciones.animation)
	if $animaciones.animation == "appearing":
		appeared = true
	if $animaciones.animation == "attack_1":
		$animaciones.play("idle")
		attacking = false
