class_name Hurtbox
extends Area2D
## ============================================================
## Hurtbox.gd — Zone réceptrice de dégâts avec invulnérabilité.
## ============================================================

signal a_subi_degats(montant: int, direction_recul: Vector2)

@export var camp: String = "joueur" # doit être opposé au camp de la Hitbox
@export var temps_invulnerabilite: float = 0.5

var est_invulnerable: bool = false
var _chrono_invuln: float = 0.0

func _ready() -> void:
	area_entered.connect(_sur_area_entered)

func _process(delta: float) -> void:
	if est_invulnerable:
		_chrono_invuln -= delta
		if _chrono_invuln <= 0.0:
			est_invulnerable = false

func _sur_area_entered(autre: Area2D) -> void:
	if autre is Hitbox:
		var hitbox := autre as Hitbox
		if hitbox.camp != camp and not est_invulnerable:
			est_invulnerable = true
			_chrono_invuln = temps_invulnerabilite
			var dir := (global_position - hitbox.global_position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.UP
			a_subi_degats.emit(hitbox.degats, dir * hitbox.recul)
