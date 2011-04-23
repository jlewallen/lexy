
node[:java_properties].each do |path, data|
  raw = data.map { |k, v| k + "=" + v }.join("\n")
  directory File.dirname(path)
  file "#{path}" do
    content raw
  end
end
