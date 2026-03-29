require_relative "../core/statistic"

class CompetedInMostVoivodeships < Statistic
  def initialize
    @title = "Competed in most voivodeships in Vietnam"
    @note = "Voivodeships are inferred from competition coordinates. Approximate bounding box classification."
    @table_header = {
      "Person" => :left,
      "Completed" => :right,
      "Missed" => :right,
      "Missed Voivodeships" => :left,
      "Completed At" => :left
    }
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
    voivodeships = {
      "dolnośląskie" => [50.09, 51.74, 15.03, 17.93],
      "kujawsko-pomorskie" => [52.58, 53.81, 17.45, 19.85],
      "lubelskie" => [50.33, 51.64, 22.01, 24.15],
      "lubuskie" => [51.08, 52.92, 14.12, 16.12],
      "łódzkie" => [51.00, 52.25, 18.17, 20.28],
      "małopolskie" => [49.33, 50.50, 19.15, 21.25],
      "mazowieckie" => [51.40, 53.55, 19.00, 22.00],
      "opolskie" => [50.17, 51.13, 17.33, 18.77],
      "podkarpackie" => [49.00, 50.55, 21.28, 23.53],
      "podlaskie" => [52.60, 54.50, 22.75, 23.85],
      "pomorskie" => [53.60, 55.15, 16.50, 19.75],
      "śląskie" => [49.40, 50.75, 18.00, 19.95],
      "świętokrzyskie" => [50.30, 51.15, 19.90, 21.45],
      "warmińsko-mazurskie" => [53.50, 54.45, 19.20, 22.95],
      "wielkopolskie" => [51.60, 53.50, 16.10, 18.90],
      "zachodniopomorskie" => [53.05, 54.35, 14.10, 16.70]
    }

    def voivodeship_for(lat, lon, voivodeships)
      candidates = voivodeships.select do |_, (lat_min, lat_max, lon_min, lon_max)|
        lat >= lat_min && lat <= lat_max && lon >= lon_min && lon <= lon_max
      end
      candidates.min_by do |_, (lat_min, lat_max, lon_min, lon_max)|
        (lat_max - lat_min) * (lon_max - lon_min)
      end&.first
    end

    person_competitions = Hash.new { |h, k| h[k] = { name: "", voivodeships: Set.new, history: [] } }

    sorted_results = results.sort_by { |r| [r["wca_id"], r["end_date"]] }

    sorted_results.each do |r|
      name = r["name"]
      wca_id = r["wca_id"]
      lat = r["lat"]
      lon = r["lon"]
      competition_id = r["competition_id"]
      competition_name = r["competition_name"]
      end_date = r["end_date"]
      voiv = voivodeship_for(lat, lon, voivodeships)
      next unless voiv

      unless person_competitions[wca_id][:voivodeships].include?(voiv)
        person_competitions[wca_id][:history] << {
          voiv: voiv,
          competition_id: competition_id,
          competition_name: competition_name,
          end_date: end_date
        }
      end

      person_competitions[wca_id][:name] = name
      person_competitions[wca_id][:voivodeships] << voiv
    end

    all_voivs = voivodeships.keys

    person_competitions.map do |wca_id, data|
      completed = data[:voivodeships].to_a.sort
      missed = all_voivs - completed
      completion_info = nil

      if missed.empty? && data[:history].any?
        last = data[:history].max_by { |h| h[:end_date] }
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
end
