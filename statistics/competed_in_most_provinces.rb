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
    
    @factory = RGeo::Geos.factory(srid: 4326)
    load_vietnam_provinces
  end

  def load_vietnam_provinces
    path = File.expand_path("../data/geojson-vietnam-34.geojson", __dir__)
    if File.exist?(path)
      file_content = File.read(path)
      @provinces_geojson = RGeo::GeoJSON.decode(file_content, json_parser: :json, factory: @factory)
      @all_province_names = @provinces_geojson.map { |f| province_name(f) }.compact.sort
    else
      @provinces_geojson = []
      @all_province_names = []
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
    SQL
  end

  def transform(results)
    person_competitions = Hash.new { |h, k| h[k] = { name: "", province_names: Set.new, history: [] } }
    sorted_results = results.sort_by { |r| r["end_date"] }

    sorted_results.each do |r|
      wca_id = r["wca_id"]
      lat = r["lat"]
      lon = r["lon"]
      
      province = province_for(lat, lon)
      next unless province

      unless person_competitions[wca_id][:province_names].include?(province)
        person_competitions[wca_id][:history] << {
          province: province,
          competition_id: r["competition_id"],
          competition_name: r["competition_name"],
          end_date: r["end_date"]
        }
      end

      person_competitions[wca_id][:name] = r["name"]
      person_competitions[wca_id][:province_names] << province
    end

    person_competitions.map do |wca_id, data|
      completed = data[:province_names].to_a.sort
      missed = @all_province_names - completed
      completion_info = nil

      if missed.empty? && data[:history].any?
        last = data[:history].last
        completion_info = "[#{last[:competition_name]}](https://www.worldcubeassociation.org/competitions/#{last[:competition_id]})"
      end

      [
        "[#{data[:name]}](https://www.worldcubeassociation.org/persons/#{wca_id})",
        completed.size,
        missed.size,
        missed.join(", "),
        completion_info
      ]
    end.sort_by { |row| [-row[1], row[2], row[0]] }.first(100)
  end

  private

  def province_for(lat, lon)
    return nil if @provinces_geojson.empty?
    
    point = @factory.point(lon, lat)
    feature = @provinces_geojson.find { |f| f.geometry.contains?(point) }
    province_name(feature) if feature
  end

  def province_name(feature)
    feature.properties['ten_tinh'] || feature.properties['NAME_1'] || feature.properties['name']
  end
end