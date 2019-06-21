require 'sinatra'

class App < Sinatra::Base
  get '/orders' do
    content_type "application/vnd.api+json"

    [200, {
      :page => 1,
      :orders => [
        { name: 'Order 1', amount: 9.99, description: nil },
        { name: 'Order 2', amount: 100.0, description: 'A great order' }
      ]
    }.to_json]
  end

  get '/orders/:id' do
    content_type :json

    [200, { order: { name: 'Order 1', amount: 100.0, description: 'A great order' } }.to_json]
  end

  post '/orders' do
    content_type :json

    [201, { order: { name: 'Order 1', amount: 100.0, description: 'A great order' } }.to_json]
  end

  put '/orders/:id' do
    content_type :json

    if params[:id].to_i > 0
      [200, request.body.read]
    else
      [400, ""]
    end
  end

  delete '/orders/:id' do
    200
  end

  get '/instructions' do
    response_body = {
      data: {
        id: "1",
        type: "instructions",
        attributes: {}
      }
    }
    [200, response_body.to_json]
  end
end
