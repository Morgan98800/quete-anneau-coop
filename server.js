const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// En-têtes Cross-Origin Isolation requis par Godot Web
app.use((req, res, next) => {
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
  next();
});

// Servir les fichiers exportés du jeu
app.use(express.static(path.join(__dirname, 'build-web')));

// Fallback vers index.html
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build-web', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Serveur Quête de l'Anneau en ligne sur le port ${PORT}`);
});
