require_relative "../core/statistic"

class NationalRecordsByPerson < Statistic
  def initialize
    @title = "National records count by person"
    @table_header = { "WRs" => :right, "Person" => :left }
  end

  def query
    <<-SQL
      SELECT
        wrs_count,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link
      FROM (
        SELECT
          personId,
          SUM((IF(regionalSingleRecord = 'NR', 1, 0) + IF(regionalAverageRecord = 'NR', 1, 0))) wrs_count
        FROM Results
        GROUP BY personId
        HAVING wrs_count > 0
      ) AS wrs_count_by_person
      JOIN Persons person ON person.wca_id = personId AND subId = 1 AND person.countryId = 'Poland'
      ORDER BY wrs_count DESC, person.name
    SQL
  end
end
