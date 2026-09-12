class_name GestionnaireDialogues
extends Control

## ============================================================
## GestionnaireDialogues.gd
## Boîte de dialogue rétro style GBA (Pokémon / Zelda)
## Synchronisée par RPC entre les deux joueurs (Frodon & Sam).
## ============================================================

signal dialogue_termine
signal choix_valide(id_choix: String)

@onready var _panneau: Panel = $Panneau
@onready var _label_nom: Label = $Panneau/LabelNom
@onready var _label_texte: Label = $Panneau/LabelTexte
@onready var _portrait: TextureRect = $Panneau/Portrait
@onready var _bouton_suivant: Button = $Panneau/BoutonSuivant
@onready var _boite_choix: VBoxContainer = $PanneauChoix/VBoxChoix
@onready var _panneau_choix: Panel = $PanneauChoix
@onready var _titre_choix: Label = $PanneauChoix/TitreChoix

var _file_repliques: Array = []
var _index_replique: int = 0
var _en_cours: bool = false
var _en_attente_choix: bool = false

var _portraits := {
	"frodon": preload("res://assets/sprites/personnages/frodon.png"),
	"sam": preload("res://assets/sprites/personnages/sam.png"),
	"gandalf": preload("res://assets/sprites/personnages/gandalf.png"),
	"nazgul": preload("res://assets/sprites/personnages/nazgul.png")
}

func _ready() -> void:
	hide()
	_panneau_choix.hide()
	_bouton_suivant.pressed.connect(avancer_dialogue)


func demarrer_dialogue(repliques: Array) -> void:
	if not NetworkManager.connecte:
		_lancer_repliques_local(repliques)
		return
	_rpc_lancer_dialogue.rpc(repliques)

@rpc("any_peer", "call_local", "reliable")
func _rpc_lancer_dialogue(repliques: Array) -> void:
	_lancer_repliques_local(repliques)

func _lancer_repliques_local(repliques: Array) -> void:
	_file_repliques = repliques
	_index_replique = 0
	_en_cours = true
	_en_attente_choix = false
	_panneau_choix.hide()
	show()
	_afficher_replique_courante()

func _afficher_replique_courante() -> void:
	if _index_replique >= _file_repliques.size():
		_terminer_dialogue()
		return
	
	var r: Dictionary = _file_repliques[_index_replique]
	_label_nom.text = r.get("locuteur", "")
	_label_texte.text = r.get("texte", "")
	
	var p_id: String = r.get("portrait", "")
	if _portraits.has(p_id):
		_portrait.texture = _portraits[p_id]
		_portrait.show()
	else:
		_portrait.hide()

func avancer_dialogue() -> void:
	if not _en_cours or _en_attente_choix:
		return
	if not NetworkManager.connecte:
		_rpc_avancer()
		return
	_rpc_avancer.rpc()

@rpc("any_peer", "call_local", "reliable")
func _rpc_avancer() -> void:
	_index_replique += 1
	_afficher_replique_courante()

func _terminer_dialogue() -> void:
	_en_cours = false
	hide()
	dialogue_termine.emit()

## Affichage d'un choix partagé (🧭)
func proposer_choix(donnees_choix: Dictionary) -> void:
	if not NetworkManager.connecte:
		_rpc_afficher_choix(donnees_choix)
		return
	_rpc_afficher_choix.rpc(donnees_choix)

@rpc("any_peer", "call_local", "reliable")

func _rpc_afficher_choix(donnees_choix: Dictionary) -> void:
	_en_attente_choix = true
	_titre_choix.text = donnees_choix.get("titre_choix", "Que faire ?")
	
	for child in _boite_choix.get_children():
		child.queue_free()
		
	var options: Array = donnees_choix.get("options", [])
	for opt in options:
		var btn := Button.new()
		btn.text = opt.get("label", "")
		btn.custom_minimum_size = Vector2(0, 46)
		var id_opt: String = opt.get("id", "")
		btn.pressed.connect(func(): _sur_option_cliquee(id_opt))
		_boite_choix.add_child(btn)
		
	_panneau_choix.show()
	show()

func _sur_option_cliquee(id_choix: String) -> void:
	_rpc_valider_choix.rpc(id_choix)

@rpc("any_peer", "call_local", "reliable")
func _rpc_valider_choix(id_choix: String) -> void:
	_panneau_choix.hide()
	_en_attente_choix = false
	hide()
	choix_valide.emit(id_choix)
