extends Node
## ============================================================
## Corruption (AUTOLOAD)
## Jauge globale de corruption (0 → 100).
## - Monte tant que le Porteur reste invisible.
## - Redescend lentement quand il est visible.
## - Le Guide peut la faire baisser avec son pouvoir de soin.
##
## Le calcul est fait localement sur chaque téléphone, à partir
## de l'état "invisible" qui est synchronisé par RPC : les deux
## jauges restent donc identiques sans synchronisation réseau.
## ============================================================

signal corruption_changee(valeur: float)
signal corruption_max

const MAX := 100.0
const TAUX_MONTEE := 7.0    ## Points par seconde quand l'influence est active.
const TAUX_DESCENTE := 3.5  ## Points par seconde de repos.

var valeur := 0.0
var _influence_active := false  # vrai tant que le Porteur est invisible
var _max_atteint := false


func _process(delta: float) -> void:
	var avant := valeur
	if _influence_active:
		valeur = minf(MAX, valeur + TAUX_MONTEE * delta)
	else:
		valeur = maxf(0.0, valeur - TAUX_DESCENTE * delta)
	
	if valeur != avant:
		corruption_changee.emit(valeur)
	
	if valeur >= MAX and not _max_atteint:
		_max_atteint = true
		corruption_max.emit()


## Appelé quand l'état d'invisibilité du Porteur change (local + RPC).
func set_influence(active: bool) -> void:
	_influence_active = active


## Réduit la corruption (pouvoir du Guide).
func diminuer(montant: float) -> void:
	valeur = maxf(0.0, valeur - montant)
	if valeur < MAX:
		_max_atteint = false
	corruption_changee.emit(valeur)


## Réinitialise la corruption pour une nouvelle partie
func reinitialiser() -> void:
	valeur = 0.0
	_influence_active = false
	_max_atteint = false
	corruption_changee.emit(0.0)
