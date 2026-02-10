extends CharacterBody2D

# === CONFIGURACIÓN DEL BOSS ===
@export var max_health = 200
@export var speed_fase1 = 200
@export var speed_fase2 = 350
@export var damage_fase1 = 20
@export var damage_fase2 = 35
@export var distancia_ataque = 150    # ⬅️ AUMENTADO de 80 a 150
@export var distancia_deteccion = 600

# === ESTADO ===
enum Estado { IDLE, PERSIGUIENDO, ATACANDO, TRANSFORMANDO, MUERTO }
var estado_actual = Estado.IDLE       # ⬅️ CAMBIO: Empieza en IDLE, no APARECIENDO
var current_health = 200
var target_player = null
var is_transformed = false
var can_attack = true
var direction = 1

# === REFERENCIAS ===
@onready var anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var area_deteccion = $AreaDeteccion
@onready var area_ataque = $AreaAtaque
@onready var timer_ataque = $TimerAtaque
@onready var barra_vida = $CanvasLayer/BarraVida
@onready var label_nombre = $CanvasLayer/LabelNombre

func _ready():
	add_to_group("enemy")
	add_to_group("boss")
	print("🎯 BOSS: Inicializado - Vida: ", max_health)
	
	current_health = max_health
	
	# Configurar barra de vida
	if barra_vida:
		barra_vida.max_value = max_health
		barra_vida.value = current_health
		barra_vida.visible = false
	
	if label_nombre:
		label_nombre.visible = false
	
	# ⬅️ CAMBIO: Empieza directo en IDLE con animación "wait"
	anim.play("wait")
	estado_actual = Estado.IDLE
	# set_physics_process ya está activo por defecto
	
	# Conectar señales
	area_deteccion.body_entered.connect(_on_deteccion_jugador_entered)
	area_deteccion.body_exited.connect(_on_deteccion_jugador_exited)
	area_ataque.body_entered.connect(_on_area_ataque_body_entered)
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)
	
	print("✅ BOSS: Listo para pelear!")

func _physics_process(delta):
	if estado_actual == Estado.MUERTO:
		return
	
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match estado_actual:
		Estado.IDLE:
			comportamiento_idle()
		Estado.PERSIGUIENDO:
			comportamiento_perseguir()
		Estado.ATACANDO:
			comportamiento_atacar()
		Estado.TRANSFORMANDO:
			velocity.x = 0
	
	move_and_slide()

# === COMPORTAMIENTOS ===
func comportamiento_idle():
	velocity.x = move_toward(velocity.x, 0, 10)
	if not anim.is_playing() or anim.animation != "wait":
		anim.play("wait")

func comportamiento_perseguir():
	if not target_player:
		estado_actual = Estado.IDLE
		return
	
	var distancia = abs(global_position.x - target_player.global_position.x)
	var dir_jugador = sign(target_player.global_position.x - global_position.x)
	
	# Actualizar orientación
	if dir_jugador != 0:
		direction = dir_jugador
		actualizar_flip()
	
	# Si está cerca, atacar
	if distancia <= distancia_ataque and can_attack:
		iniciar_ataque()
		return
	
	# Perseguir al jugador
	var velocidad_actual = speed_fase2 if is_transformed else speed_fase1
	velocity.x = direction * velocidad_actual
	
	# Animación de correr
	if is_transformed:
		if anim.animation != "caminar" or not anim.is_playing():
			anim.play("caminar")
	else:
		if anim.animation != "caminar" or not anim.is_playing():
			anim.play("caminar")

func comportamiento_atacar():
	velocity.x = 0
	# La animación se encarga del timing

func actualizar_flip():
	if direction > 0:
		anim.flip_h = false
		# ⬅️ NUEVO: Mover área de ataque según dirección
		area_ataque.get_node("CollisionShape2D").position.x = 125
	else:
		anim.flip_h = true
		# ⬅️ NUEVO: Mover área de ataque según dirección
		area_ataque.get_node("CollisionShape2D").position.x = -125

# === SISTEMA DE COMBATE ===
func iniciar_ataque():
	estado_actual = Estado.ATACANDO
	can_attack = false
	
	print("⚔️ BOSS: Iniciando ataque!")  # ⬅️ DEBUG
	
	if is_transformed:
		anim.play("atack2") # Ataque monstruo más rápido
	else:
		anim.play("atack1") # Envestir normal

	# Intentar aplicar daño en el momento del impacto,
	# incluso si el jugador ya estaba dentro del área.
	aplicar_daño_despues_de_inicio_ataque()

	timer_ataque.start()

# Aplica daño si el jugador está dentro del AreaAtaque cuando el golpe "conecta"
func aplicar_daño_despues_de_inicio_ataque():
	# Pequeño retraso para sincronizar con la animación de ataque
	await get_tree().create_timer(0.25).timeout
	
	if estado_actual != Estado.ATACANDO:
		return
	
	for body in area_ataque.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			var daño = damage_fase2 if is_transformed else damage_fase1
			body.take_damage(daño, global_position)
			
			# Retroceso de Esperancito cuando el golpe conecta
			if body.has_method("apply_knockback"):
				var dir: Vector2 = (body.global_position - global_position).normalized()
				var fuerza: Vector2 = Vector2(dir.x * 700, -250)
				body.apply_knockback(fuerza)
			break

func _on_timer_ataque_timeout():
	can_attack = true
	if estado_actual == Estado.ATACANDO:
		estado_actual = Estado.PERSIGUIENDO

func _on_area_ataque_body_entered(body):
	print("💥 BOSS: AreaAtaque detectó: ", body.name)  # ⬅️ DEBUG
	
	if body.is_in_group("player") and estado_actual == Estado.ATACANDO:
		print("✅ BOSS: ¡Golpeando al jugador!")  # ⬅️ DEBUG
		if body.has_method("take_damage"):
			var daño = damage_fase2 if is_transformed else damage_fase1
			body.take_damage(daño, global_position)
			
			# Retroceso inmediato si entra en el área durante el ataque
			if body.has_method("apply_knockback"):
				var dir: Vector2 = (body.global_position - global_position).normalized()
				var fuerza: Vector2 = Vector2(dir.x * 700, -250)
				body.apply_knockback(fuerza)

# === SISTEMA DE DAÑO ===
func take_damage(amount: int, _source_position: Vector2 = Vector2.ZERO):
	print("🩸 BOSS: take_damage() llamado - Daño: ", amount)
	
	if estado_actual == Estado.MUERTO or estado_actual == Estado.TRANSFORMANDO:
		print("⚠️ BOSS: Daño bloqueado (muerto o transformando)")
		return
	
	current_health -= amount
	print("❤️ BOSS: Vida actual: ", current_health, "/", max_health)
	
	# Actualizar barra de vida
	if barra_vida:
		barra_vida.value = current_health
		print("📊 BOSS: Barra actualizada a: ", current_health)
	
	# Feedback visual
	modulate = Color(10, 10, 10)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	
	# Comprobar si debe transformarse
	if current_health <= (max_health / 2) and not is_transformed:
		iniciar_transformacion()
	# Comprobar muerte
	elif current_health <= 0:
		morir()

func iniciar_transformacion():
	estado_actual = Estado.TRANSFORMANDO
	is_transformed = true
	velocity.x = 0
	
	print("🔥 BOSS: ¡TRANSFORMACIÓN!")
	anim.play("transformation")
	
	# Esperar a que termine la animación
	await anim.animation_finished
	
	# Volver a perseguir con nuevos stats
	estado_actual = Estado.PERSIGUIENDO
	print("⚡ BOSS: ¡Solivan se ha transformado! Ahora es más peligroso")

func morir():
	estado_actual = Estado.MUERTO
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	area_ataque.set_deferred("monitoring", false)
	area_deteccion.set_deferred("monitoring", false)
	
	print("💀 BOSS: Muriendo...")
	anim.play("desappearing")
	
	# Esperar a que termine la animación
	await anim.animation_finished
	
	print("👻 BOSS: Eliminado")
	queue_free()

# === DETECCIÓN DEL JUGADOR ===
func _on_deteccion_jugador_entered(body):
	if body.is_in_group("player") and estado_actual != Estado.MUERTO:
		target_player = body
		print("👁️ BOSS: ¡Jugador detectado!")
		
		if estado_actual == Estado.IDLE:
			estado_actual = Estado.PERSIGUIENDO
			print("🏃 BOSS: Empezando a perseguir")
		
		# Mostrar UI del boss
		if barra_vida:
			barra_vida.visible = true
			print("📊 BOSS: Barra de vida mostrada")
		if label_nombre:
			label_nombre.visible = true

func _on_deteccion_jugador_exited(body):
	if body == target_player:
		print("🚶 BOSS: Jugador salió del área de detección")
		target_player = null
		estado_actual = Estado.IDLE

# === ANIMACIONES ===
func _on_animated_sprite_2d_animation_finished():
	print("🎬 BOSS: Animación terminada: ", anim.animation)
	
	match anim.animation:
		"atack1", "atack2":
			if estado_actual == Estado.ATACANDO:
				estado_actual = Estado.PERSIGUIENDO
				print("🔄 BOSS: Volviendo a perseguir después de atacar")
		"transformation":
			# Ya manejado en iniciar_transformacion()
			pass