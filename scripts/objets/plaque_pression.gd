class_name PlaquePression
extends Area2D
## ============================================================
## PlaquePression.gd — Dalle s'enfonçant sous le poids.
## ============================================================

signal etat_change(active: bool)

@export var porte_cible: NodePath
var est_enfoncee: bool = false
var _corps_presents: Array = []

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_sur_body_entered)
	body_exited.connect(_sur_body_exited)
	_mettre_a_jour_visuel()

func _sur_body_entered(body: Node2D) -> void:
	if not _corps_presents.has(body):
		_corps_presents.append(body)
	_verifier_etat()

func _sur_body_exited(body: Node2D) -> void:
	_corps_presents.erase(body)
	_verifier_etat()

func _verifier_etat() -> void:
	var nouvel_etat := _corps_presents.size() > 0
	if nouvel_etat != est_enfoncee:
		est_enfoncee = nouvel_etat
		SonChiptune.jouer_clic()
		_mettre_a_jour_visuel()
		etat_change.emit(est_enfoncee)
		if porte_cible and not porte_cible.is_empty():
			var p := get_node_or_null(porte_cible)
			if p and p.has_method("sur_plaque_etat_change"):
				p.sur_plaque_etat_change(est_enfoncee)

func _mettre_a_jour_visuel() -> void:
	if _sprite:
		# Objet donjon : Frame 0 = relâchée, Frame 1 = enfoncée (sur grille 4x4)
		_sprite.frame = 1 if est_enfoncee else 0
		_sprite.scale = Vector2(1.3, 1.3) if est_enfoncee else Vector2(1.5, 1.5)
