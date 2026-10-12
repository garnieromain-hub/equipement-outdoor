# Roadmap

Objectif actuel : **la checklist de sortie**, juste et facile à tenir à jour.
Le reste (mobile, Profil course, préparation de séjour) viendra ensuite.

Dernière mise à jour : 2026-10-12.

## Fait

### Modèle de données
- Deux couches reliées par des rôles : `inventaire/` (chaque objet une fois) et `activites/` (rôles nécessaires).
- `roles.yaml` en deux univers : **en-action** / **hors-action**, avec un libellé par activité
  (gravel : On bike / Off bike ; trail : En course / Après).
- Vêtements rangés en haut / bas / accessoires, avec un tag `saison` obligatoire : chaud, froid, toutes-saisons.
- Rôles génériques : le champ `activites` de l'objet dit où il sert ; `roles_par_activite` quand un objet
  sert différemment selon l'activité (mérinos NNormal : haut en trail, rechange en gravel).
- Off bike = la rechange (haut, bas, chaussures) et les nuits : n'apparaît qu'à partir de 2 jours.

### Activités
- **Gravel** : base, bascule chaud / froid à 12 °C ressentis (renforts mi-saison et grand froid),
  modules pluie, longue sortie, itinérance, nuit.
- **Trail** (première version, à valider) : seuil 10 °C, modules pluie, longue sortie, montagne,
  nuit, itinérance, refuge, bivouac.
- Seuils, vitesses et déclencheurs dans les YAML : la page et la skill lisent les mêmes chiffres.

### Inventaire
- 23 objets : tenue gravel (Gobik, Cascada, Van Rysel, Fizik, buff, Bonatti), tenue trail
  (NNormal, Tomir 02, Salomon, Ciele, Icebreaker, Sense Pro 10, Compressport),
  envisagés (veste Raidlight Ultralight 3.0, duvet).

### Application locale (`Lancer équipement.command` ou `ruby vue/serveur.rb`)
- Mes sorties : les checklists préparées avec Claude, cochables, cases écrites dans les fichiers.
- Manques : uniquement ce qui manque vraiment, par activité, avec le contexte où ça sert.
- Mes équipements : ce que je possède, édition (ajout, modification, suppression) avec contrôles,
  écriture directe dans les YAML, mise à jour en direct quand un fichier change.
- Export CSV, impression / PDF.
- Abandonné : l'onglet Préparer (phrase libre, météo, normales de saison, forçages) et les filtres ;
  la préparation se fait avec Claude. Le code reste dans l'historique git si besoin.

### Skills et outils
- `ajout-equipement` : intégrer un objet depuis un lien, une photo, une description.
- `checklist-sortie` : toutes activités, un ou plusieurs jours, météo et GPX automatiques,
  retour d'expérience exploité.
- `outils/meteo.rb` (prévisions jour par jour, nuit, altitude) et `outils/gpx.rb` (distance, D+, altitudes).

### Projet
- Git + dépôt GitHub privé `garnieromain-hub/equipement-outdoor`.

## À faire : la checklist (priorité)

### À compléter ou valider
- [ ] Tester la skill `checklist-sortie` sur une vraie sortie, puis faire le premier retour d'expérience.
- [ ] Valider `trail.yaml` : base, seuil 10 °C, renforts, module montagne (1 500 m ou 1 000 m D+), longue sortie (3 h).
- [ ] Valider les rôles ajoutés pour le trail et le multi-jours.
- [ ] Renseigner l'allure trail (`km_effort_h`) pour estimer les durées depuis une trace.
- [ ] Saisir les objets communs : casque, lunettes, téléphone, papiers, bidons, nourriture, électrolytes.
- [ ] Compléter le trail : frontale, bâtons, collant long et thermique, gants, chaussettes chaudes,
      manchettes, doudoune, pochette étanche, trousse de secours, couverture de survie.
- [ ] Compléter le Off bike : bas de rechange, chaussures du soir.
- [ ] Préciser : version de la Bonatti, modèles Compressport / Ciele / Icebreaker, poids NNormal.
- [ ] Choisir le duvet (Rab Mythic Ultra 360 ou Simond Sprint 900, comparatif fait).

### À construire
- [ ] **Eau et nourriture** : estimer les quantités à partir de tes habitudes (gels, eau, poudre…).
- [ ] **Module hiver / neige** : crampons légers, guêtres, etc., déclenché par la neige ou le froid en altitude.
- [ ] Nouvelles activités : rando, bikepacking.
- [ ] Modifier les activités (seuils, listes) depuis l'application.
- [ ] Enregistrement git automatique à chaque modification faite dans l'application,
      et bouton « Sauvegarder sur GitHub ».
- [ ] Option : lancer l'application automatiquement à l'ouverture de la session.

## Plus tard

### Mobile
- Deux voies possibles, les données étant de simples fichiers :
  page privée sur claude.ai (base de données + chat avec Claude intégré),
  ou application Next.js sur Vercel (comme Profil course), la plus évolutive.
- Chat dans l'application : soit un vrai chat avec Claude (page publiée), soit un dialogue
  à règles fixes qui pose la question manquante (fonctionne hors ligne).

### Rapprochement avec Profil course
- Météo à l'heure de passage aux points clés, arrivée de nuit → frontale.
- Quantités d'eau et de nourriture entre deux ravitaillements.
- Allure réelle tirée du réalisé pour régler `km_effort_h`.
- Module « course » avec le matériel obligatoire de l'organisation.
- Retour d'expérience : réalisé + retour de checklist côte à côte.

### Préparation de séjour (vision élargie)
Exemple : « trail sur 3 jours dans le Vercors un week-end de décembre ».
- Objectif → questions de cadrage → 2 ou 3 scénarios → choix → dossier complet dans `sorties/`.
- Itinéraire : étapes (km, D+, durée, points d'eau, hébergements), en s'appuyant sur des itinéraires connus
  (GR91, Grande Traversée du Vercors) ; traces GPX générées par BRouter (testé, fonctionne).
- Accès depuis chez soi : voiture via OSRM (testé, fonctionne : distance, temps), train + car avec liens
  à vérifier ; API SNCF possible plus tard (clé personnelle gratuite).
- Météo : normales de saison si la date est lointaine, prévisions à 16 jours ensuite.
- Risques signalés (neige, refuges non gardés, durée du jour en hiver).
- Organisation : une skill « séjour » qui converse et orchestre, des agents en coulisses pour les recherches
  lourdes (itinéraire et hébergements, accès et transport), `checklist-sortie` en étape finale,
  outils `itineraire.rb` (BRouter) et `trajet.rb` (OSRM), un `profil.yaml` (point de départ,
  transports, allure, préférences).
- Limites : pas de réservation, horaires de train à vérifier, traces à relire sur carte,
  pas d'accès aux sites à compte (Komoot, Visorando).

## Décisions prises
- Les fichiers YAML du projet sont la référence ; l'application et les skills les lisent et les écrivent.
- La conversation pour préparer une sortie se fait avec Claude (skill), l'application sert à consulter,
  cocher, exporter et éditer l'inventaire.
- Le mobile n'est pas prioritaire.
- On reste sur la checklist ; la préparation de séjour est une évolution future.
