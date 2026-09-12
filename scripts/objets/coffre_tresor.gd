class_name CoffreTresor
extends Area2D
## ============================================================
## CoffreTresor.gd — Coffre contenant clé ancienne ou lembas.
## ============================================================

signal coffre_ouvert(type_contenu: String)

@export_enum("cle", "lembas") var contenu: String = "cle"
var est_ouvert: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_sur_body_entered)
	_actualiser_sprite()

func _sur_body_entered(body: Node2D) -> void:
	if est_ouvert:
		return
	if body.name == "Porteur" or body.name == "Guide":
		ouvrir()

func ouvrir() -> void:
	if est_ouvert:
		return
	est_ouvert = true
	_actualiser_sprite()
	if contenu == "cle":
		GestionnaireVie.ajouter_cle()
	elif contenu == "lembas":
		GestionnaireVie.ajouter_lembas()
	coffre_ouvert.emit(contenu)

func _actualiser_sprite() -> void:
	if _sprite:
		# Frame 2 = fermé, Frame 3 = ouvert
		_sprite.frame = 3 if est_ouvert else 2
