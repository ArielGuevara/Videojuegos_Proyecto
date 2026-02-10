extends Area2D

# Referencias a los nodos hijos
@onready var anim = $AnimatedSprite2D
@onready var marker = $Marker2D # Usaremos esto para saber dónde revivir exactamente

var activado = false

func _ready():
	# 1. INICIO: Hacemos que el círculo empiece a girar inmediatamente
	anim.play("default")

func _on_body_entered(body: Node2D) -> void:
	# Si ya fue tomado, no hacemos nada
	if activado:
		return
	
	# Verificamos si es el jugador (usando el método que creamos antes)
	if body.has_method("actualizar_checkpoint"):
		activado = true
		
		# 2. ACTUALIZAR JUGADOR:
		# Le enviamos la posición del Marker2D (es más preciso que el Area2D)
		body.actualizar_checkpoint(marker.global_position)
		
		# 3. FEEDBACK VISUAL (Aquí detenemos el giro)
		cambiar_estado_a_capturado()

func cambiar_estado_a_capturado():
	# OPCIÓN A: Detener la animación y cambiar el color
	anim.stop()     # Deja de girar
	anim.frame = 0  # Se queda en el primer cuadro (o el que tú elijas)
	modulate = Color(0.6, 0.6, 0.6) # Se pone un poco oscuro/gris para indicar que ya se usó
	
	# OPCIÓN B: (Si tuvieras una animación de "activado", usarías esto):
	# anim.play("activado")
