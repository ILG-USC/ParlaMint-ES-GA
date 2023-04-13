$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'benchmark'
require 'nxml'

def build_recursive_doc(times)
  doc = +''
  times.times { doc << '<dir name="name">' }
  times.times { doc << '</dir>' }
  doc
end

puts 'Parse recursive benchmark'

rules = Nxml.root :dir do
  attribute :name
  collection :nested do
    lazy { rules }
  end
end

Benchmark.benchmark(Benchmark::CAPTION, 21) do |x|
  (1..3).each do |exp|
    times = 10 ** exp
    doc = build_recursive_doc(times)
    x.report("Parse #{times} elements") { Nxml.build(rules, doc, &:huge) }
  end
end
