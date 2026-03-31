# WCA Statistics [![Build Status](https://travis-ci.org/jonatanklosko/wca_statistics.svg?branch=master)](https://travis-ci.org/jonatanklosko/wca_statistics)

A tool simplifying creation and formatting of various cubing-related statistics.
Travis CI automatically builds and pushes the statistics to GitHub Pages
and they are accessible [here](https://jonatanklosko.github.io/wca_statistics).

## Getting started

Requirements: Ruby and MySQL.

- Clone the repository and cd into it: `git clone https://github.com/jonatanklosko/wca_statistics.git && cd wca_statistics`
- Install third party dependencies: `bundle`
- Run the initialization script: `bin/init.rb`
- If necessary edit the `database.yml` file in the project root directory. It is created by the initialization script and is not stored in the git.
- Download the WCA database: `bin/update_database.rb`

## Notes on Vietnamese statistics
While importing the WCA database (see `bin/update_database.rb`), I only keep the records of Vietnamese competitors' results or results from a Vietnamese competition or results that are regional record in tables `results`, `result_attempts`, `ranks_average`, and `ranks_single`:

```ruby
# 3. Filter out non-Vietnamese results
Helpers.timed_task("Filtering data for Vietnam only") do
    sql_results = <<~SQL
        CREATE TABLE vn_comp_ids AS 
        SELECT id FROM competitions WHERE country_id = 'Vietnam';

        CREATE TABLE results_new AS 
        SELECT * FROM results
        WHERE person_country_id = 'Vietnam'
            OR regional_single_record IN ('WR', 'AfR', 'AsR', 'ER', 'NAR', 'OcR', 'SAR')
            OR regional_average_record IN ('WR', 'AfR', 'AsR', 'ER', 'NAR', 'OcR', 'SAR')
            OR competition_id IN (SELECT id FROM vn_comp_ids);

        CREATE TABLE result_attempts_new AS
        SELECT ra.* FROM result_attempts ra
        INNER JOIN results_new rn ON ra.result_id = rn.id;

        DROP TABLE result_attempts;
        DROP TABLE results;
        DROP TABLE vn_comp_ids;

        ALTER TABLE results_new RENAME TO results;
        ALTER TABLE result_attempts_new RENAME TO result_attempts;
    SQL

    sql_ranks_single = <<~SQL
        DELETE r FROM ranks_single r 
        LEFT JOIN persons p ON r.person_id = p.id AND p.country_id = 'Vietnam' 
        WHERE p.id IS NULL;
    SQL

    sql_ranks_average = <<~SQL
        DELETE r FROM ranks_average r 
        LEFT JOIN persons p ON r.person_id = p.id AND p.country_id = 'Vietnam' 
        WHERE p.id IS NULL;
    SQL

    `#{mysql_with_credentials} #{config["database"]} -e "#{sql_results}" #{filter_out_mysql_warning}`
    `#{mysql_with_credentials} #{config["database"]} -e "#{sql_ranks_single}" #{filter_out_mysql_warning}`
    `#{mysql_with_credentials} #{config["database"]} -e "#{sql_ranks_average}" #{filter_out_mysql_warning}`
end
```

## Scripts

| Script | Description |
| ------ | ----------- |
| `compute.rb` | Computes a single statistics basing on the given statistic file path. |
| `compute_all.rb` | Computes all the statistics. |
| `list.rb` | Lists all the statistics. |
| `init.rb` | Does basic initialization. |
| `new_statistic.rb` | Generates a new statistic. Accepts a filename as an argument. When the `--grouped` flag is appended, generates so-called grouped statistics, which consists of a couple tables (e.g. a list of top 10 competitors for each event). |
| `update_database.rb` | Downloads and imports the WCA database copy. |
