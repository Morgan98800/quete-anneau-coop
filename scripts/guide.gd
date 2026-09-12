extends CharacterBody2D
## ============================================================
## Guide.gd — Compagnon de l'Anneau (Sam / Aragorn / Gandalf).
## S'adapte à chaque acte et offre des compétences uniques.
## ============================================================

const VITESSE: float = 220.0
const DELAI_SYNC: float = 0.05
const PUISSANCE_SOIN: float = 12.0

var controle_actif: bool = false # Actif si le joueur le contrôle directement
var role_actuel: String = "sam" # "sam", "aragorn", "gandalf"

var _chrono_sync: float = 0.0
var _recul: Vector2 = Vector2.ZERO
var _en_attaque: bool = false
var _chrono_attaque: float = 0.0

@onready var _visuel: Node2D = $Visuel
@onready var _halo_cristal: Polygon2D = $Visuel/Baton/HaloCristal
@onready var _onde_soin: Polygon2D = $OndeSoin
@onready var _sprite_gba: Sprite2D = $Visuel/SpriteGBA
@onready var _etiquette_nom: Label = $EtiquetteNom
@onready var _lumiere_fiole: PointLight2D = $Visuel/Baton/LumiereFiole

var _chrono_anim: float = 0.0
var _direction_row: int = 0
var _pas_timer: float = 0.0
var _chrono_soin_auto: float = 0.0

var _hurtbox: Hurtbox
var _hitbox: Hitbox
var _arc_epee: Polygon2D

func _ready() -> void:
	set_multiplayer_authority(2)
	_onde_soin.hide()
	_creer_composants_combat()
	configurer_heros_pour_acte(1)

func _creer_composants_combat() -> void:
	# Hurtbox du compagnon
	_hurtbox = Hurtbox.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.camp = "joueur"
	var col_hurt := CollisionShape2D.new()
	var shape_hurt := CircleShape2D.new()
	shape_hurt.radius = 15.0
	col_hurt.shape = shape_hurt
	_hurtbox.add_child(col_hurt)
	add_child(_hurtbox)
	_hurtbox.a_subi_degats.connect(_sur_degats)

	# Hitbox d'attaque (Épée / Torche / Bâton)
	_hitbox = Hitbox.new()
	_hitbox.name = "HitboxAttaque"
	_hitbox.camp = "joueur"
	_hitbox.degats = 1
	_hitbox.recul = 300.0
	var col_hit := CollisionShape2D.new()
	var shape_hit := CircleShape2D.new()
	shape_hit.radius = 28.0
	col_hit.shape = shape_hit
	_hitbox.add_child(col_hit)
	_hitbox.position = Vector2(0, 20)
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	add_child(_hitbox)

	# Visuel d'arc d'attaque
	_arc_epee = Polygon2D.new()
	_arc_epee.color = Color(1.0, 0.9, 0.4, 0.85)
	_arc_epee.polygon = PackedVector2Array([Vector2(-18, -6), Vector2(0, -22), Vector2(18, -6), Vector2(0, -12)])
	_arc_epee.visible = false
	add_child(_arc_epee)

func configurer_heros_pour_acte(numero_acte: int) -> void:
	match numero_acte:
		1, 4, 5:
			role_actuel = "sam"
			_etiquette_nom.text = "Sam Gamegie"
			_sprite_gba.texture = load("res://assets/sprites/personnages/sam_spritesheet.png")
			_lumiere_fiole.couleur = Color(0.62, 0.91, 0.94, 1.0)
			_lumiere_fiole.rayon = 150
			_arc_epee.color = Color(0.8, 1.0, 0.8, 0.85)
		2:
			role_actuel = "aragorn"
			_etiquette_nom.text = "Aragorn (Grand-Pas)"
			_sprite_gba.texture = load("res://assets/sprites/personnages/aragorn_spritesheet.png")
			_lumiere_fiole.couleur = Color(1.0, 0.6, 0.2, 1.0)
			_lumiere_fiole.rayon = 190
			_arc_epee.color = Color(1.0, 0.5, 0.1, 0.9)
		3:
			role_actuel = "gandalf"
			_etiquette_nom.text = "Gandalf le Gris"
			_sprite_gba.texture = load("res://assets/sprites/personnages/gandalf_spritesheet.png")
			_lumiere_fiole.couleur = Color(0.7, 0.9, 1.0, 1.0)
			_lumiere_fiole.rayon = 220
			_arc_epee.color = Color(0.5, 0.9, 1.0, 0.9)

func _physics_process(delta: float) -> void:
	_animer_sprite(delta)

	if _en_attaque:
		_chrono_attaque -= delta
		if _chrono_attaque <= 0.0:
			_en_attaque = false
			_hitbox.monitoring = false
			_hitbox.monitorable = false
			_arc_epee.visible = false

	if _recul.length() > 5.0:
		velocity = _recul
		_recul = _recul.move_toward(Vector2.ZERO, delta * 700.0)
		move_and_slide()
		return

	# Mode Solo : si non contrôlé, comportement de compagnon suiveur
	if NetworkManager.mode_solo and not controle_actif:
		_process_compagnon_solo(delta)
		return

	# En multi ou si le joueur contrôle directement le Guide
	if not NetworkManager.mode_solo and (not is_multiplayer_authority() or not NetworkManager.connecte):
		return

	var dir := JoystickVirtuel.direction
	if dir == Vector2.ZERO:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * VITESSE
	move_and_slide()

	# Pousser les caisses de donjon
	for i in range(get_slide_collision_count()):
		var coll := get_slide_collision(i)
		var collider := coll.get_collider()
		if collider is CaissePoussable:
			collider.pousser(-coll.get_normal())

	_chrono_sync += delta
	if _chrono_sync >= DELAI_SYNC:
		_chrono_sync = 0.0
		if not NetworkManager.mode_solo:
			_synchroniser.rpc(global_position, velocity)

func _process_compagnon_solo(delta: float) -> void:
	var porteur := get_node_or_null("../Porteur")
	if not porteur:
		return
	var cible: Vector2 = porteur.global_position + Vector2(-35, 20)
	var dist := global_position.distance_to(cible)
	if dist > 45.0:
		var dir := (cible - global_position).normalized()
		velocity = dir * (VITESSE * 0.95)
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	# Pousser les caisses aussi en suiveur
	for i in range(get_slide_collision_count()):
		var coll := get_slide_collision(i)
		var collider := coll.get_collider()
		if collider is CaissePoussable:
			collider.pousser(-coll.get_normal())

	# Soin automatique si corruption élevée
	_chrono_soin_auto += delta
	if _chrono_soin_auto >= 4.0:
		_chrono_soin_auto = 0.0
		if Corruption.taux > 50.0:
			Corruption.diminuer(PUISSANCE_SOIN)
			_declencher_effet_soin()

func attaquer() -> void:
	if _en_attaque:
		return
	_en_attaque = true
	_chrono_attaque = 0.22

	# Dégâts selon le héros
	if role_actuel == "aragorn":
		_hitbox.degats = 2
		SonChiptune.jouer_epee()
	elif role_actuel == "gandalf":
		_hitbox.degats = 2
		_hitbox.recul = 450.0
		SonChiptune.jouer_magie()
	else: # Sam
		_hitbox.degats = 1
		SonChiptune.jouer_impact()

	var offset := Vector2.ZERO
	var rot := 0.0
	match _direction_row:
		0: offset = Vector2(0, 24); rot = 0.0
		1: offset = Vector2(-24, 0); rot = PI / 2.0
		2: offset = Vector2(24, 0); rot = -PI / 2.0
		3: offset = Vector2(0, -24); rot = PI

	_hitbox.position = offset
	_hitbox.monitoring = true
	_hitbox.monitorable = true

	_arc_epee.position = offset
	_arc_epee.rotation = rot
	_arc_epee.visible = true

func interagir() -> void:
	if not NetworkManager.mode_solo and (not is_multiplayer_authority() or not NetworkManager.connecte):
		return

	if role_actuel == "aragorn":
		# Capacité Aragorn : Coup de torche enflammée repoussant tous les spectres
		SonChiptune.jouer_epee()
		attaquer()
	elif role_actuel == "gandalf":
		# Capacité Gandalf : Onde magique étourdissant tous les ennemis proches
		SonChiptune.jouer_magie()
		_repousser_ennemis_proches()
		_declencher_effet_soin()
	else:
		# Capacité Sam : Fiole de Galadriel (soigne + étourdit les araignées)
		Corruption.diminuer(PUISSANCE_SOIN)
		_declencher_effet_soin()
		_etourdir_araignees_proches()

	if not NetworkManager.mode_solo:
		_appliquer_soin.rpc(PUISSANCE_SOIN)

func _repousser_ennemis_proches() -> void:
	var ennemis := get_tree().get_nodes_in_group("ennemis")
	for e in ennemis:
		if e is Node2D and global_position.distance_to(e.global_position) < 220.0:
			var dir: Vector2 = (e.global_position - global_position).normalized()
			if e.has_method("_sur_degats"):
				e._sur_degats(2, dir * 400.0)

func _etourdir_araignees_proches() -> void:
	var monstres := get_tree().get_nodes_in_group("boss")
	for b in monstres:
		if b.has_method("etourdir") and global_position.distance_to(b.global_position) < 280.0:
			b.etourdir(3.0)

func _declencher_effet_soin() -> void:
	SonChiptune.jouer_soin()
	_onde_soin.show()
	_onde_soin.scale = Vector2(0.2, 0.2)
	_onde_soin.modulate.a = 0.8
	var tween := create_tween()
	tween.tween_property(_onde_soin, "scale", Vector2(1.5, 1.5), 0.35)
	tween.parallel().tween_property(_onde_soin, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func(): _onde_soin.hide())

func _sur_degats(montant: int, dir_recul: Vector2) -> void:
	_recul = dir_recul
	GestionnaireVie.subir_degats(montant)
	var tween := create_tween()
	tween.tween_property(_visuel, "modulate", Color(3.0, 0.4, 0.4, 1.0), 0.1)
	tween.tween_property(_visuel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _animer_sprite(delta: float) -> void:
	_chrono_anim += delta * 6.0
	var pulsation := 1.0 + 0.3 * sin(_chrono_anim * 0.9)
	if _halo_cristal:
		_halo_cristal.scale = Vector2(pulsation, pulsation)

	if velocity.length() > 10.0:
		if abs(velocity.x) > abs(velocity.y):
			_direction_row = 1 if velocity.x < 0 else 2
		else:
			_direction_row = 0 if velocity.y > 0 else 3
		_pas_timer += delta * 7.5
		var col := int(_pas_timer) % 4
		if _sprite_gba:
			_sprite_gba.frame = _direction_row * 4 + col
	else:
		_pas_timer = 0.0
		if _sprite_gba:
			_sprite_gba.frame = _direction_row * 4

@rpc("authority", "call_remote", "unreliable")
func _synchroniser(position_distante: Vector2, velocite_distante: Vector2) -> void:
	global_position = position_distante
	velocity = velocite_distante

@rpc("any_peer", "call_local", "reliable")
func _appliquer_soin(montant: float) -> void:
	Corruption.diminuer(montant)
	_declencher_effet_soin()
