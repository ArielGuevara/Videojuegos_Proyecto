extends CharacterBody2D

@export_multiline var consejo: String = "Sigue la luz..."
@export var mirar_derecha: bool = true

@onready var anim = $animaciones

# Variable para asegurar que no se active dos veces mientras desaparece
var se_esta_yendo = false

func _ready():
	anim.play("idle") # Animación de estar quieto
	if not mirar_derecha:
		anim.flip_h = true

func _on_area_dialogo_body_entered(body):
	# Si ya se está yendo, ignoramos todo
	if se_esta_yendo:
		return

	if body.name == "boy1": # Asegúrate que este sea el nombre de tu jugador
		var interfaz = get_tree().get_first_node_in_group("ui_historia")
		
		if interfaz:
			# 1. Mostramos el mensaje
			interfaz.mostrar_historia(consejo)
			
			# Marcamos que ya cumplió su misión
			se_esta_yendo = true
			
			# 2. ESPERAMOS: El código se pausa aquí hasta que la señal se emita
			await interfaz.historia_cerrada
			
			desaparecer_npc()

func desaparecer_npc():
	
	# 3. Desactivamos colisiones para que no te choques con el aire mientras se esfuma
	$CollisionShape2D.set_deferred("disabled", true)
	
	# 4. Reproducimos la animación
	# IMPORTANTE: Asegúrate de que en tus SpriteFrames la animación se llame EXACTAMENTE así
	anim.play("desappearing")
	
	# 5. Esperamos a que termine la animación
	await anim.animation_finished
	
	# 6. Borramos al NPC del mapa
	queue_free()
