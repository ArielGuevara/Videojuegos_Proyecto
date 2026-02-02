extends CharacterBody2D

# --- TIPOS DE ENEMIGO ---
enum Tipo { PI, INTEGRAL, SUMATORIA }
@export var tipo_enemigo: Tipo = Tipo.PI

# --- CONFIGURACIÓN ---
@export var speed_walk = 60
@export var speed_slide = 400
@export var gravedad = 980

# --- ESTADOS ---
enum Estado { PATRULLANDO, APLASTADO, DESLIZANDO }
var estado_actual = Estado.PATRULLANDO

var direction = 1
var velocity_y = 0

# --- NUEVA VARIABLE DE CONTROL ---
var puede_girar = true

# Referencias
@onready var graficos = $Graficos # Este está bien, es hijo directo
# IMPORTANTE: Actualizamos las rutas para buscar DENTRO de Graficos
@onready var anim = $Graficos/AnimatedSprite2D
@onready var ray_suelo = $Graficos/RaySuelo
@onready var ray_muro = $Graficos/RayMuro
@onready var timer_recup = $TimerRecuperacion # Este se queda igual, sigue afuera

func _ready():
	add_to_group("enemigo_lanzable")
	anim.play("walk")
	
	ray_suelo.add_exception(self)
	ray_muro.add_exception(self)
	
	# --- CORRECCIÓN TAMBIÉN AQUÍ ---
	# Como moviste las Áreas dentro de Graficos, el "has_node" directo fallará.
	# Lo mejor es acceder directamente a través de la carpeta graficos.
	
	if graficos.has_node("AreaDaño"):
		ray_suelo.add_exception(graficos.get_node("AreaDaño"))
		ray_muro.add_exception(graficos.get_node("AreaDaño"))
		
	if graficos.has_node("AreaCabeza"):
		ray_suelo.add_exception(graficos.get_node("AreaCabeza"))
		ray_muro.add_exception(graficos.get_node("AreaCabeza"))
	
	configurar_visuales()
	
	# Aseguramos que la orientación inicial sea correcta
	actualizar_orientacion()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	match estado_actual:
		Estado.PATRULLANDO:
			comportamiento_patrulla(delta)
		Estado.APLASTADO:
			velocity.x = 0
		Estado.DESLIZANDO:
			comportamiento_deslizamiento(delta)
			
	move_and_slide()

# --- COMPORTAMIENTOS ---

func comportamiento_patrulla(delta):
	if puede_girar:
		if is_on_wall() or not ray_suelo.is_colliding() or ray_muro.is_colliding():
			girar()
	
	velocity.x = direction * speed_walk
	anim.play("walk")

func girar():
	direction *= -1
	# --- CORRECCIÓN: Usamos la función segura en lugar de scale.x ---
	actualizar_orientacion()
	
	puede_girar = false
	await get_tree().create_timer(0.5).timeout
	puede_girar = true

# --- FUNCIÓN NUEVA Y SEGURA ---
func actualizar_orientacion():
	# En lugar de matemáticas complejas, solo volteamos el contenedor
	if direction == 1:
		graficos.scale.x = 1  # Mirar derecha (Normal)
	else:
		graficos.scale.x = -1 # Mirar izquierda (Espejo)
	

func comportamiento_deslizamiento(delta):
	velocity.x = direction * speed_slide
	anim.play("slide")

func configurar_visuales():
	match tipo_enemigo:
		Tipo.PI: modulate = Color(1, 0, 0)
		Tipo.INTEGRAL: modulate = Color(0, 0, 1)
		Tipo.SUMATORIA: modulate = Color(1, 1, 0)

# --- MECÁNICA DE PISOTÓN Y PATEO ---

func _on_area_cabeza_body_entered(body):
	if body.is_in_group("player") and estado_actual != Estado.DESLIZANDO:
		var altura_jugador = body.global_position.y
		var altura_enemigo = global_position.y
		
		if altura_jugador < (altura_enemigo - 10):
			if estado_actual == Estado.PATRULLANDO:
				aplastar()
				body.velocity.y = -300
			elif estado_actual == Estado.APLASTADO:
				patear(body.global_position)
				body.velocity.y = -300

func aplastar():
	estado_actual = Estado.APLASTADO
	anim.play("shell")
	timer_recup.start()

func patear(posicion_jugador):
	estado_actual = Estado.DESLIZANDO
	
	# 1. Decidir dirección
	if posicion_jugador.x < global_position.x:
		direction = 1 
	else:
		direction = -1
	
	actualizar_orientacion()
	
	# --- EL TRUCO MÁGICO ---
	# Levantamos al enemigo 2 píxeles para despegarlo del suelo
	# y evitar que se trabe con la fricción o un borde del tilemap.
	position.y -= 2  
	
	# Opcional: Dale un mini saltito físico si prefieres
	# velocity.y = -50 
	
	await get_tree().create_timer(3.0).timeout
	queue_free()

# --- INTERACCIÓN DE DAÑO (Sin cambios) ---
func _on_area_daño_body_entered(body):
	if body.is_in_group("player"):
		if estado_actual == Estado.PATRULLANDO:
			aplicar_efecto_a_jugador(body)
		elif estado_actual == Estado.DESLIZANDO:
			aplicar_efecto_a_jugador(body)

	if body.is_in_group("boss") and estado_actual == Estado.DESLIZANDO:
		if body.has_method("recibir_impacto_simbolo"):
			body.recibir_impacto_simbolo(tipo_enemigo)
		queue_free()

func aplicar_efecto_a_jugador(jugador):
	if not jugador.has_method("take_damage"): return
	
	match tipo_enemigo:
		Tipo.PI:
			jugador.take_damage(10, global_position)
		Tipo.INTEGRAL:
			jugador.take_damage(5, global_position)
			if jugador.has_method("congelar"): 
				jugador.congelar(1.0)
		Tipo.SUMATORIA:
			# 1. Aplicar daño
			jugador.take_damage(5, global_position)
			
			# 2. Calcular el Empuje (Knockback)
			if jugador.has_method("apply_knockback"):
				# Calculamos la dirección: (Destino - Origen).normalized()
				# Esto nos da una flecha que apunta DESDE el enemigo HACIA el jugador
				var direccion_empuje = (jugador.global_position - global_position).normalized()
				
				# Definimos la fuerza (puedes ajustar el 500 a tu gusto)
				var fuerza = 500 
				
				# Le damos un empujoncito extra hacia arriba para que no roce el suelo
				direccion_empuje.y = -0.5 
				
				# Enviamos el vector final
				jugador.apply_knockback(direccion_empuje * fuerza)
