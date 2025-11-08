extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var appeared:bool = false


func _ready():
	$animaciones.play("appearing")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	decide_animation()
func decide_animation():
	if not appeared: return
	
	# Eje de las x
	if velocity.x == 0:
		$animaciones.play("idle")
	elif velocity.x < 0:
		$animaciones.flip_h = true
		$animaciones.play("run")
	elif velocity.x > 0:
		$animaciones.flip_h = false
		$animaciones.play("run")
		
	#Eje de las Y
	if velocity.y > 0:
		$animaciones.play("fall")
	elif velocity.y < 0:
		$animaciones.play("jump_up")
		


func _on_animaciones_animation_finished() -> void:
	if $animaciones.animation == "appeared":
		appeared = true
