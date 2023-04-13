require 'test_helper'

describe Nxml::Builder do
  it 'Self closing elements must not be taken into account when skipping an element subtree' do
    rules = Nxml.root :text do
      element_content :after
    end
    doc = <<~XML
      <text>
        <!-- This element will be skipped, since there is no rule for it -->
        <unit>
          <!-- 
            When skipping <unit> subtree, we must not count this element as a new depth level.
            If we count it as a new depth level causes that the reader reaches the end of the document without applying new rules.
            This is due the level being > 0 when we reach the end of subtree (</unit>). Builder will treat it as if it were a nested </unit>.
          -->   
          <self_closing/>
        </unit>
        <after>After</after>
      </text>
    XML
    result = Nxml.build(rules, doc)
    expected = { text: { after: 'After' } }
    assert_equal(expected, result)
  end

  it 'should not apply nested rules if element is self-closing' do
    rules = Nxml.root :root do
      collection :list do
        element :el do
          attribute :name
          element_content :el
        end
      end
    end
    doc = <<~XML
      <root>
        <el name="A">
          <el>1</el>
        </el>
        <el name="B"/>
        <el name="C">
          <el>2</el>
        </el>
      </root>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        root: {
          list: [
            { name: 'A', el: '1' },
            { name: 'B' },
            { name: 'C', el: '2' }
          ]
        }
      }
      assert_equal(expected, result)
    end
  end

  it 'When reaching the end of an element (</list>) builder must not advance, it must continue to apply outer schema' do
    rules = Nxml.root :r do
      element :list do
        element_content :a
      end
      element_content :b
    end
    doc = '<r><list>
             <a>1</a>
             </list><b>2</b></r>'
    result = Nxml.build(rules, doc)
    expected = {
      r: {
        list: {
          a: '1'
        },
        b: '2'
      }
    }
    assert_equal(expected, result)
  end
end