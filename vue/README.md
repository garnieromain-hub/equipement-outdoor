# Vue

## Application locale (recommandée)

Double-cliquer sur « Lancer équipement.command » à la racine du projet, ou :

    ruby vue/serveur.rb

puis ouvrir http://localhost:4567 (Ctrl+C dans le terminal pour arrêter).

- Consultation : Préparer, Checklist, Manques, Inventaire.
- Édition : dans l'onglet Inventaire, « Ajouter un objet » et « Modifier » sur chaque objet.
  Les modifications sont contrôlées (id en kebab-case et unique, rôles connus de `roles.yaml`,
  statut valide, tag saison pour les vêtements) puis écrites directement dans `inventaire/*.yaml`,
  en gardant l'en-tête de commentaires de chaque fichier.
- Mise à jour en direct : la page surveille les fichiers ; un changement fait ailleurs
  (par Claude, à la main) s'affiche tout seul en quelques secondes.

## Fichiers

- `donnees.rb` : lecture, contrôle de cohérence et écriture des YAML (partagé)
- `serveur.rb` : application locale (WEBrick, fourni avec Ruby, rien à installer)
- `gabarit.html` : la page (ne pas éditer `index.html` à la main)
- `generer.rb` : produit `index.html`, version statique en lecture seule (ignorée par git)

## Onglets

- Préparer : phrase libre (« gravel le we prochain à Tours ») + trace GPX facultative.
  Météo Open-Meteo (16 jours max), plusieurs jours, refuge / bivouac, correction d'altitude.
- Checklist : bascule chaud / froid, renfort, modules de l'activité ; rangée par univers
  (libellés de l'activité) puis Haut, Bas, Accessoires…
- Manques : par activité, filtrable vêtements / tout et chaud / froid.
- Inventaire : recherche, filtres statut et saison, édition.

Exports : Markdown (à déposer dans `sorties/`), CSV (Excel), impression / PDF.
