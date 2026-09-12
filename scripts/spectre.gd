extends CharacterBody2D
class_name Spectre

## ============================================================
## Spectre.gd — Cavalier Noir / Ombre patrouilleuse.
## Traque les héros. Si le Porteur est visible à portée,
## la corruption augmente rapidement !
## ============================================================

@export var point_a: Vector2 = Vector2.ZERO
@export var point_b: Vector2 = Vector2.ZERO
@export var vitesse_patrouille: float = 65.0

var _cible_actuelle: Vector2
var _porteur: CharacterBody2D
var _chrono_anim: float = 0.0
var _etourdi: float = 0.0

@onready var _visuel: Node2D = $Visuel
@onready var _yeux: Node2D = $Visuel/Yeux
@onready var _alerte: Label = $Alerte
@onready var _zone_detection: Area2D = $ZoneDetection

func _ready() -> void:
	add_to_group("spectres")
	if point_a == Vector2.ZERO:
		point_a = global_position - Vector2(120, 0)
	if point_b == Vector2.ZERO:
		point_b = global_position + Vector2(120, 0)
	_cible_actuelle = point_b
	_alerte.hide()
	
	_zone_detection.body_entered.connect(_sur_corps_entre)
	_zone_detection.body_exited.connect(_sur_corps_sorti)

func _physics_process(delta: float) -> void:
	_chrono_anim += delta * 4.0
	# Ondulation fantomatique
	_visuel.position.y = sin(_chrono_anim) * 3.5
	_visuel.rotation = sin(_chrono_anim * 0.7) * 0.06
	
	if _etourdi > 0.0:
		_etourdi -= delta
		_alerte.text = "⚡"
		_alerte.show()
		modulate = Color(0.8, 1.0, 0.8, 0.6)
		return
	
	modulate = Color(1, 1, 1, 1)

	# Détection et menace du Porteur
	if _porteur and is_instance_valid(_porteur):
		if not _porteur.invisible:
			# Alerte ! Le Porteur est visible
			_alerte.text = "👁️"
			_alerte.show()
			_yeux.modulate = Color(1.5, 0.2, 0.2, 1.0)
			# Accroît la corruption
			Corruption.valeur = minf(Corruption.MAX, Corruption.valeur + 12.0 * delta)
			Corruption.corruption_changee.emit(Corruption.valeur)
		else:
			_alerte.hide()
			_yeux.modulate = Color(0.8, 0.3, 0.3, 0.7)
	else:
		_alerte.hide()
		_yeux.modulate = Color(0.8, 0.3, 0.3, 0.7)

	# Patrouille autonome
	var vers_cible := (_cible_actuelle - global_position)
	if vers_cible.length() < 10.0:
		_cible_actuelle = point_a if _cible_actuelle == point_b else point_b
	else:
		velocity = vers_cible.normalized() * vitesse_patrouille
		move_and_slide()
		if velocity.x < -2.0:
			_visuel.scale.x = -1.0
		elif velocity.x > 2.0:
			_visuel.scale.x = 1.0

func repousser() -> void:
	_etourdi = 2.5
	velocity = -velocity * 1.5
	move_and_slide()

func _sur_corps_entre(body: Node2D) -> void:
	if body.name == "Porteur":
		_porteur = body as CharacterBody2D

func _sur_corps_sorti(body: Node2D) -> void:
	if body == _porteur:
		_porteur = null
