Page de consultation générée à partir de `roles.yaml`, `inventaire/` et `activites/`.

- `generer.rb` : lit les YAML, vérifie la cohérence des rôles, écrit `index.html`
- `gabarit.html` : mise en page et logique de la page (ne pas éditer `index.html` à la main)

Regénérer après chaque modification : `ruby vue/generer.rb`

Onglets :
- Préparer : phrase libre (« Gravel samedi 17 octobre toute la journée ») + ville de départ
  ou trace GPX. Météo Open-Meteo (16 jours max) sur le créneau, correction d'altitude
  (-0,65 °C / 100 m au-dessus du point de prévision), activation des modules, puis checklist.
- Checklist : bascule chaud / froid, renfort, modules de l’activité ; rangée par univers (libellés de l’activité) puis Haut, Bas, Accessoires…
- Manques : par activité, filtrable vêtements / tout et chaud / froid.
- Inventaire : recherche, filtre par statut.

Exports : Markdown (à déposer dans `sorties/`), CSV (Excel), impression / PDF.
