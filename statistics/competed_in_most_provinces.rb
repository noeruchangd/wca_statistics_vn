require_relative "../core/statistic"
require 'rgeo'
require 'rgeo-geojson'

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
    
    @factory = RGeo::Geos.supported? ? RGeo::Geos.factory(srid: 4326) : RGeo::Cartesian.preferred_factory(srid: 4326)
    @province_cache = {}
    load_vietnam_provinces
  end

  def load_vietnam_provinces
    path = File.expand_path("../data/geojson-vietnam-34.geojson", __dir__)
    if File.exist?(path)
      file_content = File.read(path)
      decoded = RGeo::GeoJSON.decode(file_content, json_parser: :json, factory: @factory)
      @provinces_geojson = decoded ? decoded.to_a : []
      
      @spatial_index = RGeo::Cartesian::Analysis.spatial_index(@provinces_geojson.map(&:geometry))
      @all_province_names = @provinces_geojson.map { |f| province_name(f) }.compact.uniq.sort

    else
      @provinces_geojson = []
      @all_province_names = []
      @spatial_index = nil
      puts "Warning: GeoJSON file not found at #{path}"
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
        c.latitude / 1000000.0 AS lat,
        c.longitude / 1000000.0 AS lon
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

  def province_for(lat, lon)
    return nil if @spatial_index.nil?
    
    cache_key = "#{lat},#{lon}"
    return @province_cache[cache_key] if @province_cache.key?(cache_key)

    point = @factory.point(lon, lat)
    
    candidate_geometries = @spatial_index.search(point.envelope)
    found_geometry = candidate_geometries.find { |g| g.contains?(point) }
    
    if found_geometry
      feature = @provinces_geojson.find { |f| f.geometry == found_geometry }
      @province_cache[cache_key] = province_name(feature)
    else
      @province_cache[cache_key] = nil
    end
  end

  def province_name(feature)
    return nil unless feature
    feature.properties['ten_tinh'] || feature.properties['NAME_1'] || feature.properties['name']
  end
end