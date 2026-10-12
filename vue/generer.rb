# Génère vue/index.html, version statique (consultation hors application locale).
# Usage : ruby vue/generer.rb
require_relative "donnees"

erreurs = Donnees.erreurs_globales
abort "Incohérences :\n- #{erreurs.join("\n- ")}" unless erreurs.empty?

donnees = Donnees.tout
json = JSON.generate(donnees).gsub("</", "<\\/")
gabarit = File.read(File.join(__dir__, "gabarit.html"))
File.write(File.join(__dir__, "index.html"), gabarit.sub("/*DONNEES*/") { json })
puts "vue/index.html généré : #{donnees['objets'].size} objets, #{donnees['activites'].size} activité(s)."
