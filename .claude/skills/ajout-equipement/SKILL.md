---
name: ajout-equipement
description: Ajoute ou met à jour un objet dans l'inventaire à partir d'un document (facture, fiche produit, capture), d'un lien ou d'une simple description. À utiliser dès que Romain mentionne un achat, un objet qu'il possède, un document déposé dans documents/a-traiter, ou demande de compléter, corriger ou réformer un équipement.
---

# Ajout d'équipement

## Étapes

1. Lire la source (document de `documents/a-traiter/`, lien, ou message).
2. Vérifier si l'objet existe déjà dans `inventaire/` (même marque et modèle, ou
   même rôle avec statut `a-confirmer`). Si oui, mettre à jour plutôt que dupliquer.
3. Choisir le fichier de catégorie. Attribuer les rôles depuis `roles.yaml`
   (tous ceux que l'objet peut raisonnablement remplir) et les activités compatibles.
   Si un rôle nécessaire manque, le proposer avant de l'ajouter à `roles.yaml`
   (dans le bon univers `en-action` / `hors-action` et le bon groupe).
   Pour un vêtement (groupes haut, bas, accessoires, dans les deux univers), renseigner
   systématiquement `saison` : `chaud`, `froid` ou `toutes-saisons`.
   Si l'objet sert différemment selon l'activité (haut de course en trail, tenue
   d'après-sortie en gravel), utiliser `roles_par_activite`.
4. Renseigner uniquement les caractéristiques présentes dans la source.
   Laisser `null` le reste et lister ces champs dans la réponse.
5. Déplacer le document traité dans `documents/traites/`, puis contrôler la cohérence :
   `ruby -e 'require "./vue/donnees"; puts Donnees.erreurs_globales'` (rien ne doit s'afficher).
   L'application locale se met à jour toute seule.
6. Signaler si l'ajout comble un manque d'une activité, ou crée un doublon
   (deux objets pour le même rôle et la même plage de température).

Résumer en quelques lignes : objet ajouté, rôles, champs à compléter.
