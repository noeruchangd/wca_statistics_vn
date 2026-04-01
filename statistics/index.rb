STATISTICS = {}

def camelize(str)
  str.split('_').map(&:capitalize).join
end

Dir["#{__dir__}/*.rb"].each do |file|
  require file
  basename = File.basename(file, ".rb")
  class_name = camelize(basename)
  begin
    STATISTICS[basename] = Module.const_get(class_name).new
  rescue NameError
    warn "Class #{class_name} not defined in #{file}"
  end
end