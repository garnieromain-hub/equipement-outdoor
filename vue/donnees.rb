# Lecture, contrôle et écriture des données du projet (roles.yaml, inventaire/, activites/).
# Partagé par vue/generer.rb (page statique) et vue/serveur.rb (application locale).
Encoding.default_external = Encoding::UTF_8
require "yaml"
require "json"

module Donnees
  RACINE = File.expand_path("..", __dir__)
  STATUTS = %w[possede a-confirmer a-acheter envisage reforme].freeze
  SAISONS = %w[chaud froid toutes-saisons].freeze
  GROUPES_VETEMENTS = %w[haut bas accessoires].freeze
  # Ordre des champs à l'écriture d'un objet.
  CHAMPS = %w[id nom marque modele roles roles_par_activite activites saison temp_min temp_max temp_confort
              impermeable poids_g statut lien notes].freeze

  module_function

  def chemin(*parties)

    File.join(RACINE, *parties)

  end

  def roles
    YAML.load_file(chemin("roles.yaml")).flat_map do |univers, groupes|
      groupes.flat_map do |groupe, liste|
        liste.map { |id, libelle| { "id" => id, "libelle" => libelle, "univers" => univers, "groupe" => groupe } }
      end
    end
  end

  def fichiers_inventaire

    Dir[chemin("inventaire/*.yaml")].sort.map { |f| File.basename(f, ".yaml") }

  end

  def objets
    fichiers_inventaire.flat_map do |nom|
      (YAML.load_file(chemin("inventaire", "#{nom}.yaml")) || []).map { |o| o.merge("fichier" => nom) }
    end
  end

  def activites

    Dir[chemin("activites/*.yaml")].sort.map { |f| YAML.load_file(f) }

  end

  # Empreinte des fichiers : change dès qu'un YAML est modifié (par la page ou à la main).
  def version
    fichiers = [chemin("roles.yaml")] + Dir[chemin("inventaire/*.yaml")] + Dir[chemin("activites/*.yaml")] +
               Dir[chemin("sorties/????-??-??-*.md")]
    fichiers.map { |f| "#{f}:#{File.mtime(f).to_f}" }.sort.join("|").hash.to_s
  end

  # Checklists écrites par la skill checklist-sortie : sorties/AAAA-MM-JJ-activite.md, la plus récente d'abord.
  def sorties
    Dir[chemin("sorties/????-??-??-*.md")].sort.reverse.map do |f|
      nom = File.basename(f, ".md")
      contenu = File.read(f)
      { "fichier" => nom, "date" => nom[0, 10], "activite" => nom[11..-1],
        "titre" => contenu[/^# (.+)$/, 1] || nom, "contenu" => contenu }
    end
  end

  # Coche ou décoche la case de la ligne `ligne` (numérotée à partir de 0) d'une sortie.
  def cocher(nom, ligne, coche)
    return ["sortie inconnue : #{nom}"] unless nom.to_s.match?(/\A\d{4}-\d{2}-\d{2}-[a-z0-9-]+\z/)
    f = chemin("sorties", "#{nom}.md")
    return ["sortie introuvable : #{nom}"] unless File.exist?(f)
    lignes = File.read(f).split("\n", -1)
    l = lignes[ligne.to_i].to_s
    return ["la ligne #{ligne} n'est pas une case à cocher"] unless l.match?(/\A\s*- \[[ xX]\] /)
    lignes[ligne.to_i] = l.sub(/- \[[ xX]\] /, coche ? "- [x] " : "- [ ] ")
    File.write(f, lignes.join("\n"))
    []
  end

  def tout
    { "roles" => roles, "objets" => objets, "activites" => activites, "fichiers" => fichiers_inventaire, "sorties" => sorties,
      "statuts" => STATUTS, "saisons" => SAISONS, "version" => version,
      "genere_le" => Time.now.strftime("%Y-%m-%d %H:%M") }
  end

  # Erreurs bloquantes d'un objet (tableau de messages, vide si l'objet est valide).
  def erreurs_objet(o, roles_connus, autres_ids)
    groupe = roles_connus.to_h { |r| [r["id"], r["groupe"]] }
    e = []
    e << "id manquant ou pas en kebab-case" unless o["id"].to_s.match?(/\A[a-z0-9]+(-[a-z0-9]+)*\z/)
    e << "id déjà utilisé : #{o['id']}" if autres_ids.include?(o["id"])
    e << "nom manquant" if o["nom"].to_s.strip.empty?
    tous_roles = Array(o["roles"]) + (o["roles_par_activite"] || {}).values.flatten
    e << "au moins un rôle est nécessaire" if Array(o["roles"]).empty?
    inconnus = tous_roles - groupe.keys
    e << "rôles absents de roles.yaml : #{inconnus.join(', ')}" unless inconnus.empty?
    e << "statut invalide : #{o['statut']}" unless STATUTS.include?(o["statut"])
    vetement = tous_roles.any? { |r| GROUPES_VETEMENTS.include?(groupe[r]) }
    e << "tag saison obligatoire pour un vêtement (chaud, froid, toutes-saisons)" if vetement && !SAISONS.include?(o["saison"])
    e << "saison invalide : #{o['saison']}" if o["saison"] && !SAISONS.include?(o["saison"])
    %w[temp_min temp_max temp_confort poids_g].each do |k|
      e << "#{k} doit être un nombre" unless o[k].nil? || o[k].is_a?(Numeric)
    end
    e
  end

  # Contrôle de cohérence global (règles de CLAUDE.md).
  def erreurs_globales
    rs = roles
    connus = rs.map { |r| r["id"] }
    e = []
    obs = objets
    obs.group_by { |o| o["id"] }.each { |id, l| e << "id en double : #{id}" if l.size > 1 }
    obs.each { |o| erreurs_objet(o, rs, []).each { |m| e << "#{o['id']} : #{m}" } }
    listes = ->(m) { (m["ajouter"] || []) + (m["retirer"] || []) }
    activites.each do |a|
      inconnus = a["base"] - connus
      (a["modules"] || {}).each_value { |m| inconnus += listes.(m) - connus }
      %w[chaud froid].each do |mode|
        m = a.dig("temperature", mode) or next
        inconnus += (listes.(m) + listes.(m["renfort"] || {})) - connus
      end
      e << "#{a['activite']} : rôles absents de roles.yaml : #{inconnus.uniq.join(', ')}" unless inconnus.empty?
    end
    e
  end

  # --- Écriture ---------------------------------------------------------------

  def valeur(v)
    case v
    when nil then "null"
    when true, false, Numeric then v.to_s
    when Array then "[#{v.map { |x| valeur(x) }.join(', ')}]"
    else
      s = v.to_s
      # Texte simple sans ambiguïté YAML : écrit tel quel ; sinon entre guillemets (JSON est du YAML valide).
      simple = s.match?(/\A[[:alpha:]][[:alnum:] .,'()°\/+-]*\z/) && !s.match?(/\A(null|true|false|yes|no|on|off)\z/i) && !s.end_with?(" ")
      simple || s.match?(%r{\Ahttps?://[^\s"#]+\z}) ? s : JSON.generate(s)
    end
  end

  def bloc_objet(o)
    lignes = []
    cles = CHAMPS.select { |k| o.key?(k) } + (o.keys - CHAMPS - ["fichier"])
    cles.each_with_index do |k, i|
      prefixe = i.zero? ? "- " : "  "
      v = o[k]
      if v.is_a?(Hash)
        next if v.empty?
        lignes << "#{prefixe}#{k}:"
        v.each { |sk, sv| lignes << "    #{sk}: #{valeur(sv)}" }
      else
        texte = k == "notes" && v.is_a?(String) ? JSON.generate(v) : valeur(v)
        lignes << "#{prefixe}#{k}: #{texte}"
      end
    end
    lignes.join("\n")
  end

  # Réécrit un fichier d'inventaire en gardant son en-tête de commentaires.
  def ecrire_fichier(nom, liste)
    f = chemin("inventaire", "#{nom}.yaml")
    entete = File.exist?(f) ? File.readlines(f).take_while { |l| l.start_with?("#") || l.strip.empty? }.join.rstrip : ""
    corps = liste.empty? ? "[]" : liste.map { |o| bloc_objet(o) }.join("\n\n")
    File.write(f, [entete, corps].reject(&:empty?).join("\n\n") + "\n")
  end

  def nettoyer(o)
    o = o.reject { |k, _| k == "fichier" }
    o["roles_par_activite"] = (o["roles_par_activite"] || {}).reject { |_, v| Array(v).empty? }
    o.delete("roles_par_activite") if o["roles_par_activite"].empty?
    o
  end

  # Crée ou remplace un objet. ancien_id = nil pour une création. Renvoie la liste d'erreurs.
  def enregistrer(o, fichier, ancien_id = nil)
    return ["fichier d'inventaire inconnu : #{fichier}"] unless fichier.to_s.match?(/\A[a-z0-9-]+\z/)
    obs = objets
    autres = obs.map { |x| x["id"] } - [ancien_id]
    o = nettoyer(o)
    erreurs = erreurs_objet(o, roles, autres)
    return erreurs unless erreurs.empty?

    ancien = obs.find { |x| x["id"] == ancien_id }
    if ancien && ancien["fichier"] != fichier
      supprimer(ancien_id)
      ancien = nil
    end
    liste = obs.select { |x| x["fichier"] == fichier }.map { |x| nettoyer(x) }
    if ancien
      liste[liste.index { |x| x["id"] == ancien_id }] = o
    else
      liste << o
    end
    ecrire_fichier(fichier, liste)
    []
  end

  def supprimer(id)
    o = objets.find { |x| x["id"] == id } or return ["objet introuvable : #{id}"]
    liste = objets.select { |x| x["fichier"] == o["fichier"] && x["id"] != id }.map { |x| nettoyer(x) }
    ecrire_fichier(o["fichier"], liste)
    []
  end
end
