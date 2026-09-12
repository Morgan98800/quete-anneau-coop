class_name GestionnaireActes
extends Node
## ============================================================
## GestionnaireActes.gd
## Coordonne la progression des 5 micro-actes narratifs GBA.
## Synchronise les changements de niveaux, la musique/sons et les choix moraux.
## ============================================================

signal acte_change(numero_acte: int)
signal partie_terminee_victoire(type_fin: String)

var acte_actuel: int = 1

# Mémoire des choix moraux de la partie
var choix_route_acte1: String = "route"
var choix_grandpas_acte2: bool = true
var choix_gollum_acte4: String = "epargne"

const INFOS_ACTES := {
	1: {
		"numero": "ACTE I",
		"titre": "L'OMBRE SUR LA COMTE",
		"scene_path": "res://scenes/actes/Acte1_Comte.tscn",
		"spawn_porteur": Vector2(180, 240),
		"spawn_guide": Vector2(140, 260),
		"destination": Vector2(1100, 800)
	},
	2: {
		"numero": "ACTE II",
		"titre": "LE MONT VENTEUX",
		"scene_path": "res://scenes/actes/Acte2_MontVenteux.tscn",
		"spawn_porteur": Vector2(160, 650),
		"spawn_guide": Vector2(120, 670),
		"destination": Vector2(650, 200)
	},
	3: {
		"numero": "ACTE III",
		"titre": "LES MINES DE LA MORIA",
		"scene_path": "res://scenes/actes/Acte3_Moria.tscn",
		"spawn_porteur": Vector2(140, 420),
		"spawn_guide": Vector2(100, 440),
		"destination": Vector2(1050, 420)
	},
	4: {
		"numero": "ACTE IV",
		"titre": "L'ANTRE D'ARACHNE",
		"scene_path": "res://scenes/actes/Acte4_CirithUngol.tscn",
		"spawn_porteur": Vector2(180, 750),
		"spawn_guide": Vector2(140, 770),
		"destination": Vector2(650, 180)
	},
	5: {
		"numero": "ACTE V",
		"titre": "LA MONTAGNE DU DESTIN",
		"scene_path": "res://scenes/actes/Acte5_MontagneDestin.tscn",
		"spawn_porteur": Vector2(250, 850),
		"spawn_guide": Vector2(210, 870),
		"destination": Vector2(600, 250)
	}
}

var _noeud_monde: Node2D
var _scene_acte_active: Node
var _banniere: Control
var _voile_noir: ColorRect
var _cadre_banniere: NinePatchRect
var _label_num: Label
var _label_titre: Label

func initialiser(noeud_monde: Node2D, banniere: Control) -> void:
	_noeud_monde = noeud_monde
	_banniere = banniere
	_voile_noir = banniere.get_node("VoileNoir")
	_cadre_banniere = banniere.get_node("Cadre")
	_label_num = banniere.get_node("Cadre/VBox/LabelNumero")
	_label_titre = banniere.get_node("Cadre/VBox/LabelTitre")
	_banniere.hide()
	_cadre_banniere.modulate.a = 0.0

func demarrer_campagne() -> void:
	acte_actuel = 1
	_appliquer_acte(1)

func passer_acte_suivant() -> void:
	if not NetworkManager.connecte:
		return
	var prochain := acte_actuel + 1
	if prochain > 5:
		return
	if NetworkManager.mode_solo:
		_rpc_changer_acte(prochain)
	else:
		_rpc_changer_acte.rpc(prochain)

@rpc("any_peer", "call_local", "reliable")
func _rpc_changer_acte(nouveau_numero: int) -> void:
	_transitionner_vers_acte(nouveau_numero)

func _transitionner_vers_acte(nouveau_numero: int) -> void:
	acte_actuel = nouveau_numero
	_banniere.show()
	_voile_noir.color.a = 0.0
	_cadre_banniere.modulate.a = 0.0

	var tween := create_tween()
	# 1. Fondu au noir
	tween.tween_property(_voile_noir, "color:a", 1.0, 0.35)
	# 2. Changement de scène et téléportation
	tween.tween_callback(func(): _appliquer_acte(nouveau_numero))
	# 3. Apparition de la bannière de titre
	tween.tween_interval(0.15)
	tween.tween_callback(func():
		SonChiptune.jouer_soin()
		var info: Dictionary = INFOS_ACTES[nouveau_numero]
		_label_num.text = "— %s —" % info["numero"]
		_label_titre.text = info["titre"]
	)
	tween.tween_property(_cadre_banniere, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.4)
	tween.tween_property(_cadre_banniere, "modulate:a", 0.0, 0.3)
	# 4. Réouverture de l'écran
	tween.tween_property(_voile_noir, "color:a", 0.0, 0.4)
	tween.tween_callback(func():
		_banniere.hide()
		acte_change.emit(nouveau_numero)
	)

func _appliquer_acte(numero: int) -> void:
	if not INFOS_ACTES.has(numero):
		return
	var info: Dictionary = INFOS_ACTES[numero]

	# Décharger l'acte précédent
	if _scene_acte_active and is_instance_valid(_scene_acte_active):
		_scene_acte_active.queue_free()

	# Charger la nouvelle scène d'acte
	var scene_res = load(info["scene_path"])
	if scene_res:
		_scene_acte_active = scene_res.instantiate()
		_noeud_monde.add_child(_scene_acte_active)

	# Téléporter les héros
	var porteur := _noeud_monde.get_parent().get_node_or_null("Porteur")
	var guide := _noeud_monde.get_parent().get_node_or_null("Guide")
	if porteur:
		porteur.global_position = info["spawn_porteur"]
		porteur.velocity = Vector2.ZERO
	if guide:
		guide.global_position = info["spawn_guide"]
		guide.velocity = Vector2.ZERO

func obtenir_destination_actuelle() -> Vector2:
	if INFOS_ACTES.has(acte_actuel):
		return INFOS_ACTES[acte_actuel]["destination"]
	return Vector2.ZERO

func calculer_type_fin() -> String:
	if choix_gollum_acte4 == "epargne":
		return "fin_canon"
	elif Corruption.valeur < 80.0:
		return "fin_amitie"
	else:
		return "fin_tenebres"
