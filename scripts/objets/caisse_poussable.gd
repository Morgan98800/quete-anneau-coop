class_name CaissePoussable
extends CharacterBody2D
## ============================================================
## CaissePoussable.gd — Bloc de bois/pierre poussable style Sokoban/Zelda.
## ============================================================

const VITESSE_POUSSEE: float = 120.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func pousser(direction: Vector2) -> void:
	velocity = direction.normalized() * VITESSE_POUSSEE
	move_and_slide()

func _physics_process(delta: float) -> void:
	if velocity.length() > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, delta * 300.0)
		move_and_slide()
