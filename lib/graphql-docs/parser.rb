module GraphQLDocs
  class Parser
    attr_reader :schema, :processed_schema

    def initialize(response, options)
      @options = options
      @schema = JSON.parse(response)['data']
      @processed_schema = @schema.dup['__schema']
    end

    def parse
      # sort the types
      @processed_schema['types'] = @processed_schema['types'].sort_by { |key, _| key['name'] }

      # fetch the connections
      @processed_schema['types'].each do |object|
        next if object['fields'].nil?
        object['connections'] = object['fields'].select { |f| next if f.is_a?(Array); connection?(f) }
      end

      # fetch the kinds of items
      type_kinds = @processed_schema['types'].map { |h| h['kind'] }.uniq
      type_kinds.each do |kind|
        @processed_schema["#{kind.downcase}_types"] = @processed_schema['types'].select { |t| t['kind'] == kind }
      end
      mutation_types = @processed_schema['object_types'].select do |t|
        t['name'] == 'Mutation'
      end

      @processed_schema['mutation_types'] = if mutation_types.empty?
                                              []
                                            else
                                              @processed_schema['mutation_types'] = mutation_types.first['fields']
                                            end

      # TODO: should the 'types' key be deleted now?

      @processed_schema
    end

    private

    def connection?(hash)
      if hash['type']['ofType'] && hash['type']['ofType']['name'] && hash['type']['ofType']['name'].end_with?('Connection')
        true
      else
        false
      end
    end
  end
end
