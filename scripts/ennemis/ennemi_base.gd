class_name EnnemiBase
extends CharacterBody2D
## ============================================================
## EnnemiBase.gd — Comportement commun pour monstres & orques GBA.
## ============================================================

signal est_mort

@export var points_de_vie: int = 3
@export var vitesse: float = 115.0
@export var rayon_detection: float = 320.0
@export var type_ennemi: String = "orque" # "orque", "araignee", "spectre_boss"

var recul: Vector2 = Vector2.ZERO
var mort: bool = false
var _chrono_clignote: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $Hitbox

func _ready() -> void:
	if _hurtbox:
		_hurtbox.camp = "ennemi"
		_hurtbox.a_subi_degats.connect(_sur_degats)
	if _hitbox:
		_hitbox.camp = "ennemi"
		_hitbox.degats = 1

func _physics_process(delta: float) -> void:
	if mort:
		return

	# Application du recul
	if recul.length() > 5.0:
		velocity = recul
		recul = recul.move_toward(Vector2.ZERO, delta * 800.0)
		move_and_slide()
		return

	# Recherche de la cible la plus proche (Porteur ou Guide)
	var cible: Node2D = _trouver_cible_proche()
	if cible:
		var dist := global_position.distance_to(cible.global_position)
		if dist <= rayon_detection:
			var dir := (cible.global_position - global_position).normalized()
			velocity = dir * vitesse
			_orienter_sprite(dir)
			move_and_slide()
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

func _trouver_cible_proche() -> Node2D:
	var racine := get_tree().current_scene
	var porteur := racine.get_node_or_null("Porteur")
	var guide := racine.get_node_or_null("Guide")

	var dist_p: float = INF
	var dist_g: float = INF

	if porteur and is_instance_valid(porteur):
		# Si Frodon est invisible, l'ennemi ne le cible pas !
		if not porteur.get("invisible"):
			dist_p = global_position.distance_to(porteur.global_position)

	if guide and is_instance_valid(guide):
		dist_g = global_position.distance_to(guide.global_position)

	if dist_p == INF and dist_g == INF:
		return null
	return porteur if dist_p <= dist_g else guide

func _orienter_sprite(dir: Vector2) -> void:
	if not _sprite:
		return
	if _sprite.hframes >= 4 and _sprite.vframes >= 4:
		var row: int = 0 # 0=Bas, 1=Gauche, 2=Droite, 3=Haut
		if abs(dir.x) > abs(dir.y):
			row = 1 if dir.x < 0 else 2
		else:
			row = 0 if dir.y > 0 else 3
		_sprite.frame = row * 4 + (int(Time.get_ticks_msec() / 150) % 4)
	else:
		_sprite.flip_h = dir.x < 0

func _sur_degats(montant: int, dir_recul: Vector2) -> void:
	if mort:
		return
	points_de_vie -= montant
	recul = dir_recul
	SonChiptune.jouer_impact()

	# Effet de flash blanc
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(5.0, 5.0, 5.0, 1.0), 0.08)
	tween.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)

	if points_de_vie <= 0:
		_mourir()

func _mourir() -> void:
	mort = true
	velocity = Vector2.ZERO
	if _hitbox:
		_hitbox.set_deferred("monitoring", false)
		_hitbox.set_deferred("monitorable", false)
	if _hurtbox:
		_hurtbox.set_deferred("monitoring", false)
		_hurtbox.set_deferred("monitorable", false)
	set_collision_layer_value(1, false)

	SonChiptune.jouer_impact()
	est_mort.emit()

	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.5, 0.2), 0.2)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
