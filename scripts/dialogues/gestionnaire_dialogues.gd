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
	"nazgul": preload("res://assets/sprites/personnages/nazgul.png"),
	"aragorn": preload("res://assets/sprites/personnages/aragorn.png"),
	"gollum": preload("res://assets/sprites/personnages/gollum.png"),
	"arachne": preload("res://assets/sprites/personnages/arachne.png")
}

func _ready() -> void:
	hide()
	_panneau_choix.hide()
	_bouton_suivant.pressed.connect(avancer_dialogue)


var _frappe_active: bool = false
var _frappe_tween: Tween

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
	if _frappe_tween and _frappe_tween.is_valid():
		_frappe_tween.kill()

	if _index_replique >= _file_repliques.size():
		_terminer_dialogue()
		return
	
	var r: Dictionary = _file_repliques[_index_replique]
	var locuteur: String = r.get("locuteur", "")
	var texte: String = r.get("texte", "")
	_label_nom.text = locuteur
	_label_texte.text = texte
	
	var p_id: String = r.get("portrait", "")
	if _portraits.has(p_id):
		_portrait.texture = _portraits[p_id]
		_portrait.show()
	else:
		_portrait.hide()

	# Hauteur de voix selon le personnage (GBA style)
	var pitch: float = 1.0
	match p_id:
		"gandalf": pitch = 0.65
		"frodon": pitch = 1.05
		"sam": pitch = 0.88
		"nazgul": pitch = 0.45
		"aragorn": pitch = 0.80
		"gollum": pitch = 1.35
		"arachne": pitch = 0.35

	# Effet machine à écrire rétro (Typewriter)
	_label_texte.visible_characters = 0
	_frappe_active = true
	var duree: float = texte.length() * 0.028
	_frappe_tween = create_tween()
	_frappe_tween.tween_property(_label_texte, "visible_characters", texte.length(), duree)
	
	# Sons de bips réguliers pendant le défilement
	var nb_bips: int = max(1, texte.length() / 2)
	for i in range(nb_bips):
		_frappe_tween.parallel().tween_callback(func():
			if _frappe_active:
				SonChiptune.jouer_bip_dialogue(pitch)
		).set_delay(i * 0.055)
	
	_frappe_tween.finished.connect(func(): _frappe_active = false)

func avancer_dialogue() -> void:
	if not _en_cours or _en_attente_choix:
		return
	
	# Si le texte est encore en train de s'afficher, on le complète immédiatement
	if _frappe_active:
		if _frappe_tween and _frappe_tween.is_valid():
			_frappe_tween.kill()
		_label_texte.visible_characters = -1
		_frappe_active = false
		return

	SonChiptune.jouer_clic()
	if not NetworkManager.connecte:
		_rpc_avancer()
		return
	_rpc_avancer.rpc()

@rpc("any_peer", "call_local", "reliable")
func _rpc_avancer() -> void:
	_index_replique += 1
	_afficher_replique_courante()

func _terminer_dialogue() -> void:
	if _frappe_tween and _frappe_tween.is_valid():
		_frappe_tween.kill()
	_frappe_active = false
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
	SonChiptune.jouer_clic()
	if not NetworkManager.connecte:
		_rpc_valider_choix(id_choix)
		return
	_rpc_valider_choix.rpc(id_choix)

@rpc("any_peer", "call_local", "reliable")
func _rpc_valider_choix(id_choix: String) -> void:
	_panneau_choix.hide()
	_en_attente_choix = false
	hide()
	choix_valide.emit(id_choix)
