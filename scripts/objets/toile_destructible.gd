class_name ToileDestructible
extends Area2D
## ============================================================
## ToileDestructible.gd — Toile d'araignée coupable à l'épée ou fiole.
## ============================================================

signal detruite

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if _hurtbox:
		_hurtbox.a_subi_degats.connect(_sur_degats)

func _sur_degats(_montant: int, _recul: Vector2) -> void:
	detruire()

func detruire() -> void:
	SonChiptune.jouer_epee()
	detruite.emit()
	if _collision:
		_collision.set_deferred("disabled", true)
	if _hurtbox:
		_hurtbox.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(_sprite, "scale", Vector2.ZERO, 0.25)
	tween.tween_callback(queue_free)
