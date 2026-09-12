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

var _chrono_anim: float = 0.0

func _ready() -> void:
	# L'invité (joueur 2) contrôle le Guide.
	set_multiplayer_authority(2)
	_onde_soin.hide()

func _physics_process(delta: float) -> void:
	_animer_flottement(delta)

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
			_synchroniser.rpc(global_position, velocity)


func _animer_flottement(delta: float) -> void:
	_chrono_anim += delta * 6.0
	# Pulsation du cristal magique
	var pulsation := 1.0 + 0.3 * sin(_chrono_anim * 0.9)
	if _halo_cristal:
		_halo_cristal.scale = Vector2(pulsation, pulsation)

	# Animation de marche si en mouvement
	if velocity.length() > 10.0:
		_visuel.position.y = sin(_chrono_anim * 2.0) * 2.5
		_visuel.rotation = sin(_chrono_anim) * 0.07
		if velocity.x < -10.0:
			_visuel.scale.x = -1.0
		elif velocity.x > 10.0:
			_visuel.scale.x = 1.0
	else:
		_visuel.position.y = move_toward(_visuel.position.y, 0.0, delta * 10.0)
		_visuel.rotation = move_toward(_visuel.rotation, 0.0, delta * 5.0)

func interagir() -> void:
	if not is_multiplayer_authority() or not NetworkManager.connecte:
		return
	Corruption.diminuer(PUISSANCE_SOIN)
	_declencher_effet_soin()
	_appliquer_soin.rpc(PUISSANCE_SOIN)

func _declencher_effet_soin() -> void:
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
