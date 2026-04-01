require_relative "statistic"

class GroupedStatistic < Statistic
  def markdown
    markdown = top
    data.each do |header, subdata|
      unless subdata.empty?
        # markdown += "\n### #{header}\n\n"
        # markdown += markdown_table(@table_header, subdata)

        header_with_index_column = { "#" => :right }.merge(@table_header)
        data_with_index_column = subdata.map.with_index(1) do |row, index|
          [index] + row
        end
        # top + markdown_table(@table_header, data)
        markdown += "\n### #{header}\n\n"
        markdown += markdown_table(header_with_index_column, data_with_index_column)
      end
    end
    markdown
  end
end
