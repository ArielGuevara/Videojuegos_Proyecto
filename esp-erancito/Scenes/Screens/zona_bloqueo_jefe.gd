extends Area2D

# Esta función se ejecuta automáticamente cuando algo entra en el área
func _on_body_entered(body):
	print("ALGO ENTRÓ: ", body.name)
	# 1. Primero preguntamos: ¿Es el Jugador?
	# (Asegúrate de que tu nodo jugador se llame "Player" o usa grupos)
	if body.name == "boy1":
		verificar_si_puede_pasar()

func verificar_si_puede_pasar():
	# --- AQUÍ ESTÁ EL TRUCO ---
	# Esta línea busca en TODO el juego cuántos nodos existen 
	# que tengan la etiqueta (grupo) "historias".
	var objetos_restantes = get_tree().get_nodes_in_group("historias").size()
	
	# Imprimimos en consola para que tú (el desarrollador) veas el número
	print("Objetos restantes en el mundo: ", objetos_restantes)
	
	# Si el número es 0, significa que el jugador los recogió todos (los borró con queue_free)
	if objetos_restantes == 0:
		abrir_camino_al_jefe()
	else:
		rechazar_jugador(objetos_restantes)

func abrir_camino_al_jefe():
	print("¡ACCESO CONCEDIDO!")
	# AQUÍ DECIDES QUÉ PASA CUANDO GANA:
	# Opción A: Borrar esta barrera para que pase físicamente
	queue_free() 
	
	# Opción B: Cambiar de escena directamente
	# get_tree().change_scene_to_file("res://Niveles/JefeFinal.tscn")

func rechazar_jugador(cantidad_faltante):
	print("¡ALTO! Te faltan: " + str(cantidad_faltante) + " objetos.")
	
	# Opcional: Empujar al jugador hacia atrás para que no pase
	# (Si tienes una función de empuje en tu jugador, úsala aquí)
	# body.apply_knockback(Vector2(-500, 0))
