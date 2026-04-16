require_relative "../core/statistic"

class SumOfRanksSingle < Statistic
  def initialize
    @title = "Sum of national rankings (single)"
    @table_header = { "Person" => :left, "SoR" => :center, "333" => :center, "222" => :center, "444" => :center, "555" => :center, "666" => :center, "777" => :center, "333oh" => :center, "sq1" => :center, "minx" => :center, "pyram" => :center, "skewb" => :center, "clock" => :center, "444bf" => :center, "555bf" => :center, "333bf" => :center, "333fm" => :center, "333mbf" => :center }
  end

  def query
    <<-SQL
        WITH
        max_rank_single AS (
            SELECT
                ra.event_id,
                COUNT(DISTINCT ra.person_id) + 1 AS max_rank
            FROM ranks_single ra
            JOIN persons p ON p.wca_id = ra.person_id
            WHERE p.country_id = 'Vietnam'
            AND ra.event_id NOT IN ('333mbo','magic','mmagic','333ft')
            GROUP BY ra.event_id
        ),

        grid AS (
            SELECT 
                p.wca_id AS person_id,
                e.id as event_id
            FROM persons p
            JOIN events e
            WHERE p.country_id = 'Vietnam'
                AND e.id NOT IN ('333mbo','magic','mmagic','333ft')
            AND p.sub_id = 1
        ),

        rank_single AS (
            SELECT
                g.person_id,
                g.event_id,
                COALESCE(ra.country_rank, m.max_rank) AS rank_value
            FROM grid g
            LEFT JOIN ranks_single ra
                ON ra.person_id = g.person_id
            AND ra.event_id = g.event_id
            LEFT JOIN max_rank_single m
                ON m.event_id = g.event_id
            WHERE g.event_id NOT IN ('333mbo','magic','mmagic','333ft')
        ),


        sum_single AS (
            SELECT
                person_id,
                SUM(rank_value) AS sum_rank_single
            FROM rank_single
            GROUP BY person_id
        )

        SELECT
            CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') person_link,
            s.sum_rank_single AS sor_single,
            COALESCE(MAX(CASE WHEN r.event_id = '333' THEN r.rank_value END), 1) AS `333`,
            COALESCE(MAX(CASE WHEN r.event_id = '222' THEN r.rank_value END), 1) AS `222`,
            COALESCE(MAX(CASE WHEN r.event_id = '444' THEN r.rank_value END), 1) AS `444`,
            COALESCE(MAX(CASE WHEN r.event_id = '555' THEN r.rank_value END), 1) AS `555`,
            COALESCE(MAX(CASE WHEN r.event_id = '666' THEN r.rank_value END), 1) AS `666`,
            COALESCE(MAX(CASE WHEN r.event_id = '777' THEN r.rank_value END), 1) AS `777`,
            COALESCE(MAX(CASE WHEN r.event_id = '333oh' THEN r.rank_value END), 1) AS `333oh`,
            COALESCE(MAX(CASE WHEN r.event_id = 'sq1' THEN r.rank_value END), 1) AS `sq1`,
            COALESCE(MAX(CASE WHEN r.event_id = 'minx' THEN r.rank_value END), 1) AS `minx`,
            COALESCE(MAX(CASE WHEN r.event_id = 'pyram' THEN r.rank_value END), 1) AS `pyram`,
            COALESCE(MAX(CASE WHEN r.event_id = 'skewb' THEN r.rank_value END), 1) AS `skewb`,
            COALESCE(MAX(CASE WHEN r.event_id = 'clock' THEN r.rank_value END), 1) AS `clock`,
            COALESCE(MAX(CASE WHEN r.event_id = '444bf' THEN r.rank_value END), 1) AS `444bf`,
            COALESCE(MAX(CASE WHEN r.event_id = '555bf' THEN r.rank_value END), 1) AS `555bf`,
            COALESCE(MAX(CASE WHEN r.event_id = '333bf' THEN r.rank_value END), 1) AS `333bf`,
            COALESCE(MAX(CASE WHEN r.event_id = '333fm' THEN r.rank_value END), 1) AS `333fm`,
            COALESCE(MAX(CASE WHEN r.event_id = '333mbf' THEN r.rank_value END), 1) AS `333mbf`

        FROM sum_single s
        JOIN persons p 
        ON p.wca_id = s.person_id AND p.sub_id = 1

        JOIN rank_single r 
        ON r.person_id = s.person_id

        GROUP BY 
            s.person_id, p.name, s.sum_rank_single

        ORDER BY s.sum_rank_single ASC LIMIT 200;
    SQL
  end
end
