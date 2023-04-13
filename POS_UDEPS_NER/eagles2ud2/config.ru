require 'json'
require 'shellwords'

app = lambda do |env|
  return [400, {}, []] unless env['REQUEST_METHOD'] == 'POST'

  body = env['rack.input'].gets&.force_encoding('UTF-8')
  input = JSON.parse(body || '""')
  raise 'Input must be a JSON string' unless input.is_a?(String)

  begin
    file = Tempfile.new('input')
    file.write(input)
    file.rewind
    result = `perl eagles2UD2.pl -f -g -j < #{file.path}`

    unless ENV['DEBUG'].empty?
      puts input
      puts result
    end
    [200, { 'Content-Type' => 'text/tsv' }, [result]]
  ensure
    file.close
    file.unlink
  end
end

run app
