$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'nxml'
require 'minitest/spec'
require 'minitest/autorun'

# Receives an XML string and yields it twice: first as is and then in inline form.
# This allows to test same assertions for two forms of XML that should be equivalent (except when space content is relevant).
def xml_variations(xml)
  yield xml
  inline_parse = Nokogiri::XML(xml) do |options|
    options.noblanks
    options.strict.noblanks
  end
  inline = inline_parse.to_xml(indent: 0, save_with: Nokogiri::XML::Node::SaveOptions::NO_DECLARATION).chomp
  yield inline
end