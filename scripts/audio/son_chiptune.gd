extends Node
## ============================================================
## SonChiptune.gd — Synthétiseur audio chiptune GBA 16-bit / 8-bit.
## Génère des effets sonores rétro purs en mémoire sans dépendance externe.
## ============================================================

const MIX_RATE: int = 22050

var _lecteurs: Array[AudioStreamPlayer] = []
var _index_lecteur: int = 0

var _sons: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Créer un pool de lecteurs audio polyphoniques
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_lecteurs.append(p)
	
	_initialiser_sons()

func _obtenir_lecteur() -> AudioStreamPlayer:
	var p := _lecteurs[_index_lecteur]
	_index_lecteur = (_index_lecteur + 1) % _lecteurs.size()
	return p

func _creer_wav(octets: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = octets
	return wav

func _initialiser_sons() -> void:
	# 1. Bip dialogue standard (onde carrée courte 480Hz)
	_sons["bip"] = _synthetiser_onde_carree(480.0, 0.035, 0.5)
	
	# 2. Clic menu rétro (glissando rapide 900 -> 350 Hz)
	_sons["clic"] = _synthetiser_glissando(900.0, 350.0, 0.045)
	
	# 3. Anneau unique (onde sinusoïdale modulée mystique)
	_sons["anneau"] = _synthetiser_anneau(0.35)
	
	# 4. Fiole de Galadriel / Soin de Sam (arpège ascendant C5-E5-G5-C6)
	_sons["soin"] = _synthetiser_arpege([523.25, 659.25, 783.99, 1046.5], 0.35)
	
	# 5. Alerte Nazgûl (cri strident / deux bips d'alerte)
	_sons["alerte"] = _synthetiser_alerte(0.28)

	# 6. Fanfare de victoire
	_sons["victoire"] = _synthetiser_arpege([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.7)

	# 7. Son de défaite (mineur descendant)
	_sons["defaite"] = _synthetiser_arpege([440.0, 415.3, 392.0, 329.6], 0.7)

func jouer_bip_dialogue(pitch: float = 1.0) -> void:
	if not _sons.has("bip"):
		return
	var p := _obtenir_lecteur()
	p.stream = _sons["bip"]
	p.pitch_scale = clampf(pitch, 0.5, 2.0)
	p.volume_db = -8.0
	p.play()

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
	if not _sons.has("victoire"):
		return
	var p := _obtenir_lecteur()
	p.stream = _sons["victoire"]
	p.pitch_scale = 1.0
	p.volume_db = -2.0
	p.play()

func jouer_defaite() -> void:
	if not _sons.has("defaite"):
		return
	var p := _obtenir_lecteur()
	p.stream = _sons["defaite"]
	p.pitch_scale = 1.0
	p.volume_db = -2.0
	p.play()

# --- Moteurs de synthèse ---

func _synthetiser_onde_carree(freq: float, duree: float, rapport_cyclique: float = 0.5) -> AudioStreamWAV:
	var nb_echantillons := int(duree * MIX_RATE)
	var octets := PackedByteArray()
	octets.resize(nb_echantillons)
	var periode := float(MIX_RATE) / freq

	for i in range(nb_echantillons):
		var phase := fmod(float(i), periode) / periode
		var ampl := 1.0 - float(i) / float(nb_echantillons) # Enveloppe decay
		var v := 60.0 * ampl if (phase < rapport_cyclique) else -60.0 * ampl
		octets[i] = int(clamp(128.0 + v, 0.0, 255.0))

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
		# Deux ondes qui battent (modulation d'amplitude / phasing)
		var s1: float = sin(2.0 * PI * 220.0 * t)
		var s2: float = sin(2.0 * PI * 223.5 * t)
		var env: float = sin(t_norm * PI) # Fade in et fade out doux
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
