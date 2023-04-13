require 'test_helper'

describe Nxml::Builder do
  module HashConstructor
    def initialize(hash)
      hash.each { |k, v| public_send("#{k}=", v) }
    end
  end

  class Document
    include HashConstructor
    attr_accessor :header, :texts
  end

  class Header
    include HashConstructor
    attr_accessor *%i[corpus subcorpus oral group_produtora group_ano_versión identificador autor área subárea]
  end

  class Text
    include HashConstructor
    attr_accessor *%i[source_text context_id text_section tokens units display_section]
  end

  class Token
    include HashConstructor
    attr_accessor *%i[token tag lemma unit real_position]
  end

  class Unit
    include HashConstructor
    attr_accessor *%i[unit visible_unit real_position ignored]
  end

  it 'should be able to map complex documents' do
    rules = Nxml.root :document, format: ->(r) { Document.new(r) } do
      element :document_header, key: :header, format: ->(r) { Header.new(r) } do
        element_content :corpus
        element_content :subcorpus
        element_content :oral, format: ->(r) { r == 'true' }
        sequence_content :group_produtora
        element_content :group_ano_versión, format: ->(r) { r.to_i }
        sequence_content :autor, format: ->(r) { r.empty? ? nil : r }
        sequence_content :área, format: ->(r) { r.to_i }
        sequence_content :subárea, format: ->(r) { r.to_i }
      end
      element :document_content, key: :texts, format: ->(e) { e[:text] } do
        sequence :text, format: ->(r) { Text.new(r) } do
          element_content :source_text
          element_content :context_id, format: ->(r) { r.to_i }
          element_content :text_section
          element_content :display_section
          element :tokens, format: ->(r) { r[:token] } do
            sequence :token, format: ->(r) { Token.new(r) } do
              element_content :form, key: :token
              element_content :tag
              element_content :lemma
              element_content :unit
              element_content :real_position, format: ->(r) { r.to_i }
            end
          end
          element :units, format: ->(r) { r[:unit_element] } do
            sequence :unit_element, format: ->(r) { Unit.new(r) } do
              element_content :unit_text, key: :unit
              element_content :visible_unit
              element_content :real_position, format: ->(r) { r.to_i }
              element_content :ignored, format: ->(v) { !v.nil? }
            end
          end
        end
      end
    end
    xml_variations(File.read('test/resources/complex_document.xml')) do |xml|
      result = Nxml.build(rules, xml)
      document = result[:document]
      assert_instance_of(Document, document)

      assert_instance_of(Header, document.header)
      assert_equal('CORGA', document.header.corpus)
      assert_equal('etiquetado automaticamente', document.header.subcorpus)
      refute(document.header.oral)
      assert_equal(['', '', ''], document.header.group_produtora)
      assert_equal(2006, document.header.group_ano_versión)
      assert_equal(['Nebot, F.', 'Pino, D.', 'Portela, C.', nil, nil], document.header.autor)
      assert_equal([1, 1, 1], document.header.área)
      assert_equal([2, 5, 1], document.header.subárea)

      text = document.texts.first
      assert_instance_of(Text, text)
      assert_equal('Introducción: condicionantes pra redacción do planeamento no medio rural en Galicia.', text.source_text)
      assert_equal(3, text.context_id)
      assert_equal('encabezamento', text.text_section)
      assert_equal('prólogo', text.display_section)

      assert_instance_of(Token, text.tokens[0])
      assert_equal('introducción', text.tokens[0].token)
      assert_equal('Scfs', text.tokens[0].tag)
      assert_equal('introducción', text.tokens[0].lemma)
      assert_equal('Introducción', text.tokens[0].unit)
      assert_equal(1, text.tokens[0].real_position)

      assert_instance_of(Token, text.tokens[1])
      assert_equal(':', text.tokens[1].token)
      assert_equal('Q:', text.tokens[1].tag)
      assert_equal(':', text.tokens[1].lemma)
      assert_equal(':', text.tokens[1].unit)
      assert_equal(2, text.tokens[1].real_position)

      assert_instance_of(Unit, text.units[0])
      assert_equal('Introducción', text.units[0].unit)
      assert_equal('Introducción', text.units[0].visible_unit)
      assert_equal(1, text.units[0].real_position)
      assert_nil(text.units[0].ignored)

      assert_instance_of(Unit, text.units[1])
      assert_nil(text.units[1].unit)
      assert_equal(':', text.units[1].visible_unit)
      assert_equal(2, text.units[1].real_position)
      assert(text.units[1].ignored)
    end
  end
end