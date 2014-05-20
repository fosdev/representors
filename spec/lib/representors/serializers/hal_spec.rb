require 'spec_helper'
require 'yaml'
require 'uri'

module Representors
  describe Representor do
    before do
      @minimum_valid_document = {}
      @self_reference = {
        transitions: [{
              rel: 'self',
              href: "/example_resource"
            }]
        }
      @next_reference = {
        transitions: [{
              rel: 'next',
              href: "/page=2"
            }]
        }
      @link_items = {
        embedded: {
          items: [{
          transitions: [{
              rel: 'self',
              href: "/first_item"
            }
          ]
        },{
          transitions: [{
              rel: 'self',
              href: "/second_item"
            }
          ]
        }]}
      }

      @semantics = {
        semantics: {
          total: { value: 30.00 },
          currency: { value: "USD" },
          status: { value: "shipped" }
        },
      }

      @embedded = {
        embedded: {
          orders: [
          {
            transitions: [{
              rel: 'self',
              href: "/orders/123" },{
              rel: 'basket',
              href: "/baskets/98712" },{
              rel: 'customer',
              href: "/customers/7809" }
            ],
            semantics: {
              total: { value: 30.00 },
              currency: { value: "USD" },
              status: { value: "shipped" }
            },
          },{
            transitions: [{
              rel: 'self',
              href: "/orders/124" },{
              rel: 'basket',
              href: "/baskets/97213" },{
              rel: 'customer',
              href: "/customers/12369" }
            ],
            semantics: {
              total: { value: 20.00 },
              currency: { value: "USD" },
              status: { value: "processing" }
            },
          },
        ]}
      }

      #TODO: Curies
      @complex_doc = {
        transitions: [{
          rel: 'self',
          href: "/orders" },{
          rel: 'next',
          href: "/orders?page=2" },{
          rel: 'find',
          href: "/orders",
          descriptors: {
            id: {
              scope: 'url',
            },
          }
          },{
           rel: 'admin', #IMPOSSIBLE with current Descriptor
           href: "/admins/2",
          }
        ],
        semantics: {
          currentlyProcessing: {value: 14},
          shippedToday: {value: 20},
        },
        embedded: {
          orders: [ {
            transitions: [{
              rel: 'self',
              href: "/orders/123" },{
              rel: 'basket',
              href: "/baskets/98712" },{
              rel: 'customer',
              href: "/customers/7809" }
            ],
            semantics: {
               total: { value: 30.00 },
               currency: { value: "USD" },
               status: { value: "shipped" }
               },
          }, {
            transitions: [{
              rel: 'self',
              href: "/orders/124" },{
              rel: 'basket',
              href: "/baskets/97213" },{
              rel: 'customer',
              href: "/customers/12369" }
            ],
            semantics: {
              total: { value: 20.00 },
              currency: { value: "USD" },
              status: { value: "processing" }
            },
          }
        ] }
      }

      @non_contrived = {}
      @media = 'application/hal+json'

      def assert_serialization(subject, object, options={})
        expect(subject.to_media_type(@media, options)).to eq(object)
      end
    end

    let(:representor_hash) { @representor_hash || @complex_doc }
    let(:subject) { Representor.new(representor_hash) }
    let(:media) {@media}
    let(:assert_serialization) {assert_serialization}

    describe '.to_media_type(%s)' % @media do
      it 'returns a Hash' do
        @representor_hash = @minimum_valid_document
        assert_serialization(subject, {})
      end
    end

    context 'when it has a self link' do
      describe '.to_media_type(%s)' % @media do
        it 'returns a valid serialization of the self link' do
          @representor_hash = @self_reference
          hal_serialization = {
            _links: {
              'self' => {
                href: "/example_resource"
              }
            }
          }
          assert_serialization(subject, hal_serialization)
        end
      end
    end

    context 'when it has an non-self link' do
      describe '.to_media_type(%s)' % @media do
        it 'returns a valid serialization of the link' do
          @representor_hash = @next_reference
          hal_serialization = {
            _links: {
              'next' => {
                href: "/page=2"
              }
            }
          }
          assert_serialization(subject, hal_serialization)
        end
      end
    end

    context 'when getting embedded links' do
      describe '.to_media_type(%s)' % @media do
        it 'returns a valid serialization of the embedded links' do
          @representor_hash = @link_items
          hal_serialization = {
            _links: {
              items: [{
                href: "/first_item"
              },{
                href: "/second_item"
              }]
            }
          }
          assert_serialization(subject, hal_serialization, {link_only: :items})
        end
      end
    end

     context 'when serializing semantic elements' do
      describe '.to_media_type(%s)' % @media do
        it 'returns a valid serialization of the semantic elements' do
          @representor_hash = @semantics
          hal_serialization = {
            total: 30.00 ,
            currency: "USD" ,
            status: "shipped"
          }
          assert_serialization(subject, hal_serialization)
        end
      end
    end

    context 'when serializing with embedded objects' do
      describe '.to_media_type(%s)' % @media do
        it 'returns a valid serialization of the embedded objects' do
          @representor_hash = @embedded
          hal_serialization = {
            _links: {
              'orders' => [
                {:href=>"/orders/123"},
                {:href=>"/orders/124"}
              ]
            },
            _embedded: {orders: [
              {
                _links: {
                  'self' => { href: "/orders/123" },
                  'basket' => { href: "/baskets/98712" },
                  'customer' => { href: "/customers/7809" }
                },
                total: 30.00,
                currency: "USD",
                status: "shipped"
              },{
                _links: {
                  'self' => { href: "/orders/124" },
                  'basket' => { href: "/baskets/97213" },
                  'customer' => { href: "/customers/12369" }
                },
                total: 20.00,
                currency: "USD" ,
                status: "processing"
              },
            ]}
          }

          assert_serialization(subject, hal_serialization)
        end
      end
    end

    context 'when serializing with embedded objects' do
      describe '.to_media_type(%s)' % @media do
        it 'returns a valid serialization of the embedded objects' do
          @representor_hash = @complex_doc
          hal_serialization = {
            _links: {
              self: { href: "/orders" },
              next: { href: "/orders?page=2" },
              find: {
                  href: "/orders{?id}",
                  templated: true
              },
              admin: { href: "/admins/2" },
              orders:[
                {:href=>"/orders/123"},
                {:href=>"/orders/124"}
              ]
            },
            currentlyProcessing: 14,
            shippedToday: 20,
            _embedded: {orders: [
                {
                  _links: {
                    self: { href: "/orders/123" },
                    basket: { href: "/baskets/98712" },
                    customer: { href: "/customers/7809" }
                  },
                  total: 30.00 ,
                  currency: "USD",
                  status: "shipped"
                }, {
                  _links: {
                    self: { href: "/orders/124" },
                    basket: { href: "/baskets/97213" },
                    customer: { href: "/customers/12369" }
                  },
                  total: 20.00,
                  currency: "USD" ,
                  status: "processing"
                }
              ]}
          }

          assert_serialization(subject, hal_serialization)
        end
      end
    end

  end
end


# shared_example
# it 'returns the serialized object'
# expects(subject.to_media_type(@media, options)).to eq(object)
# end
# end
#
# describe '#to_media_type'
# context 'when document has self link'
# before do
# @representor_hash = {...}
# @expected_hash = {...}
# end
#
# it_behaves_like 'a serialized object'
# end
# end


