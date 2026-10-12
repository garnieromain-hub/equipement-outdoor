# Résumé d'une trace GPX : distance, dénivelés, altitudes, point de départ.
# Usage : ruby outils/gpx.rb chemin/trace.gpx   → JSON sur la sortie standard
Encoding.default_external = Encoding::UTF_8
require "rexml/document"
require "json"

chemin = ARGV[0] or abort "Usage : ruby outils/gpx.rb trace.gpx"
doc = REXML::Document.new(File.read(chemin))
pts = []
doc.each_element("//trkpt | //rtept") do |p|
  ele = p.elements["ele"]&.text
  pts << { lat: p.attributes["lat"].to_f, lon: p.attributes["lon"].to_f, ele: ele && ele.to_f }
end
abort "Trace vide ou illisible : #{chemin}" if pts.size < 2

rad = ->(x) { x * Math::PI / 180 }
km = dplus = dmoins = 0.0
ref = pts[0][:ele]
pts.each_cons(2) do |a, b|
  h = Math.sin(rad.(b[:lat] - a[:lat]) / 2)**2 +
      Math.cos(rad.(a[:lat])) * Math.cos(rad.(b[:lat])) * Math.sin(rad.(b[:lon] - a[:lon]) / 2)**2
  km += 12742 * Math.asin(Math.sqrt(h))
  next unless b[:ele] && ref
  # Seuil de 5 m pour ne pas compter le bruit de l'altimètre.
  if (b[:ele] - ref).abs > 5
    b[:ele] > ref ? dplus += b[:ele] - ref : dmoins += ref - b[:ele]
    ref = b[:ele]
  end
end
eles = pts.map { |p| p[:ele] }.compact
nom = doc.elements["//trk/name"]&.text || doc.elements["//rte/name"]&.text || doc.elements["//metadata/name"]&.text

puts JSON.pretty_generate(
  nom: nom&.strip, depart: { lat: pts[0][:lat], lon: pts[0][:lon] },
  arrivee: { lat: pts[-1][:lat], lon: pts[-1][:lon] },
  km: km.round(1), dplus: dplus.round, dmoins: dmoins.round,
  alt_min: eles.min&.round, alt_max: eles.max&.round
)
