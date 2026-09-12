class_name Hitbox
extends Area2D
## ============================================================
## Hitbox.gd — Zone d'attaque infligeant des dégâts aux Hurtboxes.
## ============================================================

@export var degats: int = 1
@export var recul: float = 240.0
@export var camp: String = "joueur" # "joueur" ou "ennemi"

func _ready() -> void:
	monitoring = true
	monitorable = true
