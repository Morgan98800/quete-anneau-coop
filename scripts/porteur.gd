extends CharacterBody2D
## ============================================================
## Porteur.gd — Le Porteur de l'Anneau.
## ============================================================

const VITESSE: float = 220.0
const DELAI_SYNC: float = 0.05

var invisible: bool = false
var _chrono_sync: float = 0.0

@onready var _visuel: Node2D = $Visuel
@onready var _halo_anneau: Polygon2D = $Visuel/Anneau/HaloAnneau
@onready var _aura_spectrale: Polygon2D = $AuraSpectrale
@onready var _ombre: Polygon2D = $Ombre

@onready var _sprite_gba: Sprite2D = $Visuel/SpriteGBA

var _chrono_anim: float = 0.0
var _direction_row: int = 0 # 0=Down, 1=Left, 2=Right, 3=Up
var _pas_timer: float = 0.0

func _ready() -> void:
	# L'hôte (joueur 1) contrôle le Porteur.
	set_multiplayer_authority(1)
	_appliquer_apparence()

func _physics_process(delta: float) -> void:
	_animer_sprite(delta)
	
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
		if not NetworkManager.mode_solo:
			_synchroniser.rpc(global_position, invisible, velocity)


func _animer_sprite(delta: float) -> void:
	_chrono_anim += delta * 6.0
	# Pulsation douce de l'Anneau
	var pulsation := 1.0 + 0.25 * sin(_chrono_anim * 0.8)
	if _halo_anneau:
		_halo_anneau.scale = Vector2(pulsation, pulsation)
	
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

	# Pulsation de l'aura spectrale
	if invisible and _aura_spectrale:
		_aura_spectrale.scale = Vector2.ONE * (1.0 + 0.1 * sin(_chrono_anim * 1.5))

func basculer_invisibilite() -> void:
	if not is_multiplayer_authority() or not NetworkManager.connecte:
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
