# Équipement outdoor de Romain

Projet de gestion de mon équipement sportif et de mes checklists par activité.
Je tutoie Claude, Claude me tutoie. Tout le contenu est en français.

## Principe

Deux couches séparées, reliées par des **rôles** :

1. `inventaire/` décrit chaque objet **une seule fois**, quelle que soit l'activité.
   Chaque objet déclare les rôles qu'il remplit (ex. `veste-pluie`, `coupe-vent`).
2. `activites/` décrit, pour chaque activité, les rôles nécessaires :
   une base toujours emportée + une bascule de température chaud / froid (avec un
   renfort mi-saison ou grand froid) + des modules conditionnels (pluie, durée, nuit,
   altitude, plusieurs jours, refuge, bivouac), chacun avec un `declencheur`.
   Les seuils et vitesses sont dans `parametres` : la page et la skill lisent les mêmes.

Les rôles sont rangés en deux univers : **en-action** (porté et emporté pendant l'effort)
et **hors-action** (la rechange et les nuits, qui n'apparaissent qu'à partir de 2 jours). Chaque activité leur donne son libellé
(gravel : On bike / Off bike, trail : En course / Après). Les rôles sont génériques :
le champ `activites` de l'objet dit pour quelles activités il convient. Les vêtements sont classés en
haut / bas / accessoires et portent tous un tag `saison` : `chaud`, `froid` ou `toutes-saisons`.

Une checklist de sortie = rôles de la base + rôles du mode de température + rôles des modules activés,
chaque rôle étant rempli par un objet de l'inventaire. Un rôle sans objet = un manque.
On n'édite donc jamais une checklist quand on ajoute un objet : on lui donne ses rôles.

## Arborescence

- `inventaire/*.yaml` : objets, un fichier par catégorie
- `activites/*.yaml` : besoins par activité (gravel, trail)
- `outils/` : `gpx.rb` (résumé d'une trace) et `meteo.rb` (prévisions Open-Meteo jour par jour)
- `roles.yaml` : liste de référence des rôles, par univers puis groupe
- `profil.yaml` : mes données personnelles (allure, courses de référence, préférences, nutrition) ;
  à lire pour tout ce qui me concerne, et à compléter quand je donne ce type d'information
- `sorties/` : checklists générées, `AAAA-MM-JJ-activite.md`
- `documents/a-traiter/` : je dépose factures, fiches produits, photos, liens
- `documents/traites/` : documents déjà intégrés à l'inventaire
- `ROADMAP.md` : ce qui est fait, à faire, et la vision future
- `vue/` : application locale (« Lancer équipement.command » ou `ruby vue/serveur.rb`) → http://localhost:4567 :
  Mes sorties (checklists de `sorties/`, cochables), Manques, Mes équipements (édition), mise à jour en direct

## Règles

- Ne jamais inventer de caractéristiques (poids, températures) : laisser `null`
  et le signaler, plutôt que deviner.
- Un nouveau rôle doit d'abord être ajouté à `roles.yaml`.
- Les `id` sont en kebab-case et stables (ils servent de références).
- Statuts possibles : `possede`, `a-confirmer`, `a-acheter`, `envisage`, `reforme`.
- Après toute modification, vérifier la cohérence : chaque rôle utilisé dans
  `activites/` existe dans `roles.yaml`, chaque rôle d'objet aussi
  (`ruby -e 'require "./vue/donnees"; puts Donnees.erreurs_globales'` doit ne rien afficher).
- Le projet est versionné avec git (dépôt GitHub privé garnieromain-hub/equipement-outdoor) :
  enregistrer chaque lot de modifications avec un message clair.

## Skills du projet

- `checklist-sortie` : générer la checklist d'une sortie (activité, durée, météo)
- `ajout-equipement` : intégrer un objet depuis un document, un lien ou une description
