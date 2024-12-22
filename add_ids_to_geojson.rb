require 'json'
require 'colorize'

if ARGV.length != 1
  puts "Too many arguments, only 1 authorized.".red
  puts "Usage: ruby script.rb <FilePath>".red
  exit
end

file_path = ARGV[0];

unless File.exist?(file_path)
  puts "Error: can't find any file with path: #{file_path}".red
  exit
end

begin
  puts "Start parsing geojson ..."

  file_content = File.read(file_path)
  json_datas = JSON.parse(file_content)

  curr_id = 0;

  json_datas['features'].each_with_index do |entry, idx|
    geometry = entry['geometry']
    type = geometry['type']
      
    coord_f = []
    if type == 'Polygon'
      geometry['coordinates'].each do |path|
        coord_f << { id: curr_id, path: path }
        curr_id+=1
      end
      geometry['coordinates'] = coord_f
    elsif type == 'MultiPolygon'
      geometry['coordinates'].each do |polygon|
        coord_f << polygon.map do |path|
          new = { id: curr_id, path: path }
          curr_id+=1;
          new
        end
      end
    end

    geometry['coordinates'] = coord_f
  end


  modified_content = JSON.generate(json_datas)
  # File.open('output.json', 'w') do |file|
  File.open(file_path, 'w') do |file|
    file.write(modified_content);
  end
  
  puts "Successfuly add id to all geojson entries !".green

rescue JSON::ParserError
  puts "Error: Unvalid JSON for #{file_path}".red
rescue => error
  puts "Error: Innately error happens:\n#{error}".red
end

