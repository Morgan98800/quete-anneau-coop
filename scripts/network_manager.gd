extends Node
## ============================================================
## NetworkManager (AUTOLOAD)
## Gère la connexion P2P entre les deux joueurs via WebRTC.
##
## IMPORTANT : en export Web (HTML5/Safari), Godot utilise le WebRTC
## NATIF du navigateur. AUCUN plugin binaire n'est nécessaire.
## Seule la "signalisation" (échange initial des codes) est gérée
## ici à la main, par copier-coller (via WhatsApp, Messages, etc.).
##
## Alternative plus confortable (Godot 4.5) : l'addon Tube
## (https://github.com/koopmyers/tube) remplace cette signalisation
## manuelle par un vrai ID de session court. Les scripts de gameplay
## (porteur.gd / guide.gd) n'ont PAS besoin d'être modifiés.
## ============================================================

## Émis quand un code (offre ou réponse) est prêt à être envoyé.
signal code_pret(texte_code: String, est_une_reponse: bool)
## Émis quand les deux joueurs sont connectés.
signal connexion_etablie
## Émis si l'autre joueur se déconnecte.
signal deconnexion
## Émis pour mettre à jour le message d'état en mode automatique.
signal statut_change(texte: String)

## Salle de signalisation publique et gratuite (zéro compte, zéro configuration)
const URL_SIGNAL := "https://api.restful-api.dev/objects/ff808181a067127101a09778a7000452"

## Identifiants fixes des deux pairs : 1 = hôte (créateur), 2 = invité.
const ID_HOTE := 1
const ID_INVITE := 2

## Serveur STUN public (Google) : indispensable pour traverser les box/NAT.
const SERVEURS_ICE := [{"urls": "stun:stun.l.google.com:19302"}]

## Vrai quand la connexion WebRTC est établie.
var connecte := false
## Vrai si CE téléphone joue le Porteur (l'hôte joue le Porteur).
var joue_porteur := true
## Vrai si CE téléphone a créé la session.
var est_hote := false

var mode_auto := true
var _polling_actif := false
var _polling_chrono := 0.0
var _derniere_offre := ""
var _derniere_reponse := ""

var _peer: WebRTCMultiplayerPeer
var _conn: WebRTCPeerConnection
var _candidats: Array = []
var _code_emis := false  # garde-fou : n'émet le code qu'une seule fois
var _chrono_emission := 0.0   # secondes écoulées depuis la description locale
var _description_prete := false
var _description_locale := ""


# ------------------------------------------------------------
# API publique — Mode Automatique (Zéro Code)
# ------------------------------------------------------------

## JOUEUR 1 : Porteur — démarre la session et attend automatiquement le Guide.
func lancer_auto_hote() -> void:
	mode_auto = true
	_derniere_offre = ""
	_derniere_reponse = ""
	_polling_actif = false
	statut_change.emit("Initialisation de la session...")
	_envoyer_signal({"offre": "", "reponse": "", "timestamp": int(Time.get_unix_time_from_system())})
	creer_session()


## JOUEUR 2 : Guide — recherche automatiquement la session du Porteur.
func lancer_auto_invite() -> void:
	mode_auto = true
	_derniere_offre = ""
	_derniere_reponse = ""
	_polling_actif = true
	_polling_chrono = 1.0  # vérification quasi-immédiate
	statut_change.emit("Recherche de la partie du Joueur 1 (Porteur)...")
	_verifier_signal()


# ------------------------------------------------------------
# API publique — Mode Manuel (Copier-Coller)
# ------------------------------------------------------------

## JOUEUR 1 — crée la session et génère le code d'invitation.
func creer_session() -> void:
	est_hote = true
	joue_porteur = true
	_init_peer(ID_HOTE)
	_conn.create_offer()  # déclenche la génération du code "offre"


## JOUEUR 2 — colle le code d'invitation reçu, génère un code "réponse".
func rejoindre_session(code: String) -> void:
	var donnees: Variant = _decoder_code(code)
	if donnees == null or donnees.get("type") != "offre" or not (donnees.get("sdp") is String):
		push_error("NetworkManager : code invalide, ce n'est pas une offre.")
		return
	est_hote = false
	joue_porteur = false
	_init_peer(ID_INVITE)
	# On applique d'abord la description distante, PUIS les candidats ICE.
	_conn.set_remote_description("offer", str(donnees["sdp"]))
	for c in donnees.get("candidats", []):
		_conn.add_ice_candidate(c["media"], int(c["index"]), c["name"])
	# Une description distante étant déjà définie, create_offer()
	# produit automatiquement une RÉPONSE.
	_conn.create_offer()


## JOUEUR 1 — colle le code "réponse" renvoyé par le Joueur 2.
func appliquer_reponse(code: String) -> void:
	var donnees: Variant = _decoder_code(code)
	if donnees == null or donnees.get("type") != "reponse" or not (donnees.get("sdp") is String):
		push_error("NetworkManager : code invalide, ce n'est pas une réponse.")
		return
	_conn.set_remote_description("answer", str(donnees["sdp"]))
	for c in donnees.get("candidats", []):
		_conn.add_ice_candidate(c["media"], int(c["index"]), c["name"])


# ------------------------------------------------------------
# Initialisation interne
# ------------------------------------------------------------

func _init_peer(id_local: int) -> void:
	# 1. Peer mesh 1-contre-1 (chaque joueur est pair 1 ou 2).
	_peer = WebRTCMultiplayerPeer.new()
	_peer.create_mesh(id_local)
	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_connected.connect(_sur_pair_connecte)
	multiplayer.peer_disconnected.connect(_sur_pair_deconnecte)

	# 2. Connexion WebRTC avec serveur STUN.
	_candidats = []
	_code_emis = false
	_chrono_emission = 0.0
	_description_prete = false
	_conn = WebRTCPeerConnection.new()
	_conn.initialize({"iceServers": SERVEURS_ICE})
	_conn.session_description_created.connect(_sur_description_creee)
	_conn.ice_candidate_created.connect(_sur_candidat_cree)

	# 3. On l'attache au peer (l'autre pair aura l'ID opposé).
	var id_distant := ID_INVITE if id_local == ID_HOTE else ID_HOTE
	_peer.add_peer(_conn, id_distant)


func _decoder_code(code: String) -> Variant:
	var donnees: Variant = JSON.parse_string(code.strip_edges())
	if donnees == null or donnees is not Dictionary:
		return null
	return donnees


# ------------------------------------------------------------
# Réactions aux signaux WebRTC
# ------------------------------------------------------------

## Notre propre description locale (offre ou réponse) a été générée.
## (Ce signal n'est émis que pendant le poll : voir _process ci-dessous.)
func _sur_description_creee(type: String, sdp: String) -> void:
	_description_locale = sdp
	_description_prete = true
	_conn.set_local_description(type, sdp)


## Un candidat ICE (route réseau) a été découvert : on le stocke.
func _sur_candidat_cree(media: String, index: int, nom: String) -> void:
	_candidats.append({"media": media, "index": index, "name": nom})


## Poll continu : indispensable pour le WebRTC Godot !
## _conn.poll() DOIT tourner en permanence pour traiter les paquets et l'état de connexion.
## Pendant la phase de signalisation, on surveille la description et les candidats ICE.
func _process(delta: float) -> void:
	if _test_actif:
		_boucle_auto_test(delta)
		return
	if _conn != null:
		# Poll continu obligatoire pour WebRTC
		_conn.poll()

		if not _code_emis:
			if _description_prete:
				if _conn.get_gathering_state() == WebRTCPeerConnection.GATHERING_STATE_COMPLETE:
					_emettre_code()
				else:
					_chrono_emission += delta
					if _chrono_emission >= 1.8:
						_emettre_code()

	# Polling automatique de la salle de signalisation
	if _polling_actif and not connecte:
		_polling_chrono += delta
		if _polling_chrono >= 1.0:
			_polling_chrono = 0.0
			_verifier_signal()
			_lire_reponse_signal()


func _emettre_code() -> void:
	if _code_emis:
		return  # déjà envoyé (via la récolte terminée ou le minuteur)
	_code_emis = true
	var type_code := "offre" if est_hote else "reponse"
	var paquet := {
		"type": type_code,
		"sdp": _description_locale,
		"candidats": _candidats,
	}
	var json_code := JSON.stringify(paquet)
	code_pret.emit(json_code, not est_hote)

	if mode_auto:
		if est_hote:
			_derniere_offre = json_code
			_envoyer_signal({
				"offre": json_code,
				"reponse": "",
				"timestamp": int(Time.get_unix_time_from_system())
			})
			statut_change.emit("Partie prête ! En attente du Joueur 2 (Guide)...")
			_polling_actif = true
		else:
			_envoyer_signal({
				"offre": _derniere_offre,
				"reponse": json_code,
				"timestamp": int(Time.get_unix_time_from_system())
			})
			statut_change.emit("Réponse envoyée ! Connexion en cours...")


# ------------------------------------------------------------
# Signalisation en ligne automatique (REST API)
# ------------------------------------------------------------

func _get_signal_url() -> String:
	if OS.has_feature("web"):
		var origin: Variant = JavaScriptBridge.eval("window.location.origin")
		if origin is String and not origin.is_empty():
			return origin + "/api/signal"
	return "https://quete-anneau-coop.onrender.com/api/signal"

func _envoyer_signal(corps_data: Dictionary) -> void:
	var json_str := JSON.stringify(corps_data)
	if OS.has_feature("web"):
		var js := """
		(function() {
			try {
				var url = window.location.origin.includes('localhost') || window.location.origin.includes('onrender.com') 
					? (window.location.origin + '/api/signal')
					: 'https://quete-anneau-coop.onrender.com/api/signal';
				fetch(url, {
					method: 'POST',
					headers: { 'Content-Type': 'application/json' },
					body: %s
				}).catch(function(e) { console.error('Erreur POST signal:', e); });
			} catch(e) { console.error(e); }
		})();
		""" % [JSON.stringify(json_str)]
		JavaScriptBridge.eval(js)


func _verifier_signal() -> void:
	if OS.has_feature("web"):
		var js := """
		(function() {
			if (window.__signalFetchEnCours) return;
			window.__signalFetchEnCours = true;
			var url = window.location.origin.includes('localhost') || window.location.origin.includes('onrender.com') 
				? (window.location.origin + '/api/signal')
				: 'https://quete-anneau-coop.onrender.com/api/signal';
			fetch(url)
				.then(function(r) { return r.json(); })
				.then(function(d) {
					window.__signalFetchEnCours = false;
					if (d && d.data) {
						window.__signalDonnees = JSON.stringify(d.data);
					}
				})
				.catch(function(e) {
					window.__signalFetchEnCours = false;
				});
		})();
		"""
		JavaScriptBridge.eval(js)



func _lire_reponse_signal() -> void:
	var json_str: Variant = null
	if OS.has_feature("web"):
		json_str = JavaScriptBridge.eval("window.__signalDonnees ?? null")

	if json_str is String and not json_str.is_empty():
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__signalDonnees = null")
		var donnees: Variant = JSON.parse_string(json_str)
		if donnees is Dictionary:
			if est_hote:
				# L'hôte attend la réponse du Joueur 2
				var rep: String = donnees.get("reponse", "")
				if not rep.is_empty() and rep != _derniere_reponse:
					_derniere_reponse = rep
					_polling_actif = false
					statut_change.emit("Joueur 2 détecté ! Finalisation de la connexion...")
					appliquer_reponse(rep)
			else:
				# L'invité attend l'offre du Joueur 1
				var off: String = donnees.get("offre", "")
				if not off.is_empty() and off != _derniere_offre:
					_derniere_offre = off
					_polling_actif = false
					statut_change.emit("Partie trouvée ! Connexion au Joueur 1...")
					rejoindre_session(off)


## Le pair distant est connecté : la partie peut commencer.
func _sur_pair_connecte(_id_pair: int) -> void:
	connecte = true
	connexion_etablie.emit()


func _sur_pair_deconnecte(_id_pair: int) -> void:
	connecte = false
	deconnexion.emit()


# ============================================================
# MODE AUTO-TEST (?autotest=1 dans l'URL)
# Crée DEUX connexions WebRTC dans la même page (boucle locale,
# comme le démo officiel Godot) et vérifie tout le pipeline :
# offre/réponse, candidats ICE, poll, canal de données, messages.
# Le résultat s'affiche à l'écran ET dans window.__testWebRTC.
# Ouvre : https://ton-site/index.html?autotest=1
# ============================================================

var _test_actif := false
var _test_phase := 0
var _test_chrono := 0.0
var _test_a: WebRTCPeerConnection
var _test_b: WebRTCPeerConnection
var _test_canal_a: WebRTCDataChannel
var _test_canal_b: WebRTCDataChannel
var _cand_a: Array = []
var _cand_b: Array = []
var _ping_envoye := false
var _label_test: Label


func _ready() -> void:
	# Sur le Web : lance l'auto-test si l'URL contient ?autotest=1
	if OS.has_feature("web"):
		var param: Variant = JavaScriptBridge.eval("new URLSearchParams(location.search).get('autotest')")
		if param == "1":
			demarrer_auto_test()


## Démarre le test en boucle locale (deux pairs dans la même page).
func demarrer_auto_test() -> void:
	_test_actif = true
	_maj_label_test("Test WebRTC : initialisation des deux pairs…")
	_test_a = WebRTCPeerConnection.new()
	_test_b = WebRTCPeerConnection.new()
	_test_a.initialize({"iceServers": SERVEURS_ICE})
	_test_b.initialize({"iceServers": SERVEURS_ICE})
	_test_a.ice_candidate_created.connect(
		func(m, i, n): _cand_a.append({"m": m, "i": i, "n": n}))
	_test_b.ice_candidate_created.connect(
		func(m, i, n): _cand_b.append({"m": m, "i": i, "n": n}))
	_test_b.data_channel_received.connect(_test_sur_canal_b)
	_test_canal_a = _test_a.create_data_channel("test")
	_test_a.create_offer()


## B reçoit le canal de données ouvert par A.
func _test_sur_canal_b(canal: WebRTCDataChannel) -> void:
	_test_canal_b = canal


## Machine à états du test, appelée à chaque frame (avec poll).
func _boucle_auto_test(delta: float) -> void:
	_test_chrono += delta
	_test_a.poll()
	_test_b.poll()

	# Vérification du canal de données une fois la connexion établie.
	if _test_canal_b != null \
			and _test_canal_b.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
		if not _ping_envoye:
			_ping_envoye = true
			_test_canal_a.put_packet("ping".to_utf8_buffer())
			_maj_label_test("Canal OUVERT — ping envoyé, attente du retour…")
		while _test_canal_b.get_available_packet_count() > 0:
			var msg: String = _test_canal_b.get_packet().get_string_from_utf8()
			if msg == "ping":
				_test_canal_b.put_packet("pong".to_utf8_buffer())
				_maj_label_test("Ping reçu par le pair B — pong renvoyé…")
			elif msg == "pong":
				_reussite_auto_test()
				return

	match _test_phase:
		0:  # Attendre l'offre de A (description + candidats complets).
			_maj_label_test("Phase 0/3 — récolte de l'offre A… (candidats : %d)" % _cand_a.size())
			if _test_a.get_local_description() != "" \
					and _test_a.get_gathering_state() == WebRTCPeerConnection.GATHERING_STATE_COMPLETE:
				_test_b.set_remote_description("offer", _test_a.get_local_description())
				for c in _cand_a:
					_test_b.add_ice_candidate(c["m"], c["i"], c["n"])
				_test_b.create_offer()  # génère la réponse
				_test_phase = 1
		1:  # Attendre la réponse de B, puis l'appliquer à A.
			_maj_label_test("Phase 1/3 — récolte de la réponse B… (candidats : %d)" % _cand_b.size())
			if _test_b.get_local_description() != "" \
					and _test_b.get_gathering_state() == WebRTCPeerConnection.GATHERING_STATE_COMPLETE:
				_test_a.set_remote_description("answer", _test_b.get_local_description())
				for c in _cand_b:
					_test_a.add_ice_candidate(c["m"], c["i"], c["n"])
				_test_phase = 2
		2:  # Attendre l'ouverture du canal de données.
			var etat := "inconnu"
			if _test_canal_a != null:
				etat = ["connecting", "open", "closing", "closed"][
					_test_canal_a.get_ready_state()]
			_maj_label_test("Phase 2/3 — connexion ICE en cours… (canal : %s, %.1fs)" % [etat, _test_chrono])

	if _test_chrono > 25.0:
		_echec_auto_test()


func _reussite_auto_test() -> void:
	_test_actif = false
	_maj_label_test("✅ SUCCÈS : WebRTC completement fonctionnel sur ce navigateur !")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__testWebRTC='OK'")


func _echec_auto_test() -> void:
	_test_actif = false
	_maj_label_test("❌ ÉCHEC au bout de 25 s — bloqué en phase %d. Copie ce message pour le diagnostic." % _test_phase)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__testWebRTC='ECHEC phase '+%d" % _test_phase)


## Affiche une ligne de statut du test par-dessus tout le reste.
func _maj_label_test(texte: String) -> void:
	if _label_test == null:
		var calque := CanvasLayer.new()
		calque.layer = 100  # au-dessus de toutes les interfaces
		get_tree().root.add_child(calque)
		var fond := ColorRect.new()
		fond.color = Color(0, 0, 0, 0.75)
		fond.set_anchors_preset(Control.PRESET_TOP_WIDE)
		fond.offset_bottom = 110.0
		fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		calque.add_child(fond)
		_label_test = Label.new()
		_label_test.set_anchors_preset(Control.PRESET_TOP_WIDE)
		_label_test.offset_left = 20.0
		_label_test.offset_top = 12.0
		_label_test.offset_right = -20.0
		_label_test.offset_bottom = 100.0
		_label_test.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label_test.add_theme_font_size_override("font_size", 24)
		_label_test.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		calque.add_child(_label_test)
	_label_test.text = "🧪 " + texte
