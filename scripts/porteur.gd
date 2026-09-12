extends CharacterBody2D
## ============================================================
## Porteur.gd — Le Porteur de l'Anneau (Frodon).
## ============================================================

const VITESSE: float = 220.0
const DELAI_SYNC: float = 0.05

var invisible: bool = false
var controle_actif: bool = true # Contrôlé directement ou PNJ suiveur
var _chrono_sync: float = 0.0
var _recul: Vector2 = Vector2.ZERO
var _en_attaque: bool = false
var _chrono_attaque: float = 0.0

@onready var _visuel: Node2D = $Visuel
@onready var _halo_anneau: Polygon2D = $Visuel/Anneau/HaloAnneau
@onready var _aura_spectrale: Polygon2D = $AuraSpectrale
@onready var _ombre: Polygon2D = $Ombre
@onready var _sprite_gba: Sprite2D = $Visuel/SpriteGBA

var _chrono_anim: float = 0.0
var _direction_row: int = 0 # 0=Down, 1=Left, 2=Right, 3=Up
var _pas_timer: float = 0.0

# Composants de combat créés dynamiquement
var _hurtbox: Hurtbox
var _hitbox: Hitbox
var _arc_epee: Polygon2D

func _ready() -> void:
	set_multiplayer_authority(1)
	_creer_composants_combat()
	_appliquer_apparence()

func _creer_composants_combat() -> void:
	# Hurtbox du joueur
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

	# Hitbox d'attaque (Dard / fronde)
	_hitbox = Hitbox.new()
	_hitbox.name = "HitboxAttaque"
	_hitbox.camp = "joueur"
	_hitbox.degats = 1
	_hitbox.recul = 280.0
	var col_hit := CollisionShape2D.new()
	var shape_hit := CircleShape2D.new()
	shape_hit.radius = 24.0
	col_hit.shape = shape_hit
	_hitbox.add_child(col_hit)
	_hitbox.position = Vector2(0, 18)
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	add_child(_hitbox)

	# Visuel d'arc d'attaque
	_arc_epee = Polygon2D.new()
	_arc_epee.color = Color(0.8, 0.95, 1.0, 0.8)
	_arc_epee.polygon = PackedVector2Array([Vector2(-16, -6), Vector2(0, -18), Vector2(16, -6), Vector2(0, -10)])
	_arc_epee.visible = false
	add_child(_arc_epee)

func _physics_process(delta: float) -> void:
	_animer_sprite(delta)

	if _en_attaque:
		_chrono_attaque -= delta
		if _chrono_attaque <= 0.0:
			_en_attaque = false
			_hitbox.monitoring = false
			_hitbox.monitorable = false
			_arc_epee.visible = false

	# Application du recul de dégât
	if _recul.length() > 5.0:
		velocity = _recul
		_recul = _recul.move_toward(Vector2.ZERO, delta * 700.0)
		move_and_slide()
		return

	# Si en solo et que le joueur contrôle le Guide, Frodon suit le Guide !
	if NetworkManager.mode_solo and not controle_actif:
		_process_suiveur_solo(delta)
		return

	if not is_multiplayer_authority() or not NetworkManager.connecte:
		return

	var dir := JoystickVirtuel.direction
	if dir == Vector2.ZERO:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * VITESSE
	move_and_slide()

	# Pousser les caisses de donjon en cas de collision
	for i in range(get_slide_collision_count()):
		var coll := get_slide_collision(i)
		var collider := coll.get_collider()
		if collider is CaissePoussable:
			collider.pousser(-coll.get_normal())

	_chrono_sync += delta
	if _chrono_sync >= DELAI_SYNC:
		_chrono_sync = 0.0
		if not NetworkManager.mode_solo:
			_synchroniser.rpc(global_position, invisible, velocity)

func _process_suiveur_solo(delta: float) -> void:
	var guide := get_node_or_null("../Guide")
	if not guide:
		return
	var cible: Vector2 = guide.global_position + Vector2(-30, 20)
	var dist := global_position.distance_to(cible)
	if dist > 45.0:
		var dir := (cible - global_position).normalized()
		velocity = dir * (VITESSE * 0.95)
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func attaquer() -> void:
	if _en_attaque:
		return
	_en_attaque = true
	_chrono_attaque = 0.2
	SonChiptune.jouer_epee()

	# Orienter la hitbox selon la direction regardée
	var offset := Vector2.ZERO
	var rot := 0.0
	match _direction_row:
		0: offset = Vector2(0, 22); rot = 0.0 # Bas
		1: offset = Vector2(-22, 0); rot = PI / 2.0 # Gauche
		2: offset = Vector2(22, 0); rot = -PI / 2.0 # Droite
		3: offset = Vector2(0, -22); rot = PI # Haut

	_hitbox.position = offset
	_hitbox.monitoring = true
	_hitbox.monitorable = true

	_arc_epee.position = offset
	_arc_epee.rotation = rot
	_arc_epee.visible = true

func _sur_degats(montant: int, dir_recul: Vector2) -> void:
	_recul = dir_recul
	GestionnaireVie.subir_degats(montant)
	# Clignotement rouge de blessure
	var tween := create_tween()
	tween.tween_property(_visuel, "modulate", Color(3.0, 0.4, 0.4, 1.0), 0.1)
	tween.tween_property(_visuel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _animer_sprite(delta: float) -> void:
	_chrono_anim += delta * 6.0
	var pulsation := 1.0 + 0.25 * sin(_chrono_anim * 0.8)
	if _halo_anneau:
		_halo_anneau.scale = Vector2(pulsation, pulsation)
	
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

	if invisible and _aura_spectrale:
		_aura_spectrale.scale = Vector2.ONE * (1.0 + 0.1 * sin(_chrono_anim * 1.5))

func basculer_invisibilite() -> void:
	if not NetworkManager.mode_solo and (not is_multiplayer_authority() or not NetworkManager.connecte):
		return
	invisible = not invisible
	SonChiptune.jouer_anneau()
	_appliquer_apparence()
	Corruption.set_influence(invisible)

func _appliquer_apparence() -> void:
	if _visuel:
		_visuel.modulate = Color(0.6, 0.9, 1.0, 0.35) if invisible else Color(1, 1, 1, 1)
	if _aura_spectrale:
		_aura_spectrale.visible = invisible
	if _ombre:
		_ombre.color.a = 0.1 if invisible else 0.3

@rpc("authority", "call_remote", "unreliable")
func _synchroniser(position_distante: Vector2, invisible_distant: bool, velocite_distante: Vector2) -> void:
	global_position = position_distante
	velocity = velocite_distante
	if invisible != invisible_distant:
		invisible = invisible_distant
		Corruption.set_influence(invisible_distant)
		_appliquer_apparence()
