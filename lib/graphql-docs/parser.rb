module GraphQLDocs
  class Parser
    attr_reader :schema

    def initialize(response)
      @schema = JSON.parse(response)['data']
    end

    def parse
      graphql_hash = @schema['__schema']
      # sort the types
      graphql_hash['types'] = graphql_hash['types'].sort_by { |key, _| key['name'] }

      # fetch the connections
      graphql_hash['types'].each do |object|
        next if object['fields'].nil?
        object['connections'] = object['fields'].select { |f| next if f.is_a?(Array); is_connection?(f) }
      end

      # fetch the kinds of items
      # type_kinds = graphql_hash['types'].map { |h| h['kind'] }.uniq
      # type_kinds.each do |kind|
      #   graphql_hash["#{kind.downcase}_types"] = graphql_hash['types'].select { |t| t['kind'] == kind }
      # end
      graphql_hash
    end

    private

    def is_connection?(hash)
      if hash['type']['ofType'] && hash['type']['ofType']['name'] && hash['type']['ofType']['name'].end_with?('Connection')
        true
      else
        false
      end
    end
  end
end
