# Génère vue/index.html à partir de roles.yaml, inventaire/ et activites/.
# Usage : ruby vue/generer.rb
Encoding.default_external = Encoding::UTF_8
require "yaml"
require "json"

racine = File.expand_path("..", __dir__)
lire = ->(chemin) { YAML.load_file(File.join(racine, chemin)) || [] }

roles = lire.("roles.yaml").flat_map do |univers, groupes|
  groupes.flat_map do |groupe, liste|
    liste.map { |id, libelle| { id: id, libelle: libelle, univers: univers, groupe: groupe } }
  end
end

objets = Dir[File.join(racine, "inventaire/*.yaml")].sort.flat_map do |f|
  (YAML.load_file(f) || []).map { |o| o.merge("fichier" => File.basename(f, ".yaml")) }
end

activites = Dir[File.join(racine, "activites/*.yaml")].sort.map { |f| YAML.load_file(f) }

# Contrôle de cohérence : un rôle inconnu bloque la génération.
connus = roles.map { |r| r[:id] }
inconnus = objets.flat_map { |o| o["roles"] + (o["roles_par_activite"] || {}).values.flatten - connus }
listes = ->(m) { (m["ajouter"] || []) + (m["retirer"] || []) }
activites.each do |a|
  inconnus += a["base"] - connus
  (a["modules"] || {}).each_value { |m| inconnus += listes.(m) - connus }
  %w[chaud froid].each do |mode|
    m = a.dig("temperature", mode) or next
    inconnus += (listes.(m) + listes.(m["renfort"] || {})) - connus
  end
end
saisons = %w[chaud froid toutes-saisons]
sans_saison = objets.select do |o|
  vetement = o["roles"].any? { |r| %w[haut bas accessoires].include?(roles.find { |x| x[:id] == r }&.dig(:groupe)) }
  vetement && !saisons.include?(o["saison"])
end
warn "Vêtements sans tag saison valide : #{sans_saison.map { |o| o['id'] }.join(', ')}" unless sans_saison.empty?
abort "Rôles absents de roles.yaml : #{inconnus.uniq.join(', ')}" unless inconnus.empty?

donnees = { roles: roles, objets: objets, activites: activites,
            genere_le: Time.now.strftime("%Y-%m-%d %H:%M") }

gabarit = File.read(File.join(__dir__, "gabarit.html"))
json = JSON.generate(donnees).gsub("</", "<\\/")
File.write(File.join(__dir__, "index.html"), gabarit.sub("/*DONNEES*/", json))
puts "vue/index.html généré : #{objets.size} objets, #{activites.size} activité(s)."
