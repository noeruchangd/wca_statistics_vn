require "time"
require_relative "database"

class Statistic
  attr_reader :title

  def query
    raise "Must implement #query"
  end

  def query_results
    Database.client.query(query)
  end

  def transform(query_results)
    query_results.each(as: :array)
  end

  def data
    @data ||= transform(query_results)
  end

  def top
    timestamp = Time.parse(Database.metadata["export_timestamp"])

    markdown = "## #{@title}\n\n"
    markdown += "*Note: #{@note}*\n" if @note
    markdown + timestamp.strftime("*Updated on %e %B %Y*\n\n")
  end

  def markdown
    header_with_index_column = { "#" => :right }.merge(@table_header)
    data_with_index_column = data.map.with_index(1) do |row, index|
      [index] + row
    end
    # top + markdown_table(@table_header, data)
    top + markdown_table(header_with_index_column, data_with_index_column)
  end

  def markdown_table(header, data)
    table = "| #{header.keys.join(' | ')} |\n"
    alignments = { left: ":---", center: ":--:", right: "---:" }
    table += "| #{header.values.map { |alignment| alignments[alignment] }.join(' | ')} |\n"
    data.each do |row|
      table += "| #{row.join(' | ')} |\n"
    end
    table
  end
end
