#!/bin/bash
# Double-clic : lance l'application locale et l'ouvre dans le navigateur.
# Fermer la fenêtre du Terminal (ou Ctrl+C) arrête l'application.
cd "$(dirname "$0")"
URL=http://localhost:4567

# Déjà lancée : on se contente d'ouvrir la page.
if curl -s -o /dev/null "$URL/api/version"; then
  open "$URL"
  exit 0
fi

(sleep 2; open "$URL") &
exec ruby vue/serveur.rb
