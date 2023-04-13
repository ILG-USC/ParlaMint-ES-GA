$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'benchmark'
require 'nxml'

def build_sequence_doc(times)
  doc = +'<root>'
  times.times do
    doc << <<~XML
      <el name="name">
        <content>value</content>
      </el>
    XML
  end
  doc << '</root>'
  doc
end

puts 'Parse collection benchmark'

rules = Nxml.root :root do
  collection :list do
    element :el do
      attribute :name
      element_content :content
    end
  end
end

Benchmark.benchmark(Benchmark::CAPTION, 21) do |x|
  (1..6).each do |exp|
    times = 10 ** exp
    doc = build_sequence_doc(times)
    x.report("Parse #{times} elements") { Nxml.build(rules, doc) }
  end
end
