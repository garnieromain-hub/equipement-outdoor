---
name: checklist-sortie
description: Génère la checklist d'équipement d'une sortie (gravel, trail, rando… à la journée ou sur plusieurs jours) à partir de l'activité, des dates, des horaires, de la météo récupérée automatiquement et d'une éventuelle trace GPX. À utiliser dès que Romain parle de préparer une sortie, de quoi emporter, de son sac, donne une activité et une date (« trail samedi 6 h », « gravel demain, 8 °C, averses », « rando du 17 au 19 en refuge »), ou fait le retour d'une sortie passée, même sans dire « checklist ».
---

# Checklist de sortie

Toute la logique vient des fichiers : `activites/<activite>.yaml` (base, température,
modules, paramètres), `roles.yaml` (univers et groupes), `inventaire/*.yaml` (objets),
`profil.yaml` (allure, références, préférences et nutrition de Romain).
Ne jamais coder en dur un seuil, une vitesse ou une liste propre à une activité ici :
si une règle manque, proposer de l'ajouter au YAML de l'activité.

## 1. Comprendre la sortie

Extraire de la demande :
- **activité** : doit correspondre à un fichier `activites/*.yaml`. Si elle n'existe pas,
  le dire et proposer de créer le fichier (sur le modèle de `trail.yaml`) avant d'aller plus loin.
- **dates** : un jour, ou une plage (« du 17 au 19 », « 3 jours à partir de samedi »).
- **horaires** : départ, fin ou durée par jour (« toute la journée » = 9 h – 17 h, « matin » = 8 h – 12 h).
- **lieu** : ville de départ, ou trace GPX (chemin fourni, ou fichier dans `documents/a-traiter/`).
- **hébergement** si plusieurs jours : `refuge`, `bivouac` ou autre (gîte, hôtel : aucun module).

Demander uniquement ce qui bloque vraiment (activité inconnue, lieu absent pour la météo,
hébergement inconnu sur plusieurs jours). Pour le reste, prendre une hypothèse et l'écrire
en tête de checklist.

## 2. Mesurer : trace et météo

- Trace GPX : `ruby outils/gpx.rb <trace.gpx>` → distance, D+, D−, altitudes, point de départ.
- Durée, si elle n'est pas donnée : appliquer l'allure de `profil.yaml` (`<activite>.allure`),
  à défaut `parametres.vitesse` de l'activité
  (`velo` : km / plat_kmh + D+ / montee_m_h ; `km-effort` : (km + D+ / 100) / km_effort_h).
  Si la valeur est `null`, demander la durée prévue plutôt que deviner.
- Météo : `ruby outils/meteo.rb --ville <ville> | --lat <lat> --lon <lon> --du AAAA-MM-JJ [--au AAAA-MM-JJ] --debut <h> --fin <h> [--alt-max <point haut>]`.
  Utiliser le départ de la trace s'il y en a une, et passer `--alt-max` pour corriger le
  ressenti en altitude. Le résultat donne, jour par jour : ressenti mini sur le créneau,
  maxi, pluie, vent, soleil, et température mini de la nuit.
- Au-delà de 16 jours, pas de prévision : le dire, demander une estimation de température
  ou proposer de relancer plus près de la date.

## 3. Choisir les rôles

Lire `activites/<activite>.yaml` :
1. Partir de `base`.
2. **Température** : prendre le ressenti le plus bas sur l'ensemble des jours. Mode `chaud`
   s'il dépasse `temperature.seuil`, sinon `froid` : appliquer son `ajouter`, puis son
   `renfort` si la condition est remplie (`ajouter` puis `retirer`).
3. **Modules** : activer chaque module dont un critère de `declencheur` est rempli :
   - `pluie` : un jour avec une proba ≥ `parametres.pluie_proba_min` ou un cumul ≥ `pluie_mm_min`
   - `nuit` : départ avant le lever ou fin moins de 30 min avant le coucher
   - `duree_h: x` : une journée de plus de x heures
   - `altitude_m: x` / `denivele_m: x` : point haut ou D+ de la trace au-delà de x
   - `jours: x` : sortie d'au moins x jours
   - `hebergement: refuge|bivouac` : type de nuit annoncé
   - `course: true` : course organisée (dossard, règlement) ; lire le règlement et ajouter son
     matériel obligatoire, en signalant ce qui est obligatoire et ce qui est conseillé
   Un module peut avoir une exception `sauf` : si ses conditions sont remplies (`depart_max_h` :
   départ au plus tard à cette heure ; `distance_max_km` : distance inférieure), retirer ses rôles
   `retirer`, sauf ceux de `garder_si_obligatoire` quand le règlement de la course les impose.
   Le signaler dans les hypothèses.
4. Plusieurs jours : une seule liste (on emporte tout dès le départ), en signalant les
   jours qui imposent un module (« pluie le dimanche »).

## 4. Choisir les objets

Pour chaque rôle, chercher dans `inventaire/*.yaml` les objets qui le remplissent
(leurs `roles`, ou `roles_par_activite.<activite>` s'il existe, qui prime alors),
avec l'activité dans `activites` et `statut: possede` (`a-confirmer` accepté mais signalé).
S'il y en a plusieurs, préférer :
1. celui dont le tag `saison` correspond au mode (ou `toutes-saisons`) ;
2. celui dont `temp_min` / `temp_max` couvrent le mieux le ressenti prévu ;
3. le plus léger.

Un objet qui couvre plusieurs rôles (veste pluie qui sert de coupe-vent) n'est listé qu'une
fois, avec une mention. Pour un bivouac, comparer `temp_confort` du duvet à la température
mini de la nuit et alerter si elle est plus basse.

Un rôle sans objet possédé reste dans sa rubrique (Bas, Sécurité…), comme une case à cocher
avec le libellé du rôle et le tag `**à acheter**` (l'application l'affiche en pastille), suivi
si besoin d'un objet envisagé ou d'une solution de repli : `- [ ] Chaussettes mérinos épaisses – **à acheter** ; en attendant, …`.
Il n'y a pas de section Manques séparée.

## 5. Écrire la checklist

Fichier `sorties/AAAA-MM-JJ-<activite>.md` (date du premier jour). Sections rangées par
univers, avec les libellés `univers` de l'activité, puis par groupe dans l'ordre de `roles.yaml`.
N'afficher que les groupes non vides.

```markdown
# Trail – 17 au 18/10/2026 – Annecy – 2 jours, refuge

Hypothèses : départ 8 h, 6 h par jour, …
Météo : sam. 4 à 14 °C ressentis, pluie 27 % ; dim. 1 à 13 °C, sec. Nuit mini 2 °C.
Trace : 42 km, 2 300 m D+, point haut 2 100 m.
Température : froid (+ grand froid) · Modules : montagne, itinerance, refuge

## En course
### Haut
- [ ] Objet (rôle) – mention éventuelle
### Bas
- [ ] Libellé du rôle manquant – **à acheter** ; solution de repli éventuelle
### Accessoires
### Portage
### Navigation et énergie
### Ravitaillement
### Sécurité
## Après
### Haut
### Bas
### Accessoires
### Bivouac

## Eau et nourriture
Estimation à venir.

## Retour (à remplir après)
- Ce qui a manqué :
- Ce qui était en trop :
```

Section « Eau et nourriture » : si `profil.yaml` renseigne la nutrition, l'estimer pour la
durée prévue (eau, glucides, produits habituels, recharges aux ravitaillements) en montrant
le calcul ; sinon écrire « Estimation à venir ». Appliquer aussi les `preferences` du profil.

La checklist apparaît aussitôt dans l'application (onglet Mes sorties), où Romain la coche ;
les cases cochées sont écrites dans le fichier (`- [x]`). Garder ce format : cases `- [ ] `
pour les objets à emporter (y compris ceux à acheter), puces simples `- ` pour le retour, texte complémentaire
après « – » sur la même ligne.

Terminer par une
phrase sur les manques et les objets `a-confirmer`, puis toujours le lien de l'application :
http://localhost:4567 (onglet Mes sorties ; si elle n'est pas lancée : « Lancer équipement.command »
ou `ruby vue/serveur.rb`).

## 6. Retour après la sortie

Quand Romain raconte une sortie passée (« j'ai eu froid aux mains », « les bâtons ne
m'ont pas servi ») :
1. Remplir la section **Retour** du fichier `sorties/` correspondant, en s'aidant des cases
   cochées (`- [x]`) : un objet non coché a peut-être été laissé, à confirmer avec Romain.
2. Proposer l'ajustement précis du YAML de l'activité (déplacer un rôle, changer un seuil,
   modifier un renfort), sans l'appliquer avant son accord.

Avant de préparer une nouvelle sortie de la même activité, relire les sections **Retour**
des sorties passées et signaler celles qui s'appliquent (même saison, même type de sortie).
