extends Node
## ============================================================
## Palette (AUTOLOAD)
## Palette limitée façon 16 bits (SNES / GBA), déclinée sur
## l'univers de Tolkien. Une trentaine de teintes, organisées
## par zone : chaque région du monde a ses 3-4 valeurs et rien
## d'autre. C'est la contrainte qui fait le rendu rétro, pas
## le nombre de détails.
##
## Usage : Palette.HERBE, Palette.LAVE_VIVE, etc.
## Règle : ne JAMAIS écrire une couleur en dur ailleurs.
## ============================================================

# --- Ambiance nocturne (teintes du CanvasModulate) -----------
const NUIT_PROFONDE := Color("1a1c2c")
const OMBRE_FROIDE := Color("2b2b47")
const CREPUSCULE := Color("4a4670")
## Teinte globale appliquée au monde. Multiplie tout le canvas.
const AMBIANCE_NUIT := Color("5c5f96")
const AMBIANCE_JOUR := Color("b9b4d6")

# --- Comté / forêt ------------------------------------------
const FEUILLE_NUIT := Color("1b3a2a")
const MOUSSE := Color("2f5d3a")
const HERBE := Color("4c8b4f")
const HERBE_CLAIRE := Color("7fbf6a")
const ECORCE := Color("4a3323")
const ECORCE_CLAIRE := Color("6b4a30")

# --- Marais des Morts ---------------------------------------
const BOUE := Color("2b3327")
const VASE := Color("4d5c3a")
const BRUME := Color("8a9a7e")

# --- Mordor / Montagne du Destin ----------------------------
const ROCHE_NOIRE := Color("241c1c")
const ROCHE := Color("3f2e2a")
const CENDRE := Color("5a4a44")
const BRAISE := Color("8c3a1e")
const LAVE := Color("e05c1f")
const LAVE_VIVE := Color("ffa938")

# --- L'Anneau -----------------------------------------------
const OR_SOMBRE := Color("8a6320")
const OR := Color("d9a441")
const OR_VIF := Color("ffe6a0")

# --- Le Guide / cristal -------------------------------------
const CRISTAL_SOMBRE := Color("1f5a63")
const CRISTAL := Color("3fa9b8")
const CRISTAL_VIF := Color("9fe8f0")

# --- Spectres / Nazgûls -------------------------------------
const SPECTRE_NOIR := Color("14121c")
const SPECTRE_GRIS := Color("3a3547")
const OEIL_ROUGE := Color("d92b2b")

# --- Personnages --------------------------------------------
const PEAU_OMBRE := Color("a06a4a")
const PEAU := Color("e0a878")
const TISSU_BRUN := Color("5c4433")
const TISSU_VERT := Color("3d5c3a")

# --- Feu de camp --------------------------------------------
const FEU := Color("ff7b28")
const FEU_COEUR := Color("ffd86b")

# --- Interface ----------------------------------------------
const PARCHEMIN := Color("e8d9a8")
const ENCRE := Color("2a2018")


## Assombrit une couleur en restant dans la palette : au lieu de
## baisser la luminosité linéairement (ce qui délave et donne un
## rendu « 3D »), on tire vers l'ombre froide commune. C'est ce
## que faisaient les artistes 16 bits avec une rampe de palette.
func vers_ombre(couleur: Color, quantite: float) -> Color:
	return couleur.lerp(OMBRE_FROIDE, clampf(quantite, 0.0, 1.0))


## Éclaircit vers la lumière chaude plutôt que vers le blanc.
func vers_lumiere(couleur: Color, quantite: float) -> Color:
	return couleur.lerp(OR_VIF, clampf(quantite, 0.0, 1.0))


## Quantifie une couleur sur N niveaux par canal. Utile pour
## forcer un dégradé calculé à retomber dans un rendu par paliers.
func quantifier(couleur: Color, niveaux: int) -> Color:
	var n := float(maxi(niveaux, 2) - 1)
	return Color(
		roundf(couleur.r * n) / n,
		roundf(couleur.g * n) / n,
		roundf(couleur.b * n) / n,
		couleur.a
	)
