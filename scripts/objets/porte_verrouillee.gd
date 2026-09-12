class_name PorteVerrouillee
extends StaticBody2D
## ============================================================
## PorteVerrouillee.gd — Herse ou porte s'ouvrant par clé ou dalles.
## ============================================================

signal porte_ouverte

@export var mode_deverrouillage: String = "cle" # "cle" ou "plaques"
@export var plaques_requises: int = 1
@export var message_verrouille: String = "Il faut une clé ancienne..."

var est_ouverte: bool = false
var _plaques_actives: int = 0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visuel: Node2D = $Visuel
@onready var _zone_interaction: Area2D = $ZoneInteraction

func _ready() -> void:
	if _zone_interaction:
		_zone_interaction.body_entered.connect(_sur_joueur_proche)

func _sur_joueur_proche(body: Node2D) -> void:
	if est_ouverte:
		return
	if mode_deverrouillage == "cle":
		if body.name == "Porteur" or body.name == "Guide":
			if GestionnaireVie.utiliser_cle():
				ouvrir()

func sur_plaque_etat_change(active: bool) -> void:
	if est_ouverte:
		return
	_plaques_actives += (1 if active else -1)
	_plaques_actives = maxi(0, _plaques_actives)
	if _plaques_actives >= plaques_requises:
		ouvrir()

func ouvrir() -> void:
	if est_ouverte:
		return
	est_ouverte = true
	SonChiptune.jouer_porte()
	_collision.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(_visuel, "modulate:a", 0.15, 0.4)
	tween.parallel().tween_property(_visuel, "scale:y", 0.1, 0.4)
	porte_ouverte.emit()
