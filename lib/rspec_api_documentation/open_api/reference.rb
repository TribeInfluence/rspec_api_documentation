module RspecApiDocumentation
  module OpenApi
    class Reference < Node
      add_setting :$ref, required: true
    end
  end
end
