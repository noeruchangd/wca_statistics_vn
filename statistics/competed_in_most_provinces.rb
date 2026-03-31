require_relative "../core/statistic"
require 'json'
require 'set'

class CompetedInMostProvinces < Statistic
  def initialize
    @title = "Competed in most provinces in Vietnam"
    @note = "Provinces are inferred from competition coordinates using precise Point-in-Polygon boundaries (GADM)."
    @table_header = {
      "Person" => :left,
      "Completed" => :right,
      "Missed Count" => :right,
      "Missed Provinces" => :left,
      "Completed All At" => :left
    }
    
    @province_cache = {}
    load_vietnam_provinces
  end

  def load_vietnam_provinces
    path = File.expand_path("../data/geojson-vietnam-34.geojson", __dir__)
    if File.exist?(path)
      json = JSON.parse(File.read(path))

      @provinces = json["features"].map do |f|
        {
          name: province_name_raw(f),
          polygons: extract_polygons(f["geometry"])
        }
      end

      @all_province_names = @provinces.map { |p| p[:name] }.compact.uniq.sort
    else
      @provinces = []
      @all_province_names = []
    end
  end

  def extract_polygons(geometry)
    case geometry["type"]
    when "Polygon"
      [geometry["coordinates"][0]] # outer ring only
    when "MultiPolygon"
      geometry["coordinates"].map { |poly| poly[0] }
    else
      []
    end
  end

  def query
    <<-SQL
      SELECT
        p.name,
        p.wca_id,
        c.id AS competition_id,
        c.name AS competition_name,
        c.end_date,
        c.latitude_microdegrees / 1000000.0 AS lat,
        c.longitude_microdegrees / 1000000.0 AS lon
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Vietnam'
      JOIN competitions c ON c.id = r.competition_id
      WHERE c.country_id = 'Vietnam'
      GROUP BY p.wca_id, c.id
      ORDER BY c.end_date ASC
    SQL
  end

  def transform(results)
    person_competitions = Hash.new { |h, k| h[k] = { name: "", province_names: Set.new, history: [] } }
    
    competition_to_province = {}
    unique_comps = results.uniq { |r| r["competition_id"] }
    
    unique_comps.each do |r|
      competition_to_province[r["competition_id"]] = province_for(r["lat"], r["lon"])
    end

    results.each do |r|
      wca_id = r["wca_id"]
      province = competition_to_province[r["competition_id"]]
      
      next unless province

      unless person_competitions[wca_id][:province_names].include?(province)
        person_competitions[wca_id][:history] << {
          province: province,
          competition_id: r["competition_id"],
          competition_name: r["competition_name"]
        }
        person_competitions[wca_id][:province_names] << province
      end
      person_competitions[wca_id][:name] ||= r["name"]
    end

    all_provinces_set = @all_province_names.to_set

    person_competitions.map do |wca_id, data|
      completed_names = data[:province_names]
      missed = (all_provinces_set - completed_names).to_a.sort
      
      completion_info = nil
      if missed.empty? && data[:history].any?
        last = data[:history].last
        completion_info = "[#{last[:competition_name]}](https://www.worldcubeassociation.org/competitions/#{last[:competition_id]})"
      end

      [
        "[#{data[:name]}](https://www.worldcubeassociation.org/persons/#{wca_id})",
        completed_names.size,
        missed.size,
        missed.join(", "),
        completion_info
      ]
    end.sort_by { |row| [-row[1], row[2], row[0]] }.first(100)
  end

  private

  def point_in_polygon?(x, y, polygon)
    inside = false
    n = polygon.length

    j = n - 1
    (0...n).each do |i|
      xi, yi = polygon[i]
      xj, yj = polygon[j]

      intersect = ((yi > y) != (yj > y)) &&
                  (x < (xj - xi) * (y - yi).to_f / (yj - yi + 1e-12) + xi)

      inside = !inside if intersect
      j = i
    end

    inside
  end

  def province_for(lat, lon)
    cache_key = "#{lat},#{lon}"
    return @province_cache[cache_key] if @province_cache.key?(cache_key)

    result = nil

    @provinces.each do |province|
      province[:polygons].each do |polygon|
        if point_in_polygon?(lon, lat, polygon)
          result = province[:name]
          break
        end
      end
      break if result
    end

    @province_cache[cache_key] = result
  end

  def province_name_raw(feature)
    props = feature["properties"]
    props["ten_tinh"] || props["NAME_1"] || props["name"]
  end
end