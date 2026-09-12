# 💍 Quête de l'Anneau — Coop (Web & Mobile)

Jeu coopératif multijoueur en temps réel jouable sur navigateur (PC & Smartphones iOS/Android) développé avec **Godot Engine 4** et synchronisé en **Peer-to-Peer WebRTC**.

---

## 🚀 Déploiement sur Render

Ce dépôt est configuré pour se déployer en **1 clic** sur **[Render.com](https://render.com)** (Service gratuit *Web Service*).

### Configuration Render :
- **Environment** : `Node`
- **Build Command** : `npm install`
- **Start Command** : `npm start`
- **Instance Type** : `Free` (0.1 CPU, 512 MB RAM)

Le serveur Node.js (`server.js`) injecte automatiquement les en-têtes de sécurité indispensables pour Godot Web (`COOP: same-origin` & `COEP: require-corp`) et sert le jeu assemblé dans `/build-web`.

---

## 🎮 Guide d'embarquement (Onboarding) pour les joueurs

1. **Lien de partie** : Partagez l'URL Render (ou Netlify) avec votre partenaire de jeu.
2. **Sur smartphone** : 
   - Tenez l'appareil **à l'horizontale (mode paysage)**.
   - Cliquez sur **`⛶ Activer le Plein Écran`** pour masquer les barres du navigateur.
3. **Connexion directe** :
   - **Joueur 1** clique sur **`🗡️ Joueur 1 : Porteur (Lancer la partie)`**.
   - **Joueur 2** clique sur **`🌿 Joueur 2 : Guide (Rejoindre la partie)`**.
   - Les deux joueurs se connectent automatiquement en P2P direct en quelques secondes sans aucun code à recopier.
4. **Contrôles** :
   - Déplacement : **Joystick virtuel tactile** à gauche ou touches fléchées / ZQSD sur PC.
   - Compétence spéciale : **Bouton d'action** en bas à droite (*Invisibilité* pour le Porteur, *Soin radiant* pour le Guide).

---

## 🛠️ Pour les développeurs & IA (Améliorations graphiques / 3D)

- **Scène principale** : `scenes/Main.tscn` (script `scripts/main.gd`)
- **Porteur** : `scenes/Porteur.tscn` (`scripts/porteur.gd`)
- **Guide** : `scenes/Guide.tscn` (`scripts/guide.gd`)
- **Ennemis (Spectres / Nazgûls)** : `scenes/Spectre.tscn` (`scripts/spectre.gd`)
- **Réseau P2P** : `scripts/network_manager.gd`
- **Compilation Web** :
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --export-release "Web" build-web/index.html
  ```
  *(ou exécuter Godot depuis votre chemin local).*
