extends Area2D

@export_multiline var frase_del_juego: String = "Escribe aquí la historia..."

func _on_body_entered(body):
	if body.name == "boy1": 
		# 1. Lógica de la Historia (Tu código anterior)
		var interfaz = get_tree().get_first_node_in_group("ui_historia")
		if interfaz:
			interfaz.mostrar_historia(frase_del_juego)
		
		# 2. --- NUEVA LÓGICA: INVOCAR AL JEFE ---
		verificar_si_es_el_ultimo()
		
		# 3. Borramos el objeto
		queue_free()

func verificar_si_es_el_ultimo():
	# Obtenemos todos los items que quedan en el mapa
	var items_restantes = get_tree().get_nodes_in_group("historias")
	
	# ¿Por qué .size() == 1?
	# Porque este código se ejecuta ANTES del queue_free().
	# Por tanto, si la lista dice que queda "1" (que soy yo mismo), 
	# significa que después de morir yo, quedarán 0.
	if items_restantes.size() == 1:
		despertar_al_jefe()

func despertar_al_jefe():
	# Buscamos al jefe usando el grupo "boss" que pusimos en su _ready
	var jefe = get_tree().get_first_node_in_group("boss")
	
	if jefe:
		if jefe.has_method("aparecer_jefe"):
			jefe.aparecer_jefe()
	else:
		print("ERROR: No encontré al Jefe en la escena. ¿Está en el grupo 'boss'?")
