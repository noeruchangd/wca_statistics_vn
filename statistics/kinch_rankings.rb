require_relative "../core/statistic"

class KinchRankings < Statistic
  def initialize
    @title = "Kinch rankings of Vietnamese competitors"
    @table_header = { "Person" => :left, "Kinch" => :center, "333" => :center, "222" => :center, "444" => :center, "555" => :center, "666" => :center, "777" => :center, "333oh" => :center, "sq1" => :center, "minx" => :center, "pyram" => :center, "skewb" => :center, "clock" => :center, "444bf" => :center, "555bf" => :center, "333bf" => :center, "333fm" => :center, "333mbf" => :center }
  end

  def query
    <<-SQL
        WITH vn_avg AS (
            SELECT ra.event_id, MIN(ra.best) AS vn_avg
            FROM ranks_average ra
            JOIN persons p ON p.wca_id = ra.person_id
            WHERE p.country_id = 'Vietnam'
            AND p.sub_id = 1
            GROUP BY ra.event_id
        ),

        vn_single AS (
            SELECT rs.event_id, MIN(rs.best) AS vn_single
            FROM ranks_single rs
            JOIN persons p ON p.wca_id = rs.person_id
            WHERE p.country_id = 'Vietnam'
            AND p.sub_id = 1
            GROUP BY rs.event_id
        ),

        -- gộp PB 1 lần (tránh join 2 bảng nhiều lần)
        pb AS (
            SELECT 
                p.wca_id AS person_id,
                e.event_id,
                ra.best AS pb_avg,
                rs.best AS pb_single
            FROM persons p

            -- tạo danh sách event chuẩn
            JOIN (
                SELECT DISTINCT event_id FROM ranks_average
                UNION
                SELECT DISTINCT event_id FROM ranks_single
            ) e

            LEFT JOIN ranks_average ra 
                ON ra.person_id = p.wca_id
            AND ra.event_id = e.event_id

            LEFT JOIN ranks_single rs 
                ON rs.person_id = p.wca_id
            AND rs.event_id = e.event_id

            WHERE p.country_id = 'Vietnam'
            AND p.sub_id = 1
            AND p.wca_id IN (
                SELECT person_id
                FROM ranks_average
                WHERE event_id = '333'
                AND best > 0
                AND best <= 2000
            )
        ),

        -- tính kinch cho tất cả event (trừ mbf)
        kinch_base AS (
            SELECT
                pb.person_id,
                pb.event_id,
                CASE
                    WHEN pb.event_id IN ('222','333','444','555','666','777','333oh','sq1','minx','pyram','skewb','clock')
                        THEN
                            CASE WHEN pb.pb_avg IS NULL OR pb.pb_avg = 0 THEN 0
                            ELSE LEAST(1.0, vn_avg.vn_avg / pb.pb_avg)
                            END

                    WHEN pb.event_id IN ('444bf','555bf')
                        THEN
                            CASE WHEN pb.pb_single IS NULL OR pb.pb_single = 0 THEN 0
                            ELSE LEAST(1.0, vn_single.vn_single / pb.pb_single)
                            END

                    WHEN pb.event_id IN ('333bf','333fm')
                        THEN GREATEST(
                            CASE WHEN pb.pb_single IS NULL OR pb.pb_single = 0 THEN 0
                            ELSE LEAST(1.0, vn_single.vn_single / pb.pb_single)
                            END,
                            CASE WHEN pb.pb_avg IS NULL OR pb.pb_avg = 0 THEN 0
                            ELSE LEAST(1.0, vn_avg.vn_avg / pb.pb_avg)
                            END
                        )

                    ELSE 0
                END AS kinch_score

            FROM pb
            LEFT JOIN vn_avg USING(event_id)
            LEFT JOIN vn_single USING(event_id)
            WHERE pb.event_id IS NOT NULL
        ),

        -- MBF decode trực tiếp từ ranks_single (KHÔNG scan results nữa)
        mbf AS (
            SELECT
                rs.person_id,

                -- decode trực tiếp
                (99 - FLOOR(rs.best / 10000000)) AS diff,
                FLOOR((rs.best % 10000000) / 100) AS time_sec
            FROM ranks_single rs
            WHERE rs.event_id = '333mbf'
        ),

        mbf_score AS (
            SELECT
                person_id,
                (diff + (3600.0 - time_sec) / 3600.0) AS score
            FROM mbf
        ),

        vn_mbf AS (
            SELECT MAX(score) AS vn_score
            FROM mbf_score ms
            JOIN persons p ON p.wca_id = ms.person_id
            WHERE p.country_id = 'Vietnam'
        ),

        mbf_kinch AS (
            SELECT
                ms.person_id,
                '333mbf' AS event_id,
                COALESCE(ms.score / v.vn_score, 0) AS kinch_score
            FROM mbf_score ms
            JOIN persons p ON p.wca_id = ms.person_id
            CROSS JOIN vn_mbf v
            WHERE p.country_id = 'Vietnam'
        ),

        -- gộp tất cả
        all_scores AS (
            SELECT person_id, event_id, kinch_score FROM kinch_base
            UNION ALL
            SELECT person_id, event_id, kinch_score FROM mbf_kinch
        ),

        final AS (
            SELECT
                person_id,
                SUM(kinch_score) / 17 * 100 AS kinch
            FROM all_scores
            -- WHERE kinch_score IS NOT NULL
            GROUP BY person_id
        )

        SELECT
            CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
            ROUND(f.kinch, 2) as `kinch`,
            ROUND(MAX(CASE WHEN a.event_id = '333' THEN a.kinch_score * 100 END), 2) AS `333`,
            ROUND(MAX(CASE WHEN a.event_id = '222' THEN a.kinch_score * 100 END), 2) AS `222`,
            ROUND(MAX(CASE WHEN a.event_id = '444' THEN a.kinch_score * 100 END), 2) AS `444`,
            ROUND(MAX(CASE WHEN a.event_id = '555' THEN a.kinch_score * 100 END), 2) AS `555`,
            ROUND(MAX(CASE WHEN a.event_id = '666' THEN a.kinch_score * 100 END), 2) AS `666`,
            ROUND(MAX(CASE WHEN a.event_id = '777' THEN a.kinch_score * 100 END), 2) AS `777`,
            ROUND(MAX(CASE WHEN a.event_id = '333oh' THEN a.kinch_score * 100 END), 2) AS `333oh`,
            ROUND(MAX(CASE WHEN a.event_id = 'sq1' THEN a.kinch_score * 100 END), 2) AS sq1,
            ROUND(MAX(CASE WHEN a.event_id = 'minx' THEN a.kinch_score * 100 END), 2) AS minx,
            ROUND(MAX(CASE WHEN a.event_id = 'pyram' THEN a.kinch_score * 100 END), 2) AS pyram,
            ROUND(MAX(CASE WHEN a.event_id = 'skewb' THEN a.kinch_score * 100 END), 2) AS skewb,
            ROUND(MAX(CASE WHEN a.event_id = 'clock' THEN a.kinch_score * 100 END), 2) AS clock,
            ROUND(MAX(CASE WHEN a.event_id = '444bf' THEN a.kinch_score * 100 END), 2) AS `444bf`,
            ROUND(MAX(CASE WHEN a.event_id = '555bf' THEN a.kinch_score * 100 END), 2) AS `555bf`,
            ROUND(MAX(CASE WHEN a.event_id = '333bf' THEN a.kinch_score * 100 END), 2) AS `333bf`,
            ROUND(MAX(CASE WHEN a.event_id = '333fm' THEN a.kinch_score * 100 END), 2) AS `333fm`,
            ROUND(MAX(CASE WHEN a.event_id = '333mbf' THEN a.kinch_score * 100 END), 2) AS `333mbf`
        FROM final f
        JOIN persons p 
        ON p.wca_id = f.person_id AND p.sub_id = 1
        JOIN all_scores a 
        ON a.person_id = f.person_id
        GROUP BY 
            f.person_id, p.name, f.kinch
        ORDER BY kinch DESC;
    SQL
  end
end
