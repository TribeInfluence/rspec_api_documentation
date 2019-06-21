require "rspec_api_documentation"
require "rspec_api_documentation/dsl"

RspecApiDocumentation.configure do |config|
  config.app = App
  config.api_name = "Example API"
  config.format = :open_api
  config.configurations_dir = "."
  config.request_body_formatter = :json
  config.request_headers_to_include = %w[Content-Type Host]
  config.response_headers_to_include = %w[Content-Type Content-Length]
end

resource 'Orders' do
  explanation "Orders resource"

  get '/orders' do
    route_summary "This URL allows users to interact with all orders."
    route_description "Long description."

    parameter :one_level_array, type: :array, items: {type: :string, enum: ['string1', 'string2']}, default: ['string1']
    parameter :two_level_array, type: :array, items: {type: :array, items: {type: :string}}

    parameter :one_level_arr, with_example: true
    parameter :two_level_arr, with_example: true

    let(:one_level_arr) { ['value1', 'value2'] }
    let(:two_level_arr) { [[5.1, 3.0], [1.0, 4.5]] }

    example_request 'Getting a list of orders' do
      expect(status).to eq(200)
      expect(response_body).to eq('{"page":1,"orders":[{"name":"Order 1","amount":9.99,"description":null},{"name":"Order 2","amount":100.0,"description":"A great order"}]}')
    end
  end

  post '/orders' do
    route_summary "This is used to create orders."

    header "Content-Type", "application/json"

    parameter :name, scope: :data, with_example: true, default: 'name'
    parameter :description, scope: :data, with_example: true
    parameter :amount, scope: :data, with_example: true, minimum: 0, maximum: 100
    parameter :values, scope: :data, with_example: true, enum: [1, 2, 3, 5]

    example 'Creating an order' do
      request = {
        data: {
          name: "Order 1",
          amount: 100.0,
          description: "A description",
          values: [5.0, 1.0]
        }
      }
      do_request(request)
      expect(status).to eq(201)
    end
  end

  get '/orders/:id' do
    route_summary "This is used to return orders."
    route_description "Returns a specific order."

    let(:id) { 1 }

    example_request 'Getting a specific order' do
      expect(status).to eq(200)
      expect(response_body).to eq('{"order":{"name":"Order 1","amount":100.0,"description":"A great order"}}')
    end
  end

  put '/orders/:id' do
    route_summary "This is used to update orders."

    parameter :name, 'The order name', required: true, scope: :data, with_example: true
    parameter :amount, required: false, scope: :data, with_example: true
    parameter :description, 'The order description', required: false, scope: :data, with_example: true

    header "Content-Type", "application/json"

    context "with a valid id" do
      let(:id) { 1 }

      example 'Update an order' do
        request = {
          data: {
            name: 'order',
            amount: 1,
            description: 'fast order'
          }
        }
        do_request(request)
        expected_response = {
          data: {
            name: 'order',
            amount: 1,
            description: 'fast order'
          }
        }
        expect(status).to eq(200)
        expect(response_body).to eq(expected_response.to_json)
      end
    end

    context "with an invalid id" do
      let(:id) { "a" }

      example_request 'Invalid request' do
        expect(status).to eq(400)
        expect(response_body).to eq("")
      end
    end
  end

  delete '/orders/:id' do
    route_summary "This is used to delete orders."

    let(:id) { 1 }

    example_request "Deleting an order" do
      expect(status).to eq(200)
      expect(response_body).to eq('')
    end
  end
end

resource 'Instructions' do
  explanation 'Instructions help the users use the app.'

  get '/instructions' do
    route_summary 'This should be used to get all instructions.'

    example_request 'List all instructions' do
      expected_response = {
        data: {
          id: "1",
          type: "instructions",
          attributes: {}
        }
      }
      expect(status).to eq(200)
      expect(response_body).to eq(expected_response.to_json)
    end
  end
end