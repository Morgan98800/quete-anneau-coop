class_name JoystickVirtuel
extends Control

## NOTE : nommé "JoystickVirtuel" (et pas "VirtualJoystick") car Godot
## 4.6+ possède déjà une classe native appelée VirtualJoystick.

## Direction actuelle, lue par porteur.gd / guide.gd.
static var direction: Vector2 = Vector2.ZERO

const RAYON: float = 80.0
const ZONE_MORTE: float = 8.0

var _index_doigt: int = -1

@onready var _bouton: ColorRect = $Bouton

func _ready() -> void:
	_positionner_bouton(Vector2.ZERO)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed and _index_doigt == -1 and _contient(touch_event.position):
			_index_doigt = touch_event.index
			_mettre_a_jour(touch_event.position)
		elif not touch_event.pressed and touch_event.index == _index_doigt:
			_relacher()
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if drag_event.index == _index_doigt:
			_mettre_a_jour(drag_event.position)

func _relacher() -> void:
	_index_doigt = -1
	direction = Vector2.ZERO
	_positionner_bouton(Vector2.ZERO)

func _contient(position_ecran: Vector2) -> bool:
	var centre: Vector2 = global_position + size / 2.0
	# Zone tactile étendue pour faciliter la saisie sur smartphone
	return position_ecran.distance_to(centre) <= (RAYON + 30.0)

func _mettre_a_jour(position_ecran: Vector2) -> void:
	var centre: Vector2 = global_position + size / 2.0
	var vecteur: Vector2 = (position_ecran - centre).limit_length(RAYON)
	_positionner_bouton(vecteur)
	if vecteur.length() < ZONE_MORTE:
		direction = Vector2.ZERO
	else:
		direction = vecteur / RAYON

func _positionner_bouton(vecteur: Vector2) -> void:
	_bouton.position = size / 2.0 - _bouton.size / 2.0 + vecteur

