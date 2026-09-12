extends Node2D
## ============================================================
## Main.gd — Chef d'orchestre de la Quête de l'Anneau.
## Gère la progression des 5 micro-actes, l'interface GBA,
## les dialogues, les choix moraux et le multijoueur/solo.
## ============================================================

@onready var _ui_connexion: Control = $CanvasLayer/UIConnexion
@onready var _ui_jeu: Control = $CanvasLayer/UIJeu
@onready var _label_statut: Label = $CanvasLayer/UIConnexion/CadreParcho/VBox/LabelStatut
@onready var _bouton_solo: Button = $CanvasLayer/UIConnexion/CadreParcho/VBox/BoutonSolo
@onready var _bouton_creer: Button = $CanvasLayer/UIConnexion/CadreParcho/VBox/BoutonCreer
@onready var _bouton_rejoindre: Button = $CanvasLayer/UIConnexion/CadreParcho/VBox/BoutonRejoindre
@onready var _bouton_basculer_manuel: Button = $CanvasLayer/UIConnexion/CadreParcho/VBox/BoutonBasculerManuel
@onready var _conteneur_manuel: VBoxContainer = $CanvasLayer/UIConnexion/CadreParcho/VBox/ConteneurManuel
@onready var _champ_code: LineEdit = $CanvasLayer/UIConnexion/CadreParcho/VBox/ConteneurManuel/ChampCode
@onready var _bouton_valider_manuel: Button = $CanvasLayer/UIConnexion/CadreParcho/VBox/ConteneurManuel/BoutonValiderManuel
@onready var _bouton_copier: Button = $CanvasLayer/UIConnexion/CadreParcho/VBox/ConteneurManuel/BoutonCopier
@onready var _bouton_plein_ecran: Button = $CanvasLayer/UIConnexion/CadreParcho/VBox/BoutonPleinEcran
@onready var _bouton_plein_ecran_jeu: Button = $CanvasLayer/UIJeu/BoutonPleinEcranJeu
@onready var _barre_corruption: ProgressBar = $CanvasLayer/UIJeu/BarreCorruption
@onready var _label_corruption: Label = $CanvasLayer/UIJeu/LabelCorruption
@onready var _bouton_action: Button = $CanvasLayer/UIJeu/BoutonAction

@onready var _fleche_boussole: Polygon2D = $CanvasLayer/UIJeu/Boussole/FlecheBoussole
@onready var _label_boussole: Label = $CanvasLayer/UIJeu/Boussole/LabelBoussole
@onready var _label_allie: Label = $CanvasLayer/UIJeu/LabelAllie

@onready var _ecran_victoire: Control = $CanvasLayer/EcranVictoire
@onready var _titre_v: Label = $CanvasLayer/EcranVictoire/BoiteV/TitreV
@onready var _desc_v: Label = $CanvasLayer/EcranVictoire/BoiteV/DescV
@onready var _bouton_rejouer_victoire: Button = $CanvasLayer/EcranVictoire/BoiteV/BoutonRejouerVictoire

@onready var _ecran_defaite: Control = $CanvasLayer/EcranDefaite
@onready var _bouton_rejouer_defaite: Button = $CanvasLayer/EcranDefaite/BoiteD/BoutonRejouerDefaite

@onready var _boite_dialogue: GestionnaireDialogues = $CanvasLayer/BoiteDialogue
@onready var _banniere_acte: Control = $CanvasLayer/BanniereTitreActe
@onready var _monde: Node2D = $Monde
@onready var _gestionnaire_actes: GestionnaireActes = $GestionnaireActes

var _porteur: CharacterBody2D
var _guide: CharacterBody2D
var _partie_terminee := false

var _dernier_dialogue_cle: String = ""
var _choix_intermediaire_fait := false
var _evenement_secondaire_fait := false
var _fin_declenchee := false

func _ready() -> void:
	_ui_jeu.hide()
	_ui_connexion.show()
	_conteneur_manuel.hide()
	_ecran_victoire.hide()
	_ecran_defaite.hide()
	
	NetworkManager.code_pret.connect(_sur_code_pret)
	NetworkManager.connexion_etablie.connect(_sur_connexion_etablie)
	NetworkManager.deconnexion.connect(_sur_deconnexion)
	NetworkManager.statut_change.connect(_sur_statut_change)
	
	Corruption.corruption_changee.connect(_sur_corruption_changee)
	Corruption.corruption_max.connect(_sur_corruption_max)
	
	_bouton_solo.pressed.connect(_sur_bouton_solo)
	_bouton_creer.pressed.connect(_sur_bouton_creer_auto)
	_bouton_rejoindre.pressed.connect(_sur_bouton_rejoindre_auto)
	_bouton_plein_ecran.pressed.connect(_basculer_plein_ecran)
	_bouton_plein_ecran_jeu.pressed.connect(_basculer_plein_ecran)
	_bouton_basculer_manuel.pressed.connect(_sur_basculer_manuel)
	_bouton_valider_manuel.pressed.connect(_sur_bouton_valider_manuel)
	_bouton_copier.pressed.connect(_sur_bouton_copier)
	_bouton_action.pressed.connect(_sur_bouton_action)
	_bouton_rejouer_victoire.pressed.connect(_sur_rejouer_clic)
	_bouton_rejouer_defaite.pressed.connect(_sur_rejouer_clic)

	_porteur = get_node_or_null("Porteur")
	_guide = get_node_or_null("Guide")

	_gestionnaire_actes.initialiser(_monde, _banniere_acte)
	_gestionnaire_actes.acte_change.connect(_sur_acte_change)
	_boite_dialogue.choix_valide.connect(_sur_choix_valide)
	_boite_dialogue.dialogue_termine.connect(_sur_dialogue_termine)
	
	if OS.has_feature("web"):
		var code_url: Variant = JavaScriptBridge.eval("new URLSearchParams(location.search).get('code')")
		if code_url is String and not code_url.is_empty():
			_champ_code.text = code_url
			_conteneur_manuel.show()
			_sur_bouton_valider_manuel()

func _sur_statut_change(texte: String) -> void:
	_label_statut.text = texte

func _sur_bouton_solo() -> void:
	SonChiptune.jouer_clic()
	_label_statut.text = "Lancement de l'aventure en solitaire..."
	_bouton_solo.disabled = true
	_bouton_creer.disabled = true
	_bouton_rejoindre.disabled = true
	NetworkManager.lancer_mode_solo()

func _sur_bouton_creer_auto() -> void:
	SonChiptune.jouer_clic()
	_bouton_solo.disabled = true
	_bouton_creer.disabled = true
	_bouton_rejoindre.disabled = true
	NetworkManager.lancer_auto_hote()

func _sur_bouton_rejoindre_auto() -> void:
	SonChiptune.jouer_clic()
	_bouton_creer.disabled = true
	_bouton_rejoindre.disabled = true
	NetworkManager.lancer_auto_invite()

func _sur_basculer_manuel() -> void:
	SonChiptune.jouer_clic()
	_conteneur_manuel.visible = not _conteneur_manuel.visible

func _sur_bouton_valider_manuel() -> void:
	SonChiptune.jouer_clic()
	var code := _champ_code.text.strip_edges()
	if code.is_empty():
		_label_statut.text = "Colle d'abord un code d'invitation !"
		return
	NetworkManager.mode_auto = false
	if NetworkManager.est_hote and code.contains("\"offre\""):
		_label_statut.text = "Tu es l'hôte ! Attends la RÉPONSE du Joueur 2."
		return
	if code.contains("\"offre\""):
		_label_statut.text = "Offre reçue ! Génération de la réponse..."
		_bouton_creer.disabled = true
		_bouton_rejoindre.disabled = true
		NetworkManager.rejoindre_session(code)
	elif code.contains("\"reponse\""):
		_label_statut.text = "Réponse reçue ! Finalisation P2P..."
		NetworkManager.appliquer_reponse(code)

func _sur_code_pret(texte_code: String, est_une_reponse: bool) -> void:
	if not NetworkManager.mode_auto:
		_label_statut.text = "Code généré ! Copie-le et envoie-le."
		_champ_code.text = texte_code
		_bouton_copier.show()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__codeSession=" + JSON.stringify(texte_code))

func _sur_bouton_copier() -> void:
	_copier_texte(_champ_code.text)
	_label_statut.text = "Code copié !"

func _copier_texte(texte: String) -> void:
	if OS.has_feature("web"):
		var navigateur = JavaScriptBridge.get_interface("navigator")
		if navigateur and navigateur.clipboard:
			navigateur.clipboard.writeText(texte)
			return
	DisplayServer.clipboard_set(texte)

func _basculer_plein_ecran() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			if (!document.fullscreenElement && !document.webkitFullscreenElement) {
				var el = document.documentElement;
				if (el.requestFullscreen) { el.requestFullscreen(); }
				else if (el.webkitRequestFullscreen) { el.webkitRequestFullscreen(); }
			} else {
				if (document.exitFullscreen) { document.exitFullscreen(); }
				else if (document.webkitExitFullscreen) { document.webkitExitFullscreen(); }
			}
		""")
	else:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _sur_connexion_etablie() -> void:
	_ui_connexion.hide()
	_ui_jeu.show()
	if NetworkManager.joue_porteur:
		_bouton_action.text = "Invisibilité"
	else:
		_bouton_action.text = "Soigner"
	_label_statut.text = "Connectés !"
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__connecte=true")

	var joueur_local: Node2D = _porteur if NetworkManager.joue_porteur else _guide
	if joueur_local:
		var camera: Camera2D = get_node("Camera2D")
		camera.reparent(joueur_local)
		camera.position = Vector2.ZERO
		camera.zoom = Vector2(1.55, 1.55)
		camera.make_current()

	# Démarrer la campagne à l'Acte 1
	_gestionnaire_actes.demarrer_campagne()
	_sur_acte_change(1)

func _sur_acte_change(numero: int) -> void:
	_choix_intermediaire_fait = false
	_evenement_secondaire_fait = false
	_fin_declenchee = false

	# Lancer la musique chiptune d'ambiance de l'acte
	SonChiptune.jouer_musique_acte(numero)

	# Lancement du dialogue d'ouverture de l'acte
	match numero:
		1:
			_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte1.json", "prologue_gandalf")
		2:
			_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte2.json", "intro_bree")
		3:
			_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte3.json", "portes_durin")
		4:
			_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte4.json", "rencontre_gollum")
		5:
			_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte5.json", "sommet_mont_destin")

func _lancer_dialogue_fichier(chemin_json: String, cle: String) -> void:
	var f := FileAccess.open(chemin_json, FileAccess.READ)
	if not f:
		return
	var contenu := f.get_as_text()
	var json := JSON.new()
	if json.parse(contenu) != OK:
		return
	var donnees: Dictionary = json.data
	if donnees.has(cle):
		_dernier_dialogue_cle = cle
		var bloc: Dictionary = donnees[cle]
		if bloc.has("repliques"):
			_boite_dialogue.demarrer_dialogue(bloc["repliques"])
		elif bloc.has("options"):
			_boite_dialogue.proposer_choix(bloc)

func _sur_choix_valide(id_choix: String) -> void:
	match id_choix:
		"foret":
			_gestionnaire_actes.choix_route_acte1 = "foret"
			Corruption.valeur = minf(Corruption.MAX, Corruption.valeur + 10.0)
			Corruption.corruption_changee.emit(Corruption.valeur)
		"route":
			_gestionnaire_actes.choix_route_acte1 = "route"
		"confiance":
			_gestionnaire_actes.choix_grandpas_acte2 = true
		"mefiance":
			_gestionnaire_actes.choix_grandpas_acte2 = false
		"epargne":
			_gestionnaire_actes.choix_gollum_acte4 = "epargne"
			Corruption.valeur = maxf(0.0, Corruption.valeur - 15.0)
			Corruption.corruption_changee.emit(Corruption.valeur)
		"chasse":
			_gestionnaire_actes.choix_gollum_acte4 = "chasse"
			Corruption.valeur = minf(Corruption.MAX, Corruption.valeur + 5.0)
			Corruption.corruption_changee.emit(Corruption.valeur)

func _sur_dialogue_termine() -> void:
	match _dernier_dialogue_cle:
		"intro_bree":
			_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte2.json", "choix_grandpas")
		"rencontre_gollum":
			_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte4.json", "choix_gollum")
		"sommet_mont_destin":
			var fin: String = _gestionnaire_actes.calculer_type_fin()
			_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte5.json", fin)
		"fin_canon", "fin_amitie", "fin_tenebres":
			_afficher_victoire_personnalisee(_dernier_dialogue_cle)

func _afficher_victoire_personnalisee(type_fin: String) -> void:
	_partie_terminee = true
	SonChiptune.jouer_victoire()
	match type_fin:
		"fin_canon":
			_titre_v.text = "🏆 FIN CANONIQUE : LA CHUTE DU PRÉCIEUX"
			_desc_v.text = "Gollum a bondi sur Frodon, arraché l'Anneau et basculé dans le magma !\nLa Terre du Milieu est libre. Merci pour votre coopération héroïque !"
		"fin_amitie":
			_titre_v.text = "💖 FIN FRATERNELLE : L'AMITIÉ DE SAM"
			_desc_v.text = "Les douces paroles de Sam ont brisé le charme de Sauron !\nFrodon a trouvé le courage de jeter lui-même l'Anneau dans la Crevasse !"
		"fin_tenebres":
			_titre_v.text = "🌑 FIN SOMBRE : LE SEIGNEUR DE L'ANNEAU"
			_desc_v.text = "La corruption était trop lourde... Frodon a passé l'Anneau à son doigt et revendique la couronne de Barad-dûr."
	_ecran_victoire.show()

func _sur_deconnexion() -> void:
	_ui_connexion.show()
	_ui_jeu.hide()
	_label_statut.text = "L'autre joueur s'est déconnecté."
	_bouton_creer.disabled = false
	_bouton_rejoindre.disabled = false

func _sur_corruption_changee(valeur: float) -> void:
	_barre_corruption.value = valeur
	_label_corruption.text = "👁️ Corruption de l'Anneau : %d%%" % int(valeur)

func _sur_corruption_max() -> void:
	if not _partie_terminee and NetworkManager.connecte:
		_partie_terminee = true
		if NetworkManager.mode_solo:
			_declencher_defaite()
		else:
			_declencher_defaite.rpc()

func _sur_rejouer_clic() -> void:
	SonChiptune.jouer_clic()
	if NetworkManager.mode_solo:
		_recommencer_partie()
	else:
		_recommencer_partie.rpc()

@rpc("any_peer", "call_local", "reliable")
func _declencher_defaite() -> void:
	_partie_terminee = true
	SonChiptune.jouer_defaite()
	_ecran_defaite.show()

@rpc("any_peer", "call_local", "reliable")
func _recommencer_partie() -> void:
	_partie_terminee = false
	_ecran_victoire.hide()
	_ecran_defaite.hide()
	Corruption.reinitialiser()
	if _porteur:
		_porteur.invisible = false
		_porteur._appliquer_apparence()
	_gestionnaire_actes.demarrer_campagne()
	_sur_acte_change(1)

func _sur_bouton_action() -> void:
	if not NetworkManager.connecte or _partie_terminee:
		return
	if NetworkManager.joue_porteur:
		if _porteur: _porteur.basculer_invisibilite()
	else:
		if _guide: _guide.interagir()

func _process(_delta: float) -> void:
	if not NetworkManager.connecte or _partie_terminee:
		return

	var joueur_local: Node2D = _porteur if NetworkManager.joue_porteur else _guide
	if not joueur_local:
		return

	var destination: Vector2 = _gestionnaire_actes.obtenir_destination_actuelle()
	var dist_dest: float = joueur_local.global_position.distance_to(destination)
	_label_boussole.text = "Objectif : %d m" % int(dist_dest)
	_fleche_boussole.rotation = (destination - joueur_local.global_position).angle()

	if _porteur and _guide:
		var dist_allie: float = _porteur.global_position.distance_to(_guide.global_position)
		_label_allie.text = "👥 Allié : %d m" % int(dist_allie)

	# Détection de transition vers l'acte suivant
	if dist_dest < 75.0:
		if _gestionnaire_actes.acte_actuel < 5:
			if NetworkManager.est_hote or NetworkManager.mode_solo:
				_gestionnaire_actes.passer_acte_suivant()
		elif not _fin_declenchee:
			_fin_declenchee = true
			_sur_dialogue_termine()

	# Événements et choix contextuels au fil des actes
	var acte := _gestionnaire_actes.acte_actuel
	if acte == 1 and not _choix_intermediaire_fait and joueur_local.global_position.x > 420.0:
		_choix_intermediaire_fait = true
		_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte1.json", "choix_route_foret")
	elif acte == 2 and not _evenement_secondaire_fait and joueur_local.global_position.y < 380.0:
		_evenement_secondaire_fait = true
		_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte2.json", "attaque_mont_venteux")
	elif acte == 3 and not _evenement_secondaire_fait and joueur_local.global_position.x > 720.0:
		_evenement_secondaire_fait = true
		_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte3.json", "pont_khazad_dum")
	elif acte == 4 and not _evenement_secondaire_fait and joueur_local.global_position.y < 460.0:
		_evenement_secondaire_fait = true
		_lancer_dialogue_fichier("res://data/dialogues/dialogues_acte4.json", "boss_arachne")
