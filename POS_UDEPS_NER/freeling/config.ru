require 'json'
require 'shellwords'

FREELING_PORT = ENV['FREELING_PORT']

app = lambda do |env|
  return [400, {}, []] unless env['REQUEST_METHOD'] == 'POST'

  body = env['rack.input'].gets&.force_encoding('UTF-8')
  input = JSON.parse(body || '""')
  raise 'Input must be a JSON string' unless input.is_a?(String)

  begin
    file = Tempfile.new('freeling-input')
    file.write(input)
    file.rewind
    result = `analyzer_client localhost:#{FREELING_PORT} < #{file.path}`

    unless ENV['DEBUG'].empty?
      puts input
      puts result
    end
    [200, { 'Content-Type' => 'text/xml' }, [result]]
  ensure
    file.close
    file.unlink
  end
end

run app