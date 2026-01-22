extends CharacterBody2D

# --- CONFIGURACIÓN ---
@export var max_health = 200
@export var speed = 100
@export var damage_touch = 10 # Daño si tocas al enemigo con el cuerpo
@export var projectile_scene: PackedScene 

#--------VARIABLES DE ATAUQE-----------
var is_dashing = false # ¿Está embistiendo?
var dash_speed = 400   # Velocidad de la embestida
var dash_duration = 0.5 # Cuánto dura el dash

# --- ESTADOS ---
var current_health = 0
var direction = 1 # 1 = Derecha, -1 = Izquierda
var is_enraged = false # Fase 2 (Gigante)
var target_player = null 

# Referencias
@onready var anim = $AnimatedSprite2D
@onready var timer_ataque = $TimerAtaque # Asegúrate de tener este nodo Timer
@onready var punto_disparo = $PuntoDeDisparo # Asegúrate de tener este Marker2D
@onready var ray_suelo = $RaySuelo
@onready var ray_muro = $RayMuro

func _ready():
	current_health = max_health
	anim.play("walk") # O "run", la que uses para caminar
	
	# Configurar timer de ataque
	if timer_ataque.is_stopped():
		timer_ataque.start()

func _physics_process(delta):
	# 1. Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# --- MODIFICACION DASH ---
	if is_dashing:
		# Si estamos embistiendo, nos movemos MUY RÁPIDO hacia donde miramos
		velocity.x = direction * dash_speed
		move_and_slide()
		return # ¡Importante! No hacemos nada más mientras embestimos

	# 2. Si está en animación de crecer o atacar, no se mueve
	if anim.animation == "grow_up" and anim.is_playing():
		return
	if anim.animation == "attack" and anim.is_playing():
		# Pequeña pausa al atacar, opcional
		velocity.x = 0 
		move_and_slide()
		return

	# 3. Lógica de Movimiento
	if target_player:
		perseguir_jugador()
	else:
		patrullar()

	# Aplicar movimiento
	velocity.x = direction * speed
	move_and_slide()
	
	# Gestionar animación de caminar si no está atacando
	if velocity.x != 0 and (anim.animation != "attack" or not anim.is_playing()):
		anim.play("run" if is_enraged else "walk")
		
	
#----- ATAQUES ------
func iniciar_ataque_normal():
	anim.play("attack")
	# Nota: Asumo que tu animación "attack" llama a 'lanzar_proyectil'
	# o que usas un call_deferred como tenías antes.
	# Si tu animación NO tiene eventos, usa esto:
	call_deferred("lanzar_proyectil")
	
func iniciar_rafaga():
	anim.play("attack") # Animación visual
	
	# Disparo 1
	lanzar_proyectil()
	await get_tree().create_timer(0.3).timeout # Espera 0.3 segundos
	
	# Disparo 2 (Si seguimos vivos)
	if current_health > 0:
		anim.frame = 0 # Reiniciar frame de animación (opcional)
		lanzar_proyectil()
		await get_tree().create_timer(0.3).timeout
	
	# Disparo 3
	if current_health > 0:
		anim.frame = 0
		lanzar_proyectil()
		
		
func iniciar_embestida():
	# 1. Avisar visualmente (opcional: ponerlo rojo o animacion especial)
	modulate = Color(1, 0, 0) # Se pone rojo
	
	# 2. Pausa dramática antes de lanzarse (0.3 seg)
	velocity.x = 0
	await get_tree().create_timer(0.3).timeout
	
	# 3. ¡LANZAMIENTO!
	if current_health > 0 and target_player:
		is_dashing = true
		anim.play("run" if is_enraged else "walk") # O animación de correr
		
		# Asegurar dirección correcta antes de salir disparado
		perseguir_jugador() 
		
		# Esperar duración del dash
		await get_tree().create_timer(dash_duration).timeout
		
		# 4. Frenar
		is_dashing = false
		modulate = Color(1, 1, 1) # Color normal
		velocity.x = 0 # Frenado finalfunc iniciar_embestida():
	# 1. Avisar visualmente (opcional: ponerlo rojo o animacion especial)
	modulate = Color(1, 0, 0) # Se pone rojo
	
	# 2. Pausa dramática antes de lanzarse (0.3 seg)
	velocity.x = 0
	await get_tree().create_timer(0.3).timeout
	
	# 3. ¡LANZAMIENTO!
	if current_health > 0 and target_player:
		is_dashing = true
		anim.play("run" if is_enraged else "walk") # O animación de correr
		
		# Asegurar dirección correcta antes de salir disparado
		perseguir_jugador() 
		
		# Esperar duración del dash
		await get_tree().create_timer(dash_duration).timeout
		
		# 4. Frenar
		is_dashing = false
		modulate = Color(1, 1, 1) # Color normal
		velocity.x = 0 # Frenado final

# --- COMPORTAMIENTOS ---

func elegir_ataque():
	# Generamos un número aleatorio entre 0 y 100
	var dado = randf_range(0, 100)
	
	if dado < 50:
		# 0 a 49 (50%): Disparo Normal
		print("Eligió: Disparo Normal")
		iniciar_ataque_normal()
		
	elif dado < 80:
		# 50 a 79 (30%): Ráfaga Rápida
		print("Eligió: Ráfaga")
		iniciar_rafaga()
		
	else:
		# 80 a 100 (20%): Embestida
		print("Eligió: Embestida")
		iniciar_embestida()

func patrullar():
	# Si detectamos pared O se acaba el suelo -> Girar
	if ray_muro.is_colliding() or not ray_suelo.is_colliding():
		cambiar_direccion()

func perseguir_jugador():
	# Calcular dirección hacia el jugador
	var dir_x = (target_player.position.x - position.x)
	
	# Si el jugador está a la derecha y nosotros mirando a la izquierda -> Girar
	if dir_x > 0 and direction == -1:
		cambiar_direccion()
	elif dir_x < 0 and direction == 1:
		cambiar_direccion()

func cambiar_direccion():
	direction *= -1 # Invertir dirección (1 pasa a -1, -1 pasa a 1)
	
	# Voltear gráficos
	anim.flip_h = (direction == -1)
	
	# Voltear sensores (RayCasts) y punto de disparo
	# Multiplicamos su posición X por -1 para que pasen al otro lado
	ray_suelo.position.x *= -1
	ray_muro.target_position.x *= -1 # El vector del rayo, no su posición
	punto_disparo.position.x = abs(punto_disparo.position.x) * direction

# --- COMBATE ---

func _on_timer_ataque_timeout():
	# Si estoy muerto, no hago nada.
	if current_health <= 0:
		return
	# Solo dispara si ve al jugador
	if target_player:
		elegir_ataque()

func lanzar_proyectil():
	var proyectil = projectile_scene.instantiate()
	get_parent().add_child(proyectil)
	proyectil.global_position = punto_disparo.global_position
	
	# Calcular dirección hacia el jugador
	if target_player:
		var dir = (target_player.global_position - global_position).normalized()
		proyectil.direccion = dir
	else:
		# Si perdió al jugador, dispara hacia donde mira
		proyectil.direccion = Vector2(direction, 0)

# --- DAÑO Y FASES ---

func take_damage(amount):
	current_health -= amount
	# Feedback visual (parpadeo rápido)
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
	speed += 50 # Más rápido
	timer_ataque.wait_time = 1.0 # Dispara más seguido
	
	# Escalar colisiones y sprites visualmente (si la animación no lo hace sola)
	# await anim.animation_finished
	# scale = Vector2(1.5, 1.5) 

func die():
	# 1. Detener ataques inmediatamente
	timer_ataque.stop() 
	target_player = null # Dejar de apuntar/perseguir
	
	# 2. Reproducir muerte
	anim.play("desappearing")
	
	# 3. Desactivar movimiento y colisiones
	set_physics_process(false)
	
	# Desactiva la colisión principal (para que no choque con paredes)
	$CollisionShape2D.call_deferred("set_disabled", true) 
	
	# IMPORTANTE: Si tienes un nodo Hitbox aparte, desactívalo también aquí
	# o añade una comprobación de vida en la función de daño por contacto.
	# 4. Esperar y desaparecer
	await anim.animation_finished
	queue_free()

# --- SEÑALES DE VISIÓN ---
# Conecta esto al AreaDeteccion (body_entered)
func _on_area_deteccion_body_entered(body):
	if body.is_in_group("player"):
		target_player = body

# Conecta esto al AreaDeteccion (body_exited)
func _on_area_deteccion_body_exited(body):
	if body == target_player:
		target_player = null
		# OPCIONAL: Si ya no te veo, cancelo el ataque y pongo la animación de caminar YA.
		if anim.animation == "attack":
			# EN LUGAR DE STOP(), LE ORDENAMOS CAMBIAR
			anim.play("run" if is_enraged else "walk")

# --- DAÑO POR CONTACTO (OPCIONAL) ---
# Si quieres que haga daño si el jugador lo toca con el cuerpo
# Necesitas un Area2D extra llamada "Hitbox" o usar la misma deteccion pero muy cerca
func _on_hitbox_body_entered(body):
	if current_health <= 0:
		return
		
	if body.is_in_group("player") and body.has_method("take_damage"):
		print(current_health)
		body.take_damage(damage_touch, global_position)


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		# ...volvemos inmediatamente a caminar/correr
		anim.play("run" if is_enraged else "walk")
