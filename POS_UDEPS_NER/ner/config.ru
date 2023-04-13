require 'tmpdir'
require 'securerandom'
require 'json'

app = lambda do |env|
  return [400, {}, []] unless env['REQUEST_METHOD'] == 'POST'

  body = env['rack.input'].gets&.force_encoding('UTF-8')
  input = JSON.parse(body || '""')
  raise 'Input must be a JSON string' unless input.is_a?(String)

  begin
    file = Tempfile.new('input')
    file.write(input)
    file.rewind
    Dir.mktmpdir(SecureRandom.uuid) do |output_path|
      log = `python run_ner.py --model_name_or_path modelo \\
                               --train_file train.json \\
                               --validation_file dev.json \\
                               --test_file #{file.path} \\
                               --do_predict \\
                               --output_dir #{output_path}`
      output = File.read("#{output_path}/predictions.txt")
      unless ENV['DEBUG'].empty?
        puts '** INPUT **'
        puts input
        puts '** OUTPUT **'
        puts output
        puts '** LOG **'
        puts log
      end
      [200, { 'Content-Type' => 'text/plain' }, [output]]
    end
  ensure
    file.close
    file.unlink
  end
end

run app
