extends Node
## ============================================================
## GestionnaireVie.gd — Gère les Cœurs de Vie et l'Inventaire GBA.
## ============================================================

signal vie_changee(actuelle: int, max_vie: int)
signal mort
signal inventaire_change(cles: int, lembas: int)

var vie_max: int = 6 # 3 Cœurs complets (1 cœur = 2 PV)
var vie_actuelle: int = 6
var cles: int = 0
var lembas: int = 1

func _ready() -> void:
	reinitialiser()

func reinitialiser() -> void:
	vie_max = 6
	vie_actuelle = 6
	cles = 0
	lembas = 1
	vie_changee.emit(vie_actuelle, vie_max)
	inventaire_change.emit(cles, lembas)

func subir_degats(montant: int) -> void:
	if vie_actuelle <= 0:
		return
	vie_actuelle = maxi(0, vie_actuelle - montant)
	SonChiptune.jouer_degat()
	vie_changee.emit(vie_actuelle, vie_max)
	if vie_actuelle == 0:
		mort.emit()

func soigner(montant: int) -> void:
	vie_actuelle = mini(vie_max, vie_actuelle + montant)
	SonChiptune.jouer_soin()
	vie_changee.emit(vie_actuelle, vie_max)

func ajouter_cle() -> void:
	cles += 1
	SonChiptune.jouer_coffre()
	inventaire_change.emit(cles, lembas)

func utiliser_cle() -> bool:
	if cles > 0:
		cles -= 1
		SonChiptune.jouer_porte()
		inventaire_change.emit(cles, lembas)
		return true
	return false

func ajouter_lembas() -> void:
	lembas += 1
	SonChiptune.jouer_coffre()
	inventaire_change.emit(cles, lembas)

func consommer_lembas() -> bool:
	if lembas > 0 and vie_actuelle < vie_max:
		lembas -= 1
		soigner(4) # Rend 2 cœurs
		inventaire_change.emit(cles, lembas)
		return true
	return false
