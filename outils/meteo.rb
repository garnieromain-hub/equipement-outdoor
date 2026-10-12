# Météo d'une sortie (Open-Meteo, 16 jours maximum), résumée jour par jour sur le créneau d'activité,
# avec la température minimale de la nuit pour les itinérances.
# Usage :
#   ruby outils/meteo.rb --ville Annecy --du 2026-10-17 [--au 2026-10-19] [--debut 9] [--fin 17] [--alt-max 1800]
#   ruby outils/meteo.rb --lat 45.9 --lon 6.12 --du 2026-10-17
# --alt-max : point haut de la trace ; le ressenti mini est abaissé de 0,65 °C par 100 m au-dessus du point de prévision.
Encoding.default_external = Encoding::UTF_8
require "net/http"
require "json"
require "uri"
require "date"
require "optparse"

opt = { debut: 9.0, fin: 17.0 }
OptionParser.new do |o|
  o.on("--ville V") { |v| opt[:ville] = v }
  o.on("--lat X", Float) { |v| opt[:lat] = v }
  o.on("--lon X", Float) { |v| opt[:lon] = v }
  o.on("--du D") { |v| opt[:du] = Date.parse(v) }
  o.on("--au D") { |v| opt[:au] = Date.parse(v) }
  o.on("--debut H", Float) { |v| opt[:debut] = v }
  o.on("--fin H", Float) { |v| opt[:fin] = v }
  o.on("--alt-max M", Float) { |v| opt[:alt_max] = v }
end.parse!
abort "Préciser --du AAAA-MM-JJ" unless opt[:du]
opt[:au] ||= opt[:du]

get = ->(url) { JSON.parse(Net::HTTP.get(URI(url))) }
lieu = opt[:ville]
if opt[:ville]
  g = get.("https://geocoding-api.open-meteo.com/v1/search?count=1&language=fr&name=#{URI.encode_www_form_component(opt[:ville])}")
  r = g["results"]&.first or abort "Ville introuvable : #{opt[:ville]}"
  opt[:lat], opt[:lon], lieu = r["latitude"], r["longitude"], "#{r['name']} (#{r['admin1']})"
end
abort "Préciser --ville ou --lat/--lon" unless opt[:lat] && opt[:lon]

# Un jour de plus à la fin pour avoir la nuit qui suit le dernier jour.
url = "https://api.open-meteo.com/v1/forecast?latitude=#{opt[:lat]}&longitude=#{opt[:lon]}&timezone=auto" \
      "&hourly=temperature_2m,apparent_temperature,precipitation_probability,precipitation,wind_speed_10m,wind_gusts_10m" \
      "&daily=sunrise,sunset&start_date=#{opt[:du]}&end_date=#{opt[:au] + 1}"
m = get.(url)
abort "Open-Meteo : #{m['reason']} (prévisions limitées à 16 jours)" if m["error"]

h = m["hourly"]
heures = h["time"].each_with_index.map { |t, i| [DateTime.parse(t), i] }
baisse = opt[:alt_max] && opt[:alt_max] > m["elevation"] + 100 ? (opt[:alt_max] - m["elevation"]) * 0.0065 : 0
dec = ->(s) { s[11, 2].to_i + s[14, 2].to_i / 60.0 }

jours = (opt[:du]..opt[:au]).map do |jour|
  idx = heures.select { |d, _| d.to_date == jour && d.hour >= opt[:debut].floor && d.hour <= [opt[:fin].ceil, 23].min }.map(&:last)
  nuit = heures.select { |d, _| (d.to_date == jour && d.hour >= 20) || (d.to_date == jour + 1 && d.hour <= 7) }.map(&:last)
  v = ->(k, ids = idx) { ids.map { |i| h[k][i] }.compact }
  k = m["daily"]["time"].index(jour.to_s)
  {
    date: jour.to_s,
    ressenti_min: (v.("apparent_temperature").min - baisse).round(1),
    temp_max: v.("temperature_2m").max,
    pluie_proba_max: v.("precipitation_probability").max || 0,
    pluie_mm: v.("precipitation").sum.round(1),
    vent_max: v.("wind_speed_10m").max, rafales_max: v.("wind_gusts_10m").max,
    lever: m["daily"]["sunrise"][k][11, 5], coucher: m["daily"]["sunset"][k][11, 5],
    nuit_temp_min: nuit.empty? ? nil : (v.("temperature_2m", nuit).min - baisse).round(1)
  }
end

puts JSON.pretty_generate(
  lieu: lieu, lat: opt[:lat], lon: opt[:lon], altitude_prevision: m["elevation"],
  correction_altitude: baisse.zero? ? nil : "ressenti et nuit abaissés de #{baisse.round(1)} °C pour le point haut à #{opt[:alt_max].round} m",
  creneau: "#{opt[:debut]} h – #{opt[:fin]} h", jours: jours
)
