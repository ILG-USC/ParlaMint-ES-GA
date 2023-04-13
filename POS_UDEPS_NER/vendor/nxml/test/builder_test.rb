require 'test_helper'

describe Nxml::Builder do
  it 'should extract inner_xml by default' do
    rules = Nxml.root :text do
      content :content
    end
    doc = <<~XML
      <text>
        <b>xml</b>
      </text>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      assert_equal('<b>xml</b>', result[:text][:content].strip)
    end
  end

  it 'the inner_xml returned should be utf-8 without encoded characters' do
    rules = Nxml.root :text do
      content :content
    end
    doc = <<~XML
      <text>
        <ruido tipo="sonándose">&#x40;</ruido>
      </text>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      assert_equal('<ruido tipo="sonándose">@</ruido>', result[:text][:content].strip)
    end
  end

  it 'content should extract empty string from self-closing elements' do
    rules = Nxml.root :text do
      element_content :value
    end
    doc = <<~XML
      <text><value/></text>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      assert_equal('', result[:text][:value])
    end
  end

  it 'element rules should work despite of blanks or line breaks' do
    rules = Nxml.root :text do
      element_content :header
      element_content :body
    end
    doc = <<~XML
      <text>

         <header>header</header>

         <body>body</body>

       </text>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        text: {
          header: 'header',
          body: 'body'
        }
      }
      assert_equal(expected, result)
    end
  end

  it 'element rule should store the latest element if there are several' do
    rules = Nxml.root :text do
      element_content :b
    end
    doc = <<~XML
      <text>
        <b>0</b>
        <b>1</b>
       </text>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      assert_equal('1', result[:text][:b])
    end
  end

  it 'should work with namespaced elements' do
    rules = Nxml.root :text do
      element_content :'a:header'
      element_content :'a:body'
    end
    doc = <<~XML
      <text xmlns:a="schema">
        <a:header>header</a:header>
        <a:body>body</a:body>
      </text>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        text: {
          'a:header': 'header',
          'a:body': 'body'
        }
      }
      assert_equal(expected, result)
    end
  end

  it 'key option should be used instead of name if given' do
    rules = Nxml.root :texto, key: :text do
      attribute :tipo, key: :type
      element_content :cabecera, key: :header
      element_content :cuerpo, key: :body
    end
    doc = <<~XML
      <texto tipo="escrito">
        <cabecera>header</cabecera>
        <cuerpo>body</cuerpo>
      </texto>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        text: {
          type: 'escrito',
          header: 'header',
          body: 'body'
        }
      }
      assert_equal(expected, result)
    end
  end

  it 'collection should store any element defined inside' do
    rules = Nxml.root :root do
      collection :texts do
        element_content :a
        element_content :b
      end
    end
    doc = <<~XML
      <root>
        <a>One</a>
        <b>Two</b>
        <c>Three</c>
      </root>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        root: {
          texts: %w[One Two]
        }
      }
      assert_equal(expected, result)
    end
  end

  it 'collection should include self-closing elements' do
    rules = Nxml.root :root do
      collection :texts do
        element_content :a
      end
    end
    doc = <<~XML
      <root>
        <a>One</a>
        <a/>
        <a>Two</a>
      </root>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        root: {
          texts: ['One', '', 'Two']
        }
      }
      assert_equal(expected, result)
    end
  end

  it 'collection should ignore nested elements equal to the collected item' do
    rules = Nxml.root :root do
      collection :texts do
        element_content :text
      end
    end
    doc = <<~XML
      <root>
        <text>One</text>
        <text><text>Two</text></text>
      </root>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      assert_equal(%w[One <text>Two</text>], result[:root][:texts])
    end
  end

  it 'sequence should read only defined elements and ignore everything else' do
    rules = Nxml.root :root do
      sequence :el do
        attribute :name
      end
    end
    doc = <<~XML
      <root>
        <el name="A"></el>
        <nope name="B"></nope>
        <el name="C"></el>
        <nope name="D"></nope>
      </root>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        root: {
          el: [
            { name: 'A' },
            { name: 'C' }
          ]
        }
      }
      assert_equal(expected, result)
    end
  end

  it 'sequence :key parameter should be applied to collection' do
    rules = Nxml.root :root do
      sequence :el, key: :list do
        attribute :name
      end
    end
    doc = <<~XML
      <root>
        <el name="A"></el>
        <el name="C"></el>
      </root>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        root: {
          list: [
            { name: 'A' },
            { name: 'C' }
          ]
        }
      }
      assert_equal(expected, result)
    end
  end

  it 'sequence_content should read only defined elements content and ignore everything else' do
    rules = Nxml.root :root do
      sequence_content :el
    end
    doc = <<~XML
      <root>
        <el>A</el>
        <nope>B</nope>
        <el>C</el>
        <nope>D</nope>
      </root>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = { root: { el: %w[A C] } }
      assert_equal(expected, result)
    end
  end

  it 'sequence_content :key parameter should be applied to collection' do
    rules = Nxml.root :root do
      sequence_content :el, key: :list
    end
    doc = <<~XML
      <root>
        <el>A</el>
        <el>C</el>
      </root>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = { root: { list: %w[A C] } }
      assert_equal(expected, result)
    end
  end

  it 'should read attributes the same as properties' do
    rules = Nxml.root :text do
      attribute :title
    end
    doc = <<~XML
      <text title="first"/>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      assert_equal({ text: { title: 'first' } }, result)
    end
  end

  it 'if attributes and content are provided, content will be stored the same as a property' do
    rules = Nxml.root :text do
      attribute :title
      attribute :tag
      content :content
    end
    doc = <<~XML
      <text title="first" tag="second">
        content
      </text>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        text: {
          title: 'first',
          tag: 'second',
          content: 'content'
        }
      }
      result[:text][:content].strip!
      assert_equal(expected, result)
    end
  end

  it 'should format content if :format option is a proc or lambda' do
    rules = Nxml.root :text do
      content :content, format: ->(e) { e.to_i }
    end
    doc = <<~XML
      <text>0</text>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      assert_equal(0, result[:text][:content])
    end
  end

  it 'format lambda should be able to use variables in the scope that it was defined' do
    to_integer = ->(e) { e.to_i }
    rules = Nxml.root :text do
      content :content, format: ->(e) { to_integer.call(e) }
    end
    doc = <<~XML
      <text>0</text>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      assert_equal(0, result[:text][:content])
    end
  end

  it 'should store elements without definition in default rule unless they are in except list' do
    rules = Nxml.root :list do
      default :default, except: %i[b] do
        content :content
      end
    end
    doc = <<~XML
      <list>
        <a>1</a>
        <b>2</b>
        <c>3</c>
      </list>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        list: {
          default: [
            { content: '1' },
            { content: '3' },
          ]
        }
      }
      assert_equal(expected, result)
    end
  end

  it 'should be able to parse recursive structures using lazy rules' do
    rules = Nxml.root :dir do
      attribute :name
      collection :nested do
        lazy { rules }
      end
    end
    doc = <<~XML
      <dir name="root">
        <dir name="dir1"/>
        <dir name="dir2">
          <dir name="sub-dir"/>
        </dir>
      </dir>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      expected = {
        dir: {
          name: 'root',
          nested: [
            { name: 'dir1' },
            {
              name: 'dir2',
              nested: [
                { name: 'sub-dir' }
              ]
            }
          ]
        }
      }
      assert_equal(expected, result)
    end
  end

  it 'should extract text nodes that are directly inside an element keeping last if there are several' do
    rules = Nxml.root :text do
      text(:numbers, format: ->(l) { l.to_i })
    end
    doc = <<~XML
      <text>0<b>1</b>2</text>
    XML

    result = Nxml.build(rules, doc)
    assert_equal(2, result[:text][:numbers])
  end

  it 'should extract text nodes in order when they are inside a collection' do
    rules = Nxml.root :text do
      collection :numbers do
        element_content :b
        text(:text, format: ->(l) { l.to_i })
      end
    end
    doc = <<~XML
      <text>0<b>1</b>2</text>
    XML
    xml_variations(doc) do |xml|
      result = Nxml.build(rules, xml)
      assert_equal([0, '1', 2], result[:text][:numbers])
    end
  end
end