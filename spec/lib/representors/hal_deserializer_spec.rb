require 'spec_helper'

describe Representors::HalDeserializer do
  subject(:deserializer) {Representors::HalDeserializer.new(document)}
  let(:semantics_field) {deserializer.to_representor.attributes}
  let(:transitions_field) {deserializer.to_representor.transitions}
  let(:embedded_field) {deserializer.to_representor.embedded }

  it "initializes with a JSON document" do
    expect(Representors::HalDeserializer.new({}.to_json)).to be_instance_of (Representors::HalDeserializer)
  end

  describe "#to_representor" do

    context "empty document" do
      let(:document) { {}.to_json }

      it "returns a hash with no attributes, links or embedded resources" do
        expect(deserializer.to_representor.attributes).to be_empty
        expect(deserializer.to_representor.transitions).to be_empty
        expect(deserializer.to_representor.embedded).to be_empty
      end
    end

    context 'Document with only properties' do
      let(:original_hash) do
        {
          'title' => 'The Neverending Story',
          'author' => 'Michael Ende',
          'pages' => '396'
        }
      end
      let(:document) { original_hash.to_json}

      it 'return a representor with all the attributes of the document' do
        expect(semantics_field).to eq(original_hash)
      end

    end

    context 'Document with properties and links' do
      let(:semantics) { { 'title' => 'The Neverending Story'}}
      let(:transition_rel) { 'author'}
      let(:transition_href) { '/mike'}
      let(:document) do
        {
          'title' => 'The Neverending Story',
          '_links' => {
            'author' => {'href' => '/mike'}
          }
        }
      end

      it 'return a hash with all the attributes of the document' do
        expect(semantics_field).to eq(semantics)
      end
      it 'Create a transition with the link' do
        expect(transitions_field.first.rel).to eq(transition_rel)
        expect(transitions_field.first.uri).to eq(transition_href)
      end
      it 'does not return any embedded resource' do
        expect(embedded_field).to be_empty
      end

    end

    context 'Document with properties, links and embedded' do
      let(:semantics) { { 'title' => 'The Neverending Story'}}
      let(:transition_rel) { 'author'}
      let(:transition_href) { '/mike'}
      let(:embedded_book) { {'content' => 'A...'} }
      let(:document) do
        {
          'title' => 'The Neverending Story',
          '_links' => {
            transition_rel => {'href' => transition_href}
          },
          '_embedded' => {
            'embedded_book' => embedded_book
          }
        }
      end
      it 'Returns a hash with all the attributes of the document' do
        expect(semantics_field).to eq(semantics)
      end
      it 'Creates a transition with the link' do
        expect(transitions_field.first.rel).to eq(transition_rel)
        expect(transitions_field.first.uri).to eq(transition_href)
      end

      it 'Creates an embedded resource with its data' do
        expect(embedded_field['embedded_book'].attributes).to eq(embedded_book)
      end
    end


    context 'Document with an embedded collection' do
      let(:embedded_book1) { {'content' => 'A...'} }
      let(:embedded_book2) { {'content' => 'When...'} }
      let(:embedded_book3) { {'content' => 'Once upon...'} }
      let(:embedded_books) { [ embedded_book1, embedded_book2, embedded_book3 ] }
      let(:document) do
        {
          '_embedded' => {
            'embedded_books' => [ embedded_book1, embedded_book2, embedded_book3 ]
          }
        }
      end

      it 'Creates three embedded resources' do
        expect(embedded_field['embedded_books']).to have(embedded_books.size).items
      end

      it 'Creates embedded resources with its data' do
        embedded_books.each_with_index do |item, index|
          expect(embedded_field['embedded_books'][index].attributes).to eq(item)
        end
      end
    end

    context 'Document with only a self link and a title' do
      let(:href) { '/example_resource'}
      let(:title) { 'super!'}
      let(:document) do
        { '_links' => {
          'self' => { 'href' => href, 'title' => title}
          }
        }
      end

      it 'the transition has a "self" rel' do
        expect(transitions_field.first.rel).to eq('self')
      end

      it 'The transition has its href set properly' do
        expect(transitions_field.first.uri).to eq(href)
      end

      it 'The transition has a title' do
        expect(transitions_field.first['title']).to eq(title)
      end

    end

    context 'Document with an array of two links under items' do
      let(:first_href) {'/example_resource'}
      let(:second_href) {'/lotr_resource2'}
      let(:rel) { 'items'}
      let(:document) do
        { '_links' => {
            rel => [{ 'href' => first_href, 'title' => 'resource1'},
                       { 'href' => second_href, 'title' => 'resource2'}]
          }
        }
      end

      it 'The representor has two links' do
        expect(transitions_field).to have(2).items
      end

      it 'The transitions have a rel properly set' do
        expect(transitions_field.all?{|link| link.rel == 'items'}).to be_true
      end

      it 'The transitions have a href properly set ' do
        expect(transitions_field[0].uri).to eq(first_href)
        expect(transitions_field[1].uri).to eq(second_href)
      end
    end

    context 'Document with a link without a href' do
      let(:document) do
        { '_links' => {
          'self' => { 'title' => 'things'}
          }
        }
      end

      it 'raises a DeserializationError' do
        expect{transitions_field}.to raise_error(Representors::DeserializationError, "All links must contain the href attribute")
      end
    end

    context 'Document where not all links have href' do
      let(:link_properties) { { 'href' => '/example_resource'} }
      let(:document) do
        { '_links' => {
            'items' => [{ 'title' => 'resource1'},
                       { 'href' => '/example_resource2', 'title' => 'resource2'}]
          }
        }
      end

      it 'raises a DeserializationError' do
        expect{transitions_field}.to raise_error(Representors::DeserializationError, "All links must contain the href attribute")
      end
    end

    context 'Document with CURIEs' do
      let(:link_properties) { { 'href' => '/example_resource'} }
      let(:document) do
        { '_links' => {
          'curies' => { 'href' => '/example_resource'}
          }
        }
      end

      it 'raises a DeserializationError' do
        expect{transitions_field}.to raise_error(Representors::DeserializationError, "CURIE support not implemented for HAL")
      end
    end

  end
end
