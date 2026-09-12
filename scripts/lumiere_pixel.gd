@tool
class_name LumierePixel
extends PointLight2D
## ============================================================
## LumierePixel
## Une PointLight2D dont la retombée est quantifiée en paliers
## nets et tramée au Bayer 4x4, au lieu du dégradé lisse par
## défaut.
##
## C'est LE détail qui fait la différence : un halo lisse sur des
## sprites 16 bits donne un rendu « Flash », alors qu'un halo en
## 4 paliers tramés ressemble aux jeux Super Nintendo de l'époque,
## qui simulaient les dégradés avec du tramage faute de couleurs.
##
## La texture est générée en mémoire au démarrage : aucun fichier
## image à commiter, et elle est mise en cache entre les lumières
## qui partagent le même rayon et le même nombre de paliers.
## ============================================================

## Teinte de la lumière. Prends-la dans Palette.
@export var couleur: Color = Color("ffe6a0"):
	set(v):
		couleur = v
		color = v

## Rayon en pixels du monde. La texture fait 2 x rayon de côté.
@export_range(8, 512, 1) var rayon: int = 96:
	set(v):
		if rayon == v:
			return  # evite de reconstruire a chaque frame
		rayon = v
		_reconstruire()

## Intensité de base, avant vacillement.
@export_range(0.0, 4.0, 0.05) var intensite: float = 1.0:
	set(v):
		intensite = v

## Nombre de paliers de la retombée. 3 ou 4 = très rétro.
## Au-delà de 6 on retrouve un dégradé lisse.
@export_range(2, 8, 1) var paliers: int = 4:
	set(v):
		if paliers == v:
			return
		paliers = v
		_reconstruire()

## 0 = lumière fixe. 0.2 à 0.4 = flamme. Au-delà, ça clignote.
@export_range(0.0, 1.0, 0.01) var vacillement: float = 0.0

## Vitesse du vacillement, en oscillations par seconde environ.
@export_range(0.1, 20.0, 0.1) var vitesse_vacillement: float = 6.0

## Matrice de Bragg... non, de Bayer 4x4. Ordre de dispersion
## classique du tramage ordonné.
const _BAYER: Array = [
	[0, 8, 2, 10],
	[12, 4, 14, 6],
	[3, 11, 1, 9],
	[15, 7, 13, 5],
]

## Largeur de la zone tramée entre deux paliers, en fraction de
## palier. 0 = frontières nettes (trop dur), 1 = tramage partout
## (grain uniforme). 0,55 est le bon compromis.
const LARGEUR_TRAME: float = 0.55

## Partagé entre toutes les lumières du jeu : une seule texture
## par couple (rayon, paliers).
static var _cache: Dictionary = {}

var _phase: float = 0.0
## Surintensite ponctuelle (soin, alerte). Retombe toute seule.
var _impulsion: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	blend_mode = Light2D.BLEND_MODE_ADD
	shadow_enabled = false  # coûteux en WebGL2 sur mobile
	color = couleur
	energy = intensite
	_reconstruire()
	# Décale la phase pour que deux torches côte à côte ne
	# vacillent pas à l'unisson.
	_phase = randf() * TAU


## L'énergie finale est TOUJOURS recalculée ici, jamais écrite
## directement de l'extérieur : sinon le vacillement écrasait la
## valeur posée par le script appelant à la frame suivante.
func _process(delta: float) -> void:
	var bruit := 0.0
	if vacillement > 0.0:
		_phase += delta * vitesse_vacillement
		# Trois sinus incommensurables : ça évite le battement
		# régulier qui trahit une animation scriptée.
		bruit = sin(_phase) * 0.6 \
			+ sin(_phase * 2.37) * 0.3 \
			+ sin(_phase * 5.11) * 0.1
	energy = intensite * (1.0 + bruit * vacillement) + _impulsion
	if _impulsion > 0.0:
		_impulsion = move_toward(_impulsion, 0.0, delta * 5.0)


## Flash lumineux ponctuel, par-dessus l'intensité de base.
func pulser(force: float = 2.0) -> void:
	_impulsion = maxf(_impulsion, force)


func _reconstruire() -> void:
	if not is_inside_tree():
		return
	var cle := "%d_%d" % [rayon, paliers]
	if not _cache.has(cle):
		_cache[cle] = _generer_texture(rayon, paliers)
	texture = _cache[cle]
	texture_scale = 1.0


## Construit un disque dont l'alpha descend par paliers tramés.
static func _generer_texture(r: int, nb_paliers: int) -> ImageTexture:
	var taille := r * 2
	var img := Image.create(taille, taille, false, Image.FORMAT_RGBA8)
	var centre := float(r)
	for y in taille:
		for x in taille:
			var d := Vector2(x + 0.5 - centre, y + 0.5 - centre).length() / centre
			# Retombée quadratique : plus proche du comportement
			# physique qu'une rampe linéaire, et plus lisible.
			var v := clampf(1.0 - d, 0.0, 1.0)
			v = v * v
			# Aplats francs + tramage UNIQUEMENT près de la
			# frontière entre deux paliers. Trames partout, on
			# obtient un grain uniforme ; trames seulement aux
			# bords, on retrouve les anneaux de couleur pleine
			# des jeux Super Nintendo.
			var echelle := v * nb_paliers
			var palier := floorf(echelle)
			var reste := echelle - palier
			var seuil := float(_BAYER[y % 4][x % 4]) / 16.0
			if reste > 1.0 - LARGEUR_TRAME:
				var t := (reste - (1.0 - LARGEUR_TRAME)) / LARGEUR_TRAME
				if seuil < t:
					palier += 1.0
			var a := clampf(palier / float(nb_paliers), 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)


## Fait monter ou descendre l'intensité en douceur. Utilisé quand
## le Porteur passe invisible : son anneau doit s'éteindre, pas
## disparaître d'un coup.
func fondre_vers(cible: float, duree: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(self, "intensite", cible, duree) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
