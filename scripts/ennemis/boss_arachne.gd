class_name BossArachne
extends CharacterBody2D
## ============================================================
## BossArachne.gd — Combat de Boss contre Shelob (Arachne) à phases.
## ============================================================

signal boss_vaincu

@export var points_de_vie: int = 10
var est_etourdie: bool = false
var _chrono_attaque: float = 0.0
var _recul: Vector2 = Vector2.ZERO
var _mort: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $Hitbox

func _ready() -> void:
	if _hurtbox:
		_hurtbox.camp = "ennemi"
		_hurtbox.a_subi_degats.connect(_sur_degats)
	if _hitbox:
		_hitbox.camp = "ennemi"
		_hitbox.degats = 2

func _physics_process(delta: float) -> void:
	if _mort:
		return

	if _recul.length() > 5.0:
		velocity = _recul
		_recul = _recul.move_toward(Vector2.ZERO, delta * 600.0)
		move_and_slide()
		return

	if est_etourdie:
		velocity = Vector2.ZERO
		return

	_chrono_attaque += delta
	var cible: Node2D = _trouver_cible()
	if not cible:
		return

	var dist := global_position.distance_to(cible.global_position)
	var dir := (cible.global_position - global_position).normalized()

	# Phase de charge bondissante toutes les 3.5 secondes
	if _chrono_attaque >= 3.2:
		velocity = dir * 260.0 # Bond d'attaque rapide
		if _chrono_attaque >= 4.0:
			_chrono_attaque = 0.0
	else:
		velocity = dir * 85.0 # Traque lente

	_sprite.rotation = dir.angle() + PI / 2.0
	move_and_slide()

func _trouver_cible() -> Node2D:
	var racine := get_tree().current_scene
	var porteur := racine.get_node_or_null("Porteur")
	var guide := racine.get_node_or_null("Guide")
	if porteur and not porteur.get("invisible"):
		return porteur
	return guide

func etourdir(duree: float = 2.5) -> void:
	if est_etourdie or _mort:
		return
	est_etourdie = true
	SonChiptune.jouer_soin()
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(2.5, 2.5, 1.2, 1.0), 0.2)
	tween.tween_interval(duree)
	tween.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	tween.tween_callback(func(): est_etourdie = false)

func _sur_degats(montant: int, dir_recul: Vector2) -> void:
	if _mort:
		return
	# Si étourdie par la Fiole de Galadriel, subit le double de dégâts !
	var degats_infliges: int = montant * (2 if est_etourdie else 1)
	points_de_vie -= degats_infliges
	_recul = dir_recul * 0.5
	SonChiptune.jouer_impact()

	# Flash blanc de coup
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(4.0, 1.0, 1.0, 1.0), 0.1)
	tween.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

	if points_de_vie <= 0:
		_mourir()

func _mourir() -> void:
	_mort = true
	velocity = Vector2.ZERO
	if _hitbox:
		_hitbox.set_deferred("monitoring", false)
	SonChiptune.jouer_victoire()
	boss_vaincu.emit()

	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(2.0, 0.1), 0.4)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
