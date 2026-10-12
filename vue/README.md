# Vue

## Application locale

Double-cliquer sur « Lancer équipement.command » à la racine du projet, ou :

    ruby vue/serveur.rb

puis ouvrir http://localhost:4567 (fermer la fenêtre du Terminal ou Ctrl+C pour arrêter).

## Onglets

- **Mes sorties** : les checklists écrites par Claude (skill `checklist-sortie`) dans `sorties/`,
  la plus récente d'abord. On en ouvre une et on coche : chaque case est écrite dans le fichier
  (`- [x]`), donc Claude voit ce qui a été pris au moment du retour.
- **À acheter** : « Ma liste » d'achats (objets à acheter ou envisagés), chacun avec Acheté et
  Supprimer ; « Ajouter un objet » demande un nom et un modèle envisagé facultatif (texte ou lien,
  dont l'app essaie de lire le titre). Dessous, « Ce qui manque encore » par activité (Gravel / Trail),
  avec « Ajouter à ma liste ». « Ajouter un objet » (statut à acheter par défaut),
- **Mes équipements** : ce que je possède (statut possédé ou à confirmer), avec ajout et modification.
  Les modifications sont contrôlées (id en kebab-case et unique, rôles connus de `roles.yaml`,
  statut valide, tag saison pour les vêtements) puis écrites dans `inventaire/*.yaml`.

La page surveille les fichiers : un changement fait ailleurs (par Claude, à la main) s'affiche
tout seul en quelques secondes.

## Fichiers

- `donnees.rb` : lecture, contrôle de cohérence et écriture des YAML et des sorties (partagé)
- `serveur.rb` : application locale (WEBrick, fourni avec Ruby, rien à installer)
- `gabarit.html` : la page (ne pas éditer `index.html` à la main)
- `generer.rb` : produit `index.html`, version statique en lecture seule (ignorée par git)
