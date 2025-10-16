#!/usr/bin/env ruby

require_relative "../statistics/index"

# Generate statistics index.
puts "Computing statistics index."
build_path = File.expand_path("../build", __dir__)

list = STATISTICS
  .sort_by { |statistics_id, statistic_object| statistic_object.title.gsub(/\d+/) { |number| number.rjust(10, "0") } }
  .map { |statistics_id, statistic_object| "- [#{statistic_object.title}](#{statistics_id})\n" }
  .join

destination_path = File.join(build_path, "README.md")
File.write(destination_path, ("All statistics are computed only for competitors from Vietnam/Vietnamese competitions.\n\n" + list))
puts "File generated at #{destination_path}"
