const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json({ limit: '1mb' }));

// En-têtes Cross-Origin Isolation requis par Godot Web et CORS
app.use((req, res, next) => {
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

// Mémoire de signalisation WebRTC pour la salle de jeu
let salleSession = {
  offre: '',
  reponse: '',
  timestamp: Date.now()
};

// Route GET : lecture de l'offre ou de la réponse
app.get('/api/signal', (req, res) => {
  res.json({ data: salleSession });
});

// Route POST : mise à jour de l'offre ou de la réponse
app.post('/api/signal', (req, res) => {
  const { offre, reponse, reset } = req.body || {};
  if (reset) {
    salleSession = { offre: '', reponse: '', timestamp: Date.now() };
  } else {
    if (typeof offre === 'string') salleSession.offre = offre;
    if (typeof reponse === 'string') salleSession.reponse = reponse;
    salleSession.timestamp = Date.now();
  }
  res.json({ success: true, data: salleSession });
});

// Servir les fichiers exportés du jeu Godot
app.use(express.static(path.join(__dirname, 'build-web')));

// Fallback SPA vers index.html
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build-web', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Serveur Quête de l'Anneau et Relais de Signalisation en ligne sur le port ${PORT}`);
});
