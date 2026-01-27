# INFORME TÉCNICO
## Inteligencia Artificial en Videojuegos
### Análisis del Algoritmo de IA del Enemigo "Solaris" en ESPErancito

---

**Asignatura:** Desarrollo de Videojuegos  
**Fecha:** 27 de enero de 2026  
**Motor de Desarrollo:** Godot Engine 4.5  

---

## ÍNDICE

1. [Introducción](#1-introducción)
2. [Marco Teórico](#2-marco-teórico)
3. [Descripción del Videojuego](#3-descripción-del-videojuego)
4. [Análisis del Algoritmo de IA](#4-análisis-del-algoritmo-de-ia)
5. [Implementación en Código](#5-implementación-en-código)
6. [Diagramas de Flujo](#6-diagramas-de-flujo)
7. [Conclusiones](#7-conclusiones)
8. [Referencias](#8-referencias)

---

## 1. INTRODUCCIÓN

### 1.1 Objetivo del Informe

El presente informe tiene como objetivo analizar y explicar el funcionamiento de los algoritmos de Inteligencia Artificial (IA) implementados en el videojuego **ESPErancito**, un juego de plataformas 2D con combate desarrollado en Godot Engine 4.5.

### 1.2 Alcance

Se analizará específicamente el comportamiento del enemigo "Solaris", el cual implementa una **Máquina de Estados Finitos (FSM)** combinada con un **Sistema de Decisión Probabilística** para crear un oponente que presenta un desafío dinámico al jugador.

---

## 2. MARCO TEÓRICO

### 2.1 ¿Qué es la IA en Videojuegos?

La Inteligencia Artificial en videojuegos se refiere a las técnicas utilizadas para crear comportamientos aparentemente inteligentes en personajes no jugables (NPCs). A diferencia de la IA académica que busca replicar la inteligencia humana, la IA en videojuegos tiene como objetivo principal crear **experiencias de juego entretenidas y desafiantes**.

### 2.2 Máquinas de Estados Finitos (FSM)

Una **Máquina de Estados Finitos** es un modelo computacional que consiste en:

- **Estados**: Diferentes comportamientos que puede adoptar el agente
- **Transiciones**: Condiciones que provocan el cambio entre estados
- **Acciones**: Comportamientos ejecutados en cada estado

**Ventajas de las FSM:**
- Fáciles de implementar y depurar
- Comportamiento predecible y controlable
- Bajo costo computacional
- Ampliamente utilizadas en la industria

**Desventajas:**
- Pueden volverse complejas con muchos estados
- Transiciones pueden ser rígidas
- Difícil de escalar para comportamientos muy complejos

### 2.3 Sistemas de Decisión Probabilística

Los sistemas de decisión probabilística añaden **variabilidad** al comportamiento de la IA, evitando que sea completamente predecible. En lugar de siempre elegir la misma acción, el agente selecciona entre varias opciones con diferentes probabilidades.

### 2.4 Raycasting para Percepción del Entorno

El **Raycasting** es una técnica que proyecta rayos invisibles desde un punto para detectar colisiones con objetos del entorno. En IA de videojuegos se utiliza para:

- Detectar obstáculos
- Verificar línea de visión
- Detectar precipicios o paredes

---

## 3. DESCRIPCIÓN DEL VIDEOJUEGO

### 3.1 Información General

| Característica | Detalle |
|----------------|---------|
| **Nombre** | ESPErancito |
| **Género** | Plataformas 2D con combate |
| **Motor** | Godot Engine 4.5 |
| **Lenguaje** | GDScript |
| **Resolución** | 1908 x 940 píxeles |

### 3.2 Mecánicas Principales

El jugador controla a un personaje vampiro que debe:
- Navegar por niveles de plataformas
- Combatir enemigos con ataques cuerpo a cuerpo
- Utilizar un sistema de **Parry** para devolver proyectiles
- Teletransportarse usando ascensores/portales

### 3.3 El Enemigo Solaris

El **Profesor Solaris** es el enemigo principal analizado, caracterizado por:

| Atributo | Valor |
|----------|-------|
| Vida | 200 HP |
| Velocidad base | 100 px/s |
| Daño por contacto | 10 HP |
| Daño de proyectil | 20 HP |
| Distancia de combate óptima | 150 px |

---

## 4. ANÁLISIS DEL ALGORITMO DE IA

### 4.1 Arquitectura General

El enemigo Solaris implementa una arquitectura de IA basada en:

1. **Máquina de Estados Finitos (FSM)** para el comportamiento general
2. **Sistema de Percepción** mediante Raycasts
3. **Sistema de Decisión Probabilística** para selección de ataques
4. **Sistema de Escalado de Dificultad** (Fases)

### 4.2 Estados de la FSM

```
┌─────────────────────────────────────────────────────────────┐
│                    ESTADOS DEL ENEMIGO                      │
├─────────────────────────────────────────────────────────────┤
│  PATRULLAR    → Movimiento horizontal exploratorio          │
│  PERSEGUIR    → Seguimiento activo del jugador              │
│  ATACAR       → Ejecución de ataque seleccionado            │
│  ENFURECIDO   → Modo de alta agresividad (Fase 2)           │
│  MUERTE       → Animación final y destrucción               │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 Sistema de Percepción

El enemigo utiliza tres componentes de percepción:

| Componente | Función |
|------------|---------|
| **AreaDeteccion** | Detecta cuando el jugador entra en rango (2023x516 px) |
| **RaySuelo** | Detecta si hay suelo adelante para evitar caer |
| **RayMuro** | Detecta paredes para cambiar dirección |

### 4.4 Algoritmo de Distancia Óptima

Una de las características más interesantes es el algoritmo que mantiene al enemigo a una distancia táctica del jugador:

```
SI distancia > 150px:
    → ACERCARSE al jugador
    
SI distancia < 130px:
    → RETROCEDER (si es seguro)
    
SI 130px ≤ distancia ≤ 150px:
    → MANTENER posición y ATACAR
```

Este comportamiento crea un enemigo que:
- No se acerca demasiado (evita ataques del jugador)
- No se aleja demasiado (mantiene presión)
- Verifica seguridad antes de retroceder (no cae al vacío)

### 4.5 Sistema de Selección de Ataques

El enemigo elige entre tres tipos de ataque usando distribución probabilística:

| Ataque | Probabilidad | Descripción |
|--------|--------------|-------------|
| **Normal** | 50% | Dispara un proyectil |
| **Ráfaga** | 30% | Dispara 3 proyectiles consecutivos |
| **Embestida** | 20% | Dash rápido hacia el jugador |

Esta distribución está diseñada para que:
- El ataque básico sea el más común (predecible, esquivable)
- La ráfaga añada presión moderada
- La embestida sea sorpresiva y peligrosa

### 4.6 Sistema de Fases (Escalado de Dificultad)

Cuando el enemigo pierde el 50% de su vida, entra en **Fase 2**:

| Característica | Fase 1 | Fase 2 |
|----------------|--------|--------|
| Velocidad | 100 px/s | 150 px/s |
| Cooldown de ataque | Default | 1.0 segundo |
| Animación | Normal | "grow_up" |
| Indicador visual | Normal | Transformación |

---

## 5. IMPLEMENTACIÓN EN CÓDIGO

### 5.1 Variables de Estado

```gdscript
# Estados del enemigo
var current_health = 0
var direction = 1 
var is_enraged = false        # Indica si está en Fase 2
var target_player = null      # Referencia al jugador detectado
var is_dashing = false        # Estado de embestida activa

# Configuración
@export var max_health = 200
@export var speed = 100
@export var damage_touch = 10 
@export var safe_distance = 150
```

### 5.2 Bucle Principal de IA

```gdscript
func _physics_process(delta):
    # 1. Aplicar gravedad
    if not is_on_floor():
        velocity += get_gravity() * delta
    
    # 2. Procesar daño por contacto
    if player_in_contact and current_health > 0:
        if player_in_contact.has_method("take_damage"):
            player_in_contact.take_damage(damage_touch, global_position)
    
    # 3. Si está en dash, priorizar ese movimiento
    if is_dashing:
        velocity.x = direction * dash_speed
        move_and_slide()
        return 
    
    # 4. Si está atacando, detenerse
    if anim.animation == "attack" and anim.is_playing():
        velocity.x = 0 
        move_and_slide()
        return
    
    # 5. Lógica de movimiento según estado
    if target_player:
        perseguir_jugador()    # Estado: PERSEGUIR
    else:
        patrullar()            # Estado: PATRULLAR
        velocity.x = direction * speed
    
    move_and_slide()
```

### 5.3 Algoritmo de Patrullaje

```gdscript
func patrullar():
    # Verificar obstáculos usando Raycasts
    if ray_muro.is_colliding() or not ray_suelo.is_colliding():
        cambiar_direccion()

func cambiar_direccion():
    direction *= -1                              # Invertir dirección
    anim.flip_h = (direction == -1)              # Voltear sprite
    ray_suelo.position.x *= -1                   # Invertir raycast suelo
    ray_muro.target_position.x *= -1             # Invertir raycast muro
    punto_disparo.position.x = abs(punto_disparo.position.x) * direction
```

### 5.4 Algoritmo de Persecución con Distancia Óptima

```gdscript
func perseguir_jugador():
    var diferencia = target_player.position.x - position.x
    var distancia_absoluta = abs(diferencia)
    var direccion_jugador = sign(diferencia) 
    
    # Actualizar orientación visual
    if direccion_jugador > 0:
        anim.flip_h = false 
        direction = 1 
    elif direccion_jugador < 0:
        anim.flip_h = true 
        direction = -1

    # ALGORITMO DE DISTANCIA ÓPTIMA
    if distancia_absoluta > safe_distance:
        # Demasiado lejos → ACERCARSE
        velocity.x = direction * speed
        
    elif distancia_absoluta < (safe_distance - 20): 
        # Demasiado cerca → RETROCEDER (si es seguro)
        var es_seguro = not ray_muro_atras_detecta() and ray_suelo_atras_detecta()
        if es_seguro:
            velocity.x = -direction * speed 
        else:
            velocity.x = 0  # No retroceder si hay peligro
    else:
        # Distancia óptima → MANTENER POSICIÓN
        velocity.x = 0
```

### 5.5 Sistema de Decisión Probabilística

```gdscript
func elegir_ataque():
    var dado = randf_range(0, 100)  # Número aleatorio 0-100
    
    if dado < 50:
        iniciar_ataque_normal()     # 50% de probabilidad
    elif dado < 80:
        iniciar_rafaga()            # 30% de probabilidad
    else:
        iniciar_embestida()         # 20% de probabilidad

func iniciar_ataque_normal():
    anim.play("attack")
    call_deferred("lanzar_proyectil")
    
func iniciar_rafaga():
    anim.play("attack") 
    lanzar_proyectil()
    await get_tree().create_timer(0.3).timeout 
    
    if current_health > 0:
        lanzar_proyectil()
        await get_tree().create_timer(0.3).timeout
    
    if current_health > 0:
        lanzar_proyectil()
        
func iniciar_embestida():
    modulate = Color(1, 0, 0)  # Indicador visual: rojo
    velocity.x = 0
    await get_tree().create_timer(0.3).timeout  # Pausa de advertencia
    
    if current_health > 0 and target_player:
        is_dashing = true
        await get_tree().create_timer(0.5).timeout  # Duración del dash
        is_dashing = false
        modulate = Color(1, 1, 1)  # Restaurar color
```

### 5.6 Sistema de Fases

```gdscript
func take_damage(amount):
    current_health -= amount
    
    # Feedback visual de daño
    modulate = Color(10, 10, 10) 
    var tween = create_tween()
    tween.tween_property(self, "modulate", Color(1,1,1), 0.1)
    
    if current_health <= 0:
        die()
    elif current_health <= (max_health / 2) and not is_enraged:
        activar_fase_2()  # Transición a Fase 2

func activar_fase_2():
    is_enraged = true
    anim.play("grow_up")           # Animación de transformación
    speed += 50                     # Aumentar velocidad
    timer_ataque.wait_time = 1.0    # Reducir cooldown de ataques
```

---

## 6. DIAGRAMAS DE FLUJO

### 6.1 Diagrama General de la FSM

```
                    ┌──────────────┐
                    │    INICIO    │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  PATRULLAR   │◄────────────────────┐
                    └──────┬───────┘                     │
                           │                             │
                           │ ¿Jugador detectado?         │
                           ▼                             │
                    ┌──────────────┐                     │
              SÍ ───│   DECISIÓN   │─── NO ──────────────┘
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  PERSEGUIR   │◄────────────────────┐
                    └──────┬───────┘                     │
                           │                             │
                           │ ¿Distancia óptima?          │
                           ▼                             │
                    ┌──────────────┐                     │
              SÍ ───│   ATACAR     │                     │
                    └──────┬───────┘                     │
                           │                             │
                           │ ¿HP <= 50%?                 │
                           ▼                             │
                    ┌──────────────┐                     │
              SÍ ───│ ENFURECIDO   │─────────────────────┘
                    └──────┬───────┘
                           │
                           │ ¿HP <= 0?
                           ▼
                    ┌──────────────┐
              SÍ ───│   MUERTE     │
                    └──────────────┘
```

### 6.2 Diagrama de Selección de Ataques

```
         ┌─────────────────────────────┐
         │    SELECCIONAR ATAQUE       │
         │   dado = random(0, 100)     │
         └─────────────┬───────────────┘
                       │
           ┌───────────┼───────────┐
           │           │           │
           ▼           ▼           ▼
      dado < 50   50 ≤ dado < 80  dado ≥ 80
           │           │           │
           ▼           ▼           ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐
    │  NORMAL  │ │  RÁFAGA  │ │EMBESTIDA │
    │   50%    │ │   30%    │ │   20%    │
    └──────────┘ └──────────┘ └──────────┘
           │           │           │
           ▼           ▼           ▼
     1 proyectil  3 proyectiles   Dash
                 (0.3s entre c/u)
```

### 6.3 Diagrama de Distancia Óptima

```
    ┌─────────────────────────────────────────┐
    │     CALCULAR DISTANCIA AL JUGADOR       │
    │        distancia = |jugador - enemigo|  │
    └─────────────────────┬───────────────────┘
                          │
            ┌─────────────┼─────────────┐
            │             │             │
            ▼             ▼             ▼
      dist > 150     130 ≤ dist ≤ 150   dist < 130
            │             │             │
            ▼             ▼             ▼
     ┌──────────┐  ┌──────────┐  ┌──────────┐
     │ ACERCARSE│  │ MANTENER │  │RETROCEDER│
     └──────────┘  │ POSICIÓN │  │(si seguro)│
                   └──────────┘  └──────────┘
```

---

## 7. CONCLUSIONES

### 7.1 Efectividad del Algoritmo

La implementación de IA en el enemigo Solaris demuestra varios principios efectivos:

1. **Comportamiento Emergente**: Aunque las reglas son simples, la combinación de patrullaje, persecución y selección de ataques crea un enemigo que parece tener comportamientos complejos.

2. **Variabilidad**: El sistema probabilístico evita que el enemigo sea completamente predecible, manteniendo el desafío para el jugador.

3. **Escalado de Dificultad**: El sistema de fases mantiene el interés del jugador al aumentar la dificultad progresivamente.

4. **Seguridad del Agente**: El uso de Raycasts previene que el enemigo cometa "suicidio" cayendo al vacío o quedando atrapado.

### 7.2 Técnicas de IA Aplicadas

| Técnica | Aplicación en el Juego |
|---------|------------------------|
| FSM | Control general del comportamiento |
| Raycasting | Percepción del entorno |
| Decisión Probabilística | Selección de ataques |
| Keep Distance | Posicionamiento táctico |
| Difficulty Scaling | Sistema de fases |

### 7.3 Comparación con Alternativas

| Técnica Alternativa | Ventaja | Desventaja vs Nuestra Implementación |
|--------------------|---------|--------------------------------------|
| Árboles de Comportamiento | Más modular | Mayor complejidad para este caso simple |
| GOAP | Más flexible | Overhead innecesario para un enemigo |
| Machine Learning | Adaptativo | Impredecible, difícil de balancear |
| Navegación A* | Pathfinding óptimo | Innecesario en escenario 2D lineal |

### 7.4 Lecciones Aprendidas

- Las técnicas más simples (FSM) siguen siendo altamente efectivas en videojuegos
- La variabilidad es clave para evitar que la IA sea "resuelta" por el jugador
- La percepción del entorno (Raycasts) es fundamental para comportamientos realistas
- El feedback visual (cambio de color en embestida) mejora la legibilidad de la IA

---

## 8. REFERENCIAS

1. **Millington, I., & Funge, J.** (2019). *Artificial Intelligence for Games* (3rd ed.). CRC Press.

2. **Buckland, M.** (2005). *Programming Game AI by Example*. Wordware Publishing.

3. **Godot Engine Documentation** (2024). *CharacterBody2D*. https://docs.godotengine.org/

4. **Rabin, S.** (2017). *Game AI Pro 3: Collected Wisdom of Game AI Professionals*. CRC Press.

5. **Yannakakis, G. N., & Togelius, J.** (2018). *Artificial Intelligence and Games*. Springer.

---

## ANEXOS

### Anexo A: Código Fuente Completo

El código fuente completo del enemigo Solaris se encuentra en:
```
esp-erancito/Scenes/Characteres/solaris_1.gd
```

### Anexo B: Créditos del Proyecto

**Proyecto:** ESPErancito  
**Motor:** Godot Engine 4.5  
**Lenguaje:** GDScript  

---

*Informe generado para la asignatura de Desarrollo de Videojuegos*
