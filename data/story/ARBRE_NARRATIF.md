# 🌳 Arbre Narratif & Guide des Choix — Quête de l'Anneau

Ce fichier Markdown est le document de référence pour tous les dialogues, embranchements, embranchements moraux et conditions de fin du jeu.
Vous pouvez le consulter et le modifier directement : les données JSON du jeu (`data/dialogues/*.json`) sont calquées 1-pour-1 sur cette structure.

---

## 🧭 Structure Globale des 5 Actes

| Acte | Lieu Principal | Objectif Clé | Choix Majeur 🧭 | Impact Gameplay |
| :--- | :--- | :--- | :--- | :--- |
| **Acte 1** | La Comté (Cul-de-Sac -> Châteaubouc) | Fuir le Cavalier Noir | Raccourci Forêt vs Route Marchande | Vitesse vs Furtivité / +Herbes de soin |
| **Acte 2** | Auberge de Bree & Mont Venteux | Retrouver l'allié & survivre | Faire confiance à Grand-Pas vs Fuir seuls | Bonus de défense vs Embuscade rude |
| **Acte 3** | Les Mines de la Moria | Franchir Khazad-dûm | Résoudre l'énigme vs Forcer la grille | Moins de gobelins vs Éveil précoce du Balrog |
| **Acte 4** | L'Antre de Shelob (Cirith Ungol) | Échapper au piège | Épargner Gollum vs L'abandonner | Déverrouille la Fin C (Gollum) vs Fin A/B |
| **Acte 5** | Cratère du Destin (Mordor) | Détruire l'Anneau | Choix final de Frodon & Réaction de Sam | Détermine l'une des 3 Fins |

---

## 📜 Détail des Dialogues & Arbres par Acte

### 🌿 Acte 1 : L'Ombre sur la Comté

#### Scène 1.1 : L'Ordre de Gandalf (Départ de Cul-de-Sac)
- **Déclencheur** : Début de la partie, devant la maison de Frodon.
- **Intervenants** : Gandalf, Frodon, Sam.
- **Dialogue** :
  1. *Gandalf* : « Frodon, l'Anneau de Bilbon n'est pas une simple babiole. C'est l'Anneau Unique de Sauron. Il doit quitter la Comté sans attendre ! »
  2. *Frodon* : « Mais Gandalf, où dois-je aller ? Je ne suis qu'un simple hobbit... »
  3. *Sam* : « M'sieur Frodon n'ira nulle part sans moi ! M. Gandalf m'a fait promettre de ne pas vous perdre de vue ! »
  4. *Gandalf* : « Prends garde, Frodon. Glisser l'Anneau à ton doigt te rendra invisible aux mortels, mais attirera le regard de l'Ennemi. »
- **Effet** : Frodon reçoit l'Anneau Unique. Sam reçoit la Poêle de combat et 2 Lembas.

#### Scène 1.2 : Le Premier Cavalier Noir & Le Choix de Route (🧭 CHOIX 1)
- **Déclencheur** : À l'orée de la Vieille Forêt, un grondement et un souffle glacial retentissent.
- **Présentation du Choix aux 2 joueurs** :
  - **Option A** : *« Coupons à travers la Vieille Forêt ! »*
    - *Conséquence* : Brume épaisse, obscurité (+10% corruption pour Frodon), mais évite le Cavalier et donne 3 herbes de soin.
  - **Option B** : *« Restons sur la grand-route marchande ! »*
    - *Conséquence* : Chemin plus rapide et dégagé, mais un Cavalier Noir patrouille (Frodon doit utiliser l'Anneau pour esquiver).

---

### 🍻 Acte 2 : L'Auberge de Bree & Le Mont Venteux

#### Scène 2.1 : L'Inconnu au Poney Fringant (🧭 CHOIX 2)
- **Déclencheur** : Entrée dans l'auberge de Bree. Un rôdeur encapuchonné (Grand-Pas) les observe au fond de la taverne.
- **Présentation du Choix** :
  - **Option A** : *« Allons lui parler et montrons-lui la lettre de Gandalf. »*
    - *Conséquence* : Grand-Pas rejoint le groupe pour le campement du Mont Venteux. Sam gagne +1 Torche protectrice.
  - **Option B** : *« Il a une sale mine, restons méfiants et fuyons par la porte arrière. »*
    - *Conséquence* : Les hobbits campent seuls au Mont Venteux. Le combat contre les Nazgûls est plus difficile.

#### Scène 2.2 : L'Embuscade du Roi-Sorcier
- **Déclencheur** : Au sommet des ruines du Mont Venteux en pleine tempête.
- **Événement** : Le Roi-Sorcier tente de poignarder Frodon. Sam doit utiliser la Torche pour repousser les spectres pendant 20 secondes.

---

### ⛏️ Acte 3 : La Nuit de la Moria

#### Scène 3.1 : Les Portes de Durin
- **Énigme** : *« Parlez, ami, et entrez. »*
- **Mini-jeu coop** : Sam trouve la rune sur la stèle, Frodon prononce *Mellon*.

#### Scène 3.2 : Le Balrog et le Pont de Khazad-dûm
- **Fuite chronométrée** : Sam et Frodon doivent courir ensemble (s'ils s'éloignent de plus de 150px, le Balrog rattrape le retardataire).

---

### 🕷️ Acte 4 : Le Piège de Cirith Ungol

#### Scène 4.1 : Le Dilemme de Gollum (🧭 CHOIX 3)
- **Déclencheur** : Gollum tente de voler l'Anneau pendant le sommeil de Frodon, Sam le plaque au sol.
- **Présentation du Choix** :
  - **Option A (La Pitié de Frodon)** : *« Épargne-le, Sam. Il a été jadis un hobbit comme nous. »*
    - *Conséquence* : Gollum s'enfuit dans l'ombre. Réduit la corruption de Frodon de 15%. Ouvre la fin C au cratère !
  - **Option B (La Méfiance de Sam)** : *« Ligotons-le et chassons-le à coups de bâton ! »*
    - *Conséquence* : Gollum ne réapparaîtra pas au volcan. La route est plus ardue.

#### Scène 4.2 : Le Combat de Shelob
- Frodon est paralysé dans une toile d'araignée géante.
- Sam brandit la Fiole de Galadriel (*Aiya Eärendil Elenion Ancalima !*) pour aveugler Shelob et libérer Frodon.

---

### 🌋 Acte 5 : La Fin de Toutes Choses (Montagne du Destin)

#### Scène 5.1 : Au bord de la Crevasse (🧭 CHOIX FINAL)
- La corruption de Frodon atteint son sommet. Les flammes du Mordor l'encerclent.
- **Frodon** : « L'Anneau est mien ! Je refuse de le détruire ! »

#### Les 3 Fins Possibles :
1. **Fin Canonique (A) — Le Saut Involontaire** :
   - *Condition* : Si Gollum a été épargné à l'acte 4.
   - *Événement* : Gollum bondit sur Frodon, arrache l'Anneau avec ses dents, et trébuche dans le magma en dansant de joie. La Terre du Milieu est sauvée !
2. **Fin Fraternelle (B) — Les Paroles de Sam** :
   - *Condition* : Si Gollum a été chassé, mais que la Corruption de Frodon est inférieure à 80%.
   - *Événement* : Sam rappelle à Frodon la Comté, les fraises et la rivière. Frodon brise l'emprise de Sauron et jette lui-même l'Anneau.
3. **Fin Tragique (C) — La Chute dans l'Ombre** :
   - *Condition* : Si la Corruption a atteint 100%.
   - *Événement* : Frodon succombe entièrement et passe l'Anneau. Les Nazgûls fondent sur lui. L'Anneau retourne à son maître.
