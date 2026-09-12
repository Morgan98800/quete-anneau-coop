extends CharacterBody2D
## ============================================================
## Guide.gd — Le Guide.
## ============================================================

const VITESSE: float = 220.0
const DELAI_SYNC: float = 0.05
const PUISSANCE_SOIN: float = 12.0

var _chrono_sync: float = 0.0

@onready var _visuel: Node2D = $Visuel
@onready var _halo_cristal: Polygon2D = $Visuel/Baton/HaloCristal
@onready var _onde_soin: Polygon2D = $OndeSoin
@onready var _sprite_gba: Sprite2D = $Visuel/SpriteGBA

var _chrono_anim: float = 0.0
var _direction_row: int = 0 # 0=Down, 1=Left, 2=Right, 3=Up
var _pas_timer: float = 0.0
var _chrono_soin_auto: float = 0.0

func _ready() -> void:
	# L'invité (joueur 2) contrôle le Guide en multi.
	set_multiplayer_authority(2)
	_onde_soin.hide()

func _physics_process(delta: float) -> void:
	_animer_sprite(delta)

	if NetworkManager.mode_solo:
		_process_compagnon_solo(delta)
		return

	if not is_multiplayer_authority() or not NetworkManager.connecte:
		return

	var dir := JoystickVirtuel.direction
	if dir == Vector2.ZERO:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * VITESSE
	move_and_slide()

	_chrono_sync += delta
	if _chrono_sync >= DELAI_SYNC:
		_chrono_sync = 0.0
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

	# Sam soigne automatiquement si la corruption devient critique
	_chrono_soin_auto += delta
	if _chrono_soin_auto >= 4.0:
		_chrono_soin_auto = 0.0
		if Corruption.taux > 45.0:
			Corruption.diminuer(PUISSANCE_SOIN)
			_declencher_effet_soin()

func _animer_sprite(delta: float) -> void:
	_chrono_anim += delta * 6.0
	# Pulsation du cristal magique
	var pulsation := 1.0 + 0.3 * sin(_chrono_anim * 0.9)
	if _halo_cristal:
		_halo_cristal.scale = Vector2(pulsation, pulsation)

	# Direction et animation de pas GBA
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

func interagir() -> void:
	if not NetworkManager.mode_solo and (not is_multiplayer_authority() or not NetworkManager.connecte):
		return
	Corruption.diminuer(PUISSANCE_SOIN)
	_declencher_effet_soin()
	if not NetworkManager.mode_solo:
		_appliquer_soin.rpc(PUISSANCE_SOIN)

func _declencher_effet_soin() -> void:
	SonChiptune.jouer_soin()
	_onde_soin.show()
	_onde_soin.scale = Vector2(0.2, 0.2)
	_onde_soin.modulate.a = 0.8
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_onde_soin, "scale", Vector2(1.8, 1.8), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_onde_soin, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(func(): _onde_soin.hide())

	# Repousser les spectres proches
	for node in get_tree().get_nodes_in_group("spectres"):
		if node is CharacterBody2D and global_position.distance_to(node.global_position) < 220.0:
			if node.has_method("repousser"):
				node.repousser()

@rpc("any_peer", "call_remote", "reliable")
func _appliquer_soin(montant: float) -> void:
	Corruption.diminuer(montant)
	_declencher_effet_soin()

@rpc("authority", "call_remote", "unreliable")
func _synchroniser(position_distante: Vector2, velocite_distante: Vector2) -> void:
	global_position = position_distante
	velocity = velocite_distante
