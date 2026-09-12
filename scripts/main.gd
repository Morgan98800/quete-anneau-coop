extends Node2D
## ============================================================
## Main.gd — Chef d'orchestre de la scène.
## Gère l'interface de connexion, les boutons de jeu,
## et relie les personnages au NetworkManager.
## ============================================================

# Références aux nœuds de l'interface (à remplir dans l'éditeur)
@onready var _ui_connexion: Control = $CanvasLayer/UIConnexion
@onready var _ui_jeu: Control = $CanvasLayer/UIJeu
@onready var _label_statut: Label = $CanvasLayer/UIConnexion/VBox/LabelStatut
@onready var _bouton_creer: Button = $CanvasLayer/UIConnexion/VBox/BoutonCreer
@onready var _bouton_rejoindre: Button = $CanvasLayer/UIConnexion/VBox/BoutonRejoindre
@onready var _bouton_basculer_manuel: Button = $CanvasLayer/UIConnexion/VBox/BoutonBasculerManuel
@onready var _conteneur_manuel: VBoxContainer = $CanvasLayer/UIConnexion/VBox/ConteneurManuel
@onready var _champ_code: LineEdit = $CanvasLayer/UIConnexion/VBox/ConteneurManuel/ChampCode
@onready var _bouton_valider_manuel: Button = $CanvasLayer/UIConnexion/VBox/ConteneurManuel/BoutonValiderManuel
@onready var _bouton_copier: Button = $CanvasLayer/UIConnexion/VBox/ConteneurManuel/BoutonCopier
@onready var _bouton_plein_ecran: Button = $CanvasLayer/UIConnexion/VBox/BoutonPleinEcran
@onready var _bouton_plein_ecran_jeu: Button = $CanvasLayer/UIJeu/BoutonPleinEcranJeu
@onready var _barre_corruption: ProgressBar = $CanvasLayer/UIJeu/BarreCorruption
@onready var _label_corruption: Label = $CanvasLayer/UIJeu/LabelCorruption
@onready var _bouton_action: Button = $CanvasLayer/UIJeu/BoutonAction

@onready var _fleche_boussole: Polygon2D = $CanvasLayer/UIJeu/Boussole/FlecheBoussole
@onready var _label_boussole: Label = $CanvasLayer/UIJeu/Boussole/LabelBoussole
@onready var _label_allie: Label = $CanvasLayer/UIJeu/LabelAllie

@onready var _ecran_victoire: Control = $CanvasLayer/EcranVictoire
@onready var _bouton_rejouer_victoire: Button = $CanvasLayer/EcranVictoire/BoiteV/BoutonRejouerVictoire
@onready var _ecran_defaite: Control = $CanvasLayer/EcranDefaite
@onready var _bouton_rejouer_defaite: Button = $CanvasLayer/EcranDefaite/BoiteD/BoutonRejouerDefaite

@onready var _lave_pulsante: Polygon2D = $Monde/Destination/LavePulsante

const DESTINATION := Vector2(3000, 3000)
const SPAWN_PORTEUR := Vector2(490, 420)
const SPAWN_GUIDE := Vector2(390, 470)

var _porteur: CharacterBody2D
var _guide: CharacterBody2D
var _partie_terminee := false

func _ready() -> void:
	# On cache l'UI de jeu au début, on montre celle de connexion.
	_ui_jeu.hide()
	_ui_connexion.show()
	_conteneur_manuel.hide()
	_ecran_victoire.hide()
	_ecran_defaite.hide()
	
	# Connexion des signaux du NetworkManager.
	NetworkManager.code_pret.connect(_sur_code_pret)
	NetworkManager.connexion_etablie.connect(_sur_connexion_etablie)
	NetworkManager.deconnexion.connect(_sur_deconnexion)
	NetworkManager.statut_change.connect(_sur_statut_change)
	
	# Connexion des signaux de la Corruption.
	Corruption.corruption_changee.connect(_sur_corruption_changee)
	Corruption.corruption_max.connect(_sur_corruption_max)
	
	# Connexion des boutons de l'interface.
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

	# On récupère les instances des personnages placés dans la scène.
	_porteur = get_node_or_null("Porteur")
	_guide = get_node_or_null("Guide")

	
	# Sur le Web : permet de rejoindre directement via un lien ?code=...
	if OS.has_feature("web"):
		var code_url: Variant = JavaScriptBridge.eval("new URLSearchParams(location.search).get('code')")
		if code_url is String and not code_url.is_empty():
			_champ_code.text = code_url
			_conteneur_manuel.show()
			_sur_bouton_valider_manuel()

func _sur_statut_change(texte: String) -> void:
	_label_statut.text = texte

func _sur_bouton_creer_auto() -> void:
	_bouton_creer.disabled = true
	_bouton_rejoindre.disabled = true
	NetworkManager.lancer_auto_hote()

func _sur_bouton_rejoindre_auto() -> void:
	_bouton_creer.disabled = true
	_bouton_rejoindre.disabled = true
	NetworkManager.lancer_auto_invite()

func _sur_basculer_manuel() -> void:
	_conteneur_manuel.visible = not _conteneur_manuel.visible

func _sur_bouton_valider_manuel() -> void:
	var code := _champ_code.text.strip_edges()
	if code.is_empty():
		_label_statut.text = "Colle d'abord un code d'invitation !"
		return
	NetworkManager.mode_auto = false
	if NetworkManager.est_hote and code.contains("\"offre\""):
		_label_statut.text = "Tu es l'hôte ! Tu dois attendre le code RÉPONSE du Joueur 2."
		return
	if code.contains("\"offre\""):
		_label_statut.text = "Offre reçue ! Génération de la réponse..."
		_bouton_creer.disabled = true
		_bouton_rejoindre.disabled = true
		NetworkManager.rejoindre_session(code)
	elif code.contains("\"reponse\""):
		_label_statut.text = "Réponse reçue ! Finalisation de la connexion P2P..."
		NetworkManager.appliquer_reponse(code)
	else:
		_label_statut.text = "Code invalide ! Assure-toi de copier l'intégralité du texte JSON."

func _sur_code_pret(texte_code: String, est_une_reponse: bool) -> void:
	if not NetworkManager.mode_auto:
		if est_une_reponse:
			_label_statut.text = "Étape 2 : Réponse générée ! Copie ce code et renvoie-le à l'hôte."
		else:
			_label_statut.text = "Étape 1 : Code généré ! Copie-le et envoie-le au Joueur 2."
		_champ_code.text = texte_code
		_bouton_copier.show()
	
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__codeSession=" + JSON.stringify(texte_code))

func _sur_bouton_copier() -> void:
	_copier_texte(_champ_code.text)
	_label_statut.text = "Code copié ! Envoie-le par message."


## Copie un texte dans le presse-papier, de façon fiable sur le Web.
func _copier_texte(texte: String) -> void:
	# Sur le Web, DisplayServer.clipboard_set n'est pas fiable : on passe
	# par l'API Clipboard du navigateur (exige un geste utilisateur — le
	# clic sur ce bouton — et un contexte sécurisé HTTPS, OK sur itch.io).
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
	# On configure le bouton d'action selon notre rôle.
	if NetworkManager.joue_porteur:
		_bouton_action.text = "Invisibilité"
	else:
		_bouton_action.text = "Soigner"
	_label_statut.text = "Connectés !"
	# Sur le Web, on signale l'état à la page (tests automatisés, debug).
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__connecte=true")
	# La caméra suit NOTRE personnage.
	var joueur_local: Node2D = _porteur if NetworkManager.joue_porteur else _guide
	if joueur_local:
		var camera: Camera2D = get_node("Camera2D")
		camera.reparent(joueur_local)
		camera.position = Vector2.ZERO
		camera.make_current()

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
		_declencher_defaite.rpc()

func _sur_rejouer_clic() -> void:
	_recommencer_partie.rpc()

@rpc("any_peer", "call_local", "reliable")
func _declencher_victoire() -> void:
	_partie_terminee = true
	_ecran_victoire.show()

@rpc("any_peer", "call_local", "reliable")
func _declencher_defaite() -> void:
	_partie_terminee = true
	_ecran_defaite.show()

@rpc("any_peer", "call_local", "reliable")
func _recommencer_partie() -> void:
	_partie_terminee = false
	_ecran_victoire.hide()
	_ecran_defaite.hide()
	Corruption.reinitialiser()
	if _porteur:
		_porteur.global_position = SPAWN_PORTEUR
		_porteur.velocity = Vector2.ZERO
		_porteur.invisible = false
		_porteur._appliquer_apparence()
	if _guide:
		_guide.global_position = SPAWN_GUIDE
		_guide.velocity = Vector2.ZERO

func _sur_bouton_action() -> void:
	if not NetworkManager.connecte or _partie_terminee:
		return
	if NetworkManager.joue_porteur:
		if _porteur: _porteur.basculer_invisibilite()
	else:
		if _guide: _guide.interagir()


func _process(_delta: float) -> void:
	# Animation du cratère de lave
	if _lave_pulsante:
		var pulse := 1.0 + 0.1 * sin(Time.get_ticks_msec() * 0.003)
		_lave_pulsante.scale = Vector2(pulse, pulse)

	# Mise à jour du HUD en jeu
	if NetworkManager.connecte and not _partie_terminee:
		var joueur_local: Node2D = _porteur if NetworkManager.joue_porteur else _guide
		if joueur_local:
			var dist_dest := joueur_local.global_position.distance_to(DESTINATION)
			_label_boussole.text = "Montagne du Destin : %d m" % int(dist_dest)
			_fleche_boussole.rotation = (DESTINATION - joueur_local.global_position).angle()
		
		if _porteur and _guide:
			var dist_allie := _porteur.global_position.distance_to(_guide.global_position)
			_label_allie.text = "👥 Allié : %d m" % int(dist_allie)
			
			# Vérification de victoire : les deux joueurs doivent atteindre le cratère
			if NetworkManager.est_hote and not _partie_terminee:
				if _porteur.global_position.distance_to(DESTINATION) < 180.0 \
						and _guide.global_position.distance_to(DESTINATION) < 180.0:
					_declencher_victoire.rpc()

	# Pont Web de signalisation (reprise de réponse manuelle si besoin)
	if not OS.has_feature("web"):
		return
	if not NetworkManager.est_hote or NetworkManager.connecte:
		return
	var reponse: Variant = JavaScriptBridge.eval("window.__reponseAAppliquer ?? null")
	if reponse is String and not reponse.is_empty():
		JavaScriptBridge.eval("window.__reponseAAppliquer=null")
		_champ_code.text = reponse
		NetworkManager.appliquer_reponse(reponse)
