# Application locale : consultation, checklist et édition de l'inventaire.
# Usage : ruby vue/serveur.rb   puis ouvrir http://localhost:4567
# Les modifications sont écrites directement dans inventaire/*.yaml.
require "webrick"
require_relative "donnees"

# WEBrick ne transmet pas DELETE aux blocs mount_proc : on l'aiguille comme les autres méthodes.
WEBrick::HTTPServlet::ProcHandler.send(:alias_method, :do_DELETE, :do_GET)

PORT = (ENV["PORT"] || 4567).to_i
GABARIT = File.join(__dir__, "gabarit.html")

def json(res, statut, corps)
  res.status = statut
  res["Content-Type"] = "application/json; charset=utf-8"
  res["Cache-Control"] = "no-store"
  res.body = JSON.generate(corps)
end

serveur = WEBrick::HTTPServer.new(Port: PORT, BindAddress: "127.0.0.1",
                                  Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN), AccessLog: [])

# La page, avec les données du moment injectées.
serveur.mount_proc("/") do |req, res|
  next json(res, 404, erreur: "introuvable") unless req.path == "/"
  html = File.read(GABARIT).sub("/*DONNEES*/") { JSON.generate(Donnees.tout).gsub("</", "<\\/") }
  res["Content-Type"] = "text/html; charset=utf-8"
  res["Cache-Control"] = "no-store"
  res.body = html
end

serveur.mount_proc("/api/donnees") { |_req, res| json(res, 200, Donnees.tout) }
serveur.mount_proc("/api/version") { |_req, res| json(res, 200, version: Donnees.version) }

# POST /api/objets            : création       { objet, fichier }
# PUT  /api/objets/<id>       : modification   { objet, fichier }
# DELETE /api/objets/<id>     : suppression
serveur.mount_proc("/api/objets") do |req, res|
  id = req.path.sub(%r{\A/api/objets/?}, "")
  begin
    case req.request_method
    when "POST", "PUT"
      corps = JSON.parse(req.body.to_s)
      erreurs = Donnees.enregistrer(corps["objet"], corps["fichier"], req.request_method == "PUT" ? id : nil)
    when "DELETE"
      erreurs = Donnees.supprimer(id)
    else
      next json(res, 405, erreurs: ["méthode non gérée"])
    end
    erreurs.empty? ? json(res, 200, Donnees.tout) : json(res, 422, erreurs: erreurs)
  rescue JSON::ParserError
    json(res, 400, erreurs: ["requête illisible"])
  end
end

trap("INT") { serveur.shutdown }
puts "Équipement outdoor : http://localhost:#{PORT}  (Ctrl+C pour arrêter)"
serveur.start
