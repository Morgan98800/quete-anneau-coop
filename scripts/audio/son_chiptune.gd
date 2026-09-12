extends Node
## ============================================================
## SonChiptune.gd — Synthétiseur audio chiptune GBA 16-bit / 8-bit.
## Effets sonores rétro et musiques d'ambiance dynamiques (BGM)
## pour les 5 actes de la Quête de l'Anneau.
## ============================================================

const MIX_RATE: int = 22050

var _lecteurs_sfx: Array[AudioStreamPlayer] = []
var _index_lecteur: int = 0

var _lecteur_musique: AudioStreamPlayer
var _acte_musique_en_cours: int = 0
var _musiques_actes: Dictionary = {}

var _sons: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Lecteurs polyphoniques SFX
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_lecteurs_sfx.append(p)

	# Lecteur dédié pour la musique d'ambiance (BGM)
	_lecteur_musique = AudioStreamPlayer.new()
	_lecteur_musique.bus = "Master"
	_lecteur_musique.volume_db = -12.0
	add_child(_lecteur_musique)
	
	_initialiser_sons()

func _obtenir_lecteur() -> AudioStreamPlayer:
	var p := _lecteurs_sfx[_index_lecteur]
	_index_lecteur = (_index_lecteur + 1) % _lecteurs_sfx.size()
	return p

func _creer_wav(octets: PackedByteArray, en_boucle: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = octets
	if en_boucle:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = octets.size()
	return wav

func _initialiser_sons() -> void:
	_sons["bip"] = _synthetiser_onde_carree(480.0, 0.035, 0.5)
	_sons["clic"] = _synthetiser_glissando(900.0, 350.0, 0.045)
	_sons["anneau"] = _synthetiser_anneau(0.35)
	_sons["soin"] = _synthetiser_arpege([523.25, 659.25, 783.99, 1046.5], 0.35)
	_sons["alerte"] = _synthetiser_alerte(0.28)
	_sons["victoire"] = _synthetiser_arpege([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.7)
	_sons["defaite"] = _synthetiser_arpege([440.0, 415.3, 392.0, 329.6], 0.7)

# --- Effets Sonores (SFX) ---

func jouer_bip_dialogue(_pitch: float = 1.0) -> void:
	# Désactivé à la demande du joueur (silencieux pour les dialogues)
	pass

func jouer_clic() -> void:
	if not _sons.has("clic"):
		return
	var p := _obtenir_lecteur()
	p.stream = _sons["clic"]
	p.pitch_scale = 1.0
	p.volume_db = -6.0
	p.play()

func jouer_anneau() -> void:
	if not _sons.has("anneau"):
		return
	var p := _obtenir_lecteur()
	p.stream = _sons["anneau"]
	p.pitch_scale = 1.0
	p.volume_db = -4.0
	p.play()

func jouer_soin() -> void:
	if not _sons.has("soin"):
		return
	var p := _obtenir_lecteur()
	p.stream = _sons["soin"]
	p.pitch_scale = 1.0
	p.volume_db = -4.0
	p.play()

func jouer_alerte() -> void:
	if not _sons.has("alerte"):
		return
	var p := _obtenir_lecteur()
	p.stream = _sons["alerte"]
	p.pitch_scale = 1.0
	p.volume_db = -3.0
	p.play()

func jouer_victoire() -> void:
	arreter_musique()
	if not _sons.has("victoire"):
		return
	var p := _obtenir_lecteur()
	p.stream = _sons["victoire"]
	p.pitch_scale = 1.0
	p.volume_db = -2.0
	p.play()

func jouer_defaite() -> void:
	arreter_musique()
	if not _sons.has("defaite"):
		return
	var p := _obtenir_lecteur()
	p.stream = _sons["defaite"]
	p.pitch_scale = 1.0
	p.volume_db = -2.0
	p.play()

# --- Musiques d'Ambiance (BGM) pour les 5 Actes ---

func jouer_musique_acte(numero_acte: int) -> void:
	if _acte_musique_en_cours == numero_acte and _lecteur_musique.playing:
		return
	_acte_musique_en_cours = numero_acte

	if not _musiques_actes.has(numero_acte):
		_musiques_actes[numero_acte] = _generer_musique_pour_acte(numero_acte)

	var stream_musique: AudioStreamWAV = _musiques_actes[numero_acte]
	if not stream_musique:
		return

	# Transition fondu enchaîné doux
	if _lecteur_musique.playing:
		var tween := create_tween()
		tween.tween_property(_lecteur_musique, "volume_db", -35.0, 0.3)
		tween.tween_callback(func():
			_lecteur_musique.stream = stream_musique
			_lecteur_musique.play()
		)
		tween.tween_property(_lecteur_musique, "volume_db", -13.0, 0.4)
	else:
		_lecteur_musique.stream = stream_musique
		_lecteur_musique.volume_db = -13.0
		_lecteur_musique.play()

func arreter_musique() -> void:
	_acte_musique_en_cours = 0
	if _lecteur_musique.playing:
		var tween := create_tween()
		tween.tween_property(_lecteur_musique, "volume_db", -40.0, 0.4)
		tween.tween_callback(func(): _lecteur_musique.stop())

func _generer_musique_pour_acte(numero: int) -> AudioStreamWAV:
	match numero:
		1: return _creer_theme_comte()
		2: return _creer_theme_mont_venteux()
		3: return _creer_theme_moria()
		4: return _creer_theme_arachne()
		5: return _creer_theme_montagne_destin()
		_: return _creer_theme_comte()

# 🌿 ACTE 1 : Thème bucolique et chaleureux de la Comté (Concerning Hobbits)
func _creer_theme_comte() -> AudioStreamWAV:
	var duree: float = 9.5
	var melodie := [
		[0.0, 0.45, 293.66], [0.45, 0.45, 392.00], [0.9, 0.45, 440.00], [1.35, 0.9, 493.88],
		[2.25, 0.45, 587.33], [2.7, 0.45, 493.88], [3.15, 0.45, 440.00], [3.6, 1.4, 392.00],
		[5.1, 0.45, 329.63], [5.55, 0.45, 392.00], [6.0, 0.9, 440.00], [6.9, 0.45, 392.00],
		[7.35, 1.8, 392.00]
	]
	var basse := [
		[0.0, 0.9, 98.00], [0.9, 0.9, 146.83], [1.8, 0.9, 98.00], [2.7, 0.9, 146.83],
		[3.6, 0.9, 98.00], [4.5, 0.9, 130.81], [5.4, 0.9, 146.83], [6.3, 0.9, 98.00],
		[7.2, 1.8, 98.00]
	]
	return _synthetiser_boucle(duree, melodie, basse, 0.5, "onde_carree")

# 🌧️ ACTE 2 : Thème sombre et venteux d'Amon Sûl (Mont Venteux)
func _creer_theme_mont_venteux() -> AudioStreamWAV:
	var duree: float = 9.0
	var melodie := [
		[0.0, 0.8, 293.66], [0.8, 0.6, 349.23], [1.4, 1.0, 440.00], [2.4, 0.8, 392.00],
		[3.2, 0.8, 349.23], [4.0, 0.6, 329.63], [4.6, 1.2, 293.66], [5.8, 1.0, 277.18],
		[6.8, 1.8, 293.66]
	]
	var basse := [
		[0.0, 2.0, 73.42], [2.0, 2.0, 87.31], [4.0, 2.0, 73.42], [6.0, 2.6, 69.30]
	]
	return _synthetiser_boucle(duree, melodie, basse, 0.25, "onde_mystique")

# ⛏️ ACTE 3 : Tambours nains et gouffre de la Moria
func _creer_theme_moria() -> AudioStreamWAV:
	var duree: float = 8.5
	var melodie := [
		[0.0, 0.6, 130.81], [0.6, 0.6, 155.56], [1.2, 0.9, 196.00], [2.1, 0.6, 207.65],
		[2.7, 0.9, 196.00], [3.6, 0.6, 155.56], [4.2, 0.9, 146.83], [5.1, 1.8, 130.81],
		[7.0, 1.2, 130.81]
	]
	var basse := [
		[0.0, 0.5, 65.41], [0.8, 0.5, 65.41], [1.6, 0.5, 65.41], [2.4, 0.5, 77.78],
		[3.2, 0.5, 65.41], [4.0, 0.5, 65.41], [4.8, 0.5, 65.41], [5.6, 0.5, 58.27],
		[6.4, 1.8, 65.41]
	]
	return _synthetiser_boucle(duree, melodie, basse, 0.5, "percussif")

# 🕷️ ACTE 4 : Staccato angoissant de l'Antre d'Arachne
func _creer_theme_arachne() -> AudioStreamWAV:
	var duree: float = 7.5
	var melodie := [
		[0.0, 0.25, 329.63], [0.25, 0.25, 349.23], [0.5, 0.25, 329.63], [0.75, 0.25, 311.13],
		[1.0, 0.25, 329.63], [1.25, 0.25, 392.00], [1.5, 0.35, 369.99], [1.85, 0.5, 329.63],
		[2.5, 0.25, 329.63], [2.75, 0.25, 349.23], [3.0, 0.25, 329.63], [3.25, 0.25, 311.13],
		[3.5, 0.5, 293.66], [4.0, 0.6, 261.63], [4.6, 1.2, 246.94], [6.0, 1.2, 329.63]
	]
	var basse := [
		[0.0, 0.6, 82.41], [1.0, 0.6, 77.78], [2.0, 0.6, 82.41], [3.0, 0.6, 73.42],
		[4.0, 0.8, 65.41], [5.0, 1.8, 82.41]
	]
	return _synthetiser_boucle(duree, melodie, basse, 0.125, "onde_carree")

# 🌋 ACTE 5 : Marche apocalyptique du Mont du Destin (Thème héroïque & tragique)
func _creer_theme_montagne_destin() -> AudioStreamWAV:
	var duree: float = 8.8
	var melodie := [
		[0.0, 0.5, 293.66], [0.5, 0.5, 349.23], [1.0, 0.8, 440.00], [1.8, 1.0, 587.33],
		[2.8, 0.5, 523.25], [3.3, 0.5, 466.16], [3.8, 0.9, 440.00], [4.7, 0.5, 392.00],
		[5.2, 1.2, 440.00], [6.6, 1.8, 293.66]
	]
	var basse := [
		[0.0, 0.4, 73.42], [0.4, 0.4, 73.42], [0.8, 0.4, 73.42], [1.2, 0.4, 73.42],
		[1.6, 0.4, 73.42], [2.0, 0.4, 73.42], [2.4, 0.4, 58.27], [2.8, 0.4, 58.27],
		[3.2, 0.4, 65.41], [3.6, 0.4, 65.41], [4.0, 0.4, 73.42], [4.4, 0.4, 73.42],
		[4.8, 0.4, 73.42], [5.2, 0.4, 73.42], [5.6, 1.8, 73.42]
	]
	return _synthetiser_boucle(duree, melodie, basse, 0.5, "percussif")

# --- Moteur de Synthèse Musicale Rétro Haute Performance ---

func _synthetiser_boucle(duree: float, melodie: Array, basse: Array, duty: float, type_onde: String) -> AudioStreamWAV:
	var nb_samples: int = int(duree * MIX_RATE)
	var buffer := PackedFloat32Array()
	buffer.resize(nb_samples)
	buffer.fill(0.0)

	# 1. Rendu de la mélodie (Lead)
	for n in melodie:
		var start: float = float(n[0])
		var dur: float = float(n[1])
		var freq: float = float(n[2])
		var i_start: int = int(start * MIX_RATE)
		var i_end: int = mini(int((start + dur) * MIX_RATE), nb_samples)
		var periode: float = float(MIX_RATE) / freq

		for i in range(i_start, i_end):
			var local_i: int = i - i_start
			var t_note: float = float(local_i) / float(i_end - i_start)
			var env: float = (1.0 - t_note * 0.4) if (local_i > 150) else (float(local_i) / 150.0)
			var phase: float = fmod(float(local_i), periode) / periode
			var s: float = 0.0
			if type_onde == "onde_mystique":
				s = sin(phase * 2.0 * PI) * 38.0
			else:
				s = (36.0 if (phase < duty) else -36.0)
			buffer[i] += s * env

	# 2. Rendu de la ligne de basse
	for b in basse:
		var start_b: float = float(b[0])
		var dur_b: float = float(b[1])
		var freq_b: float = float(b[2])
		var i_start_b: int = int(start_b * MIX_RATE)
		var i_end_b: int = mini(int((start_b + dur_b) * MIX_RATE), nb_samples)
		var periode_b: float = float(MIX_RATE) / freq_b

		for i in range(i_start_b, i_end_b):
			var local_i_b: int = i - i_start_b
			var phase_b: float = fmod(float(local_i_b), periode_b) / periode_b
			# Onde triangle douce pour la basse
			var tri: float = abs(phase_b * 2.0 - 1.0) * 2.0 - 1.0
			buffer[i] += tri * 28.0

	# 3. Conversion en 8-bit non signé
	var octets := PackedByteArray()
	octets.resize(nb_samples)
	for i in range(nb_samples):
		octets[i] = int(clampf(128.0 + buffer[i], 0.0, 255.0))

	return _creer_wav(octets, true)

# --- Moteurs de synthèse SFX de base ---

func _synthetiser_onde_carree(freq: float, duree: float, rapport_cyclique: float = 0.5) -> AudioStreamWAV:
	var nb_echantillons := int(duree * MIX_RATE)
	var octets := PackedByteArray()
	octets.resize(nb_echantillons)
	var periode := float(MIX_RATE) / freq

	for i in range(nb_echantillons):
		var phase := fmod(float(i), periode) / periode
		var ampl: float = 1.0 - float(i) / float(nb_echantillons)
		var v := 60.0 * ampl if (phase < rapport_cyclique) else -60.0 * ampl
		octets[i] = int(clampf(128.0 + v, 0.0, 255.0))

	return _creer_wav(octets)

func _synthetiser_glissando(freq_debut: float, freq_fin: float, duree: float) -> AudioStreamWAV:
	var nb_echantillons := int(duree * MIX_RATE)
	var octets := PackedByteArray()
	octets.resize(nb_echantillons)
	var phase: float = 0.0

	for i in range(nb_echantillons):
		var t: float = float(i) / float(nb_echantillons)
		var freq: float = lerpf(freq_debut, freq_fin, t)
		phase += (freq / float(MIX_RATE))
		var ampl: float = 1.0 - t
		var s: float = 55.0 * ampl if (fmod(phase, 1.0) < 0.5) else -55.0 * ampl
		octets[i] = int(clampf(128.0 + s, 0.0, 255.0))

	return _creer_wav(octets)

func _synthetiser_anneau(duree: float) -> AudioStreamWAV:
	var nb_echantillons: int = int(duree * MIX_RATE)
	var octets := PackedByteArray()
	octets.resize(nb_echantillons)

	for i in range(nb_echantillons):
		var t: float = float(i) / float(MIX_RATE)
		var t_norm: float = float(i) / float(nb_echantillons)
		var s1: float = sin(2.0 * PI * 220.0 * t)
		var s2: float = sin(2.0 * PI * 223.5 * t)
		var env: float = sin(t_norm * PI)
		var val: float = (s1 + s2) * 0.5 * env * 65.0
		octets[i] = int(clampf(128.0 + val, 0.0, 255.0))

	return _creer_wav(octets)

func _synthetiser_arpege(notes: Array, duree_totale: float) -> AudioStreamWAV:
	var nb_echantillons: int = int(duree_totale * MIX_RATE)
	var octets := PackedByteArray()
	octets.resize(nb_echantillons)
	var echantillons_par_note: int = nb_echantillons / notes.size()

	for note_idx in range(notes.size()):
		var freq: float = float(notes[note_idx])
		var debut: int = note_idx * echantillons_par_note
		var fin: int = mini(debut + echantillons_par_note, nb_echantillons)
		var periode: float = float(MIX_RATE) / freq

		for i in range(debut, fin):
			var local_i: int = i - debut
			var t: float = float(local_i) / float(echantillons_par_note)
			var phase: float = fmod(float(i), periode) / periode
			var s: float = 50.0 * (1.0 - t * 0.5) if (phase < 0.35) else -50.0 * (1.0 - t * 0.5)
			octets[i] = int(clampf(128.0 + s, 0.0, 255.0))

	return _creer_wav(octets)

func _synthetiser_alerte(duree: float) -> AudioStreamWAV:
	var nb_echantillons: int = int(duree * MIX_RATE)
	var octets := PackedByteArray()
	octets.resize(nb_echantillons)

	for i in range(nb_echantillons):
		var t: float = float(i) / float(nb_echantillons)
		var freq: float = 750.0 if (fmod(t * 8.0, 1.0) < 0.5) else 950.0
		var phase: float = fmod(float(i) * (freq / float(MIX_RATE)), 1.0)
		var val: float = 60.0 * (1.0 - t * 0.4) if (phase < 0.5) else -60.0 * (1.0 - t * 0.4)
		octets[i] = int(clampf(128.0 + val, 0.0, 255.0))

	return _creer_wav(octets)
