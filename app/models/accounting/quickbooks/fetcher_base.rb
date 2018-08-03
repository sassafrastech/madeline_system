module Accounting
  module Quickbooks
    class FetchError < StandardError; end

    # This class is responsible for batching up Quickbooks API calls into separate types.
    # The API does support batch requests for queries, but quickbooks-ruby does not.
    class FetcherBase
      attr_reader :qb_connection

      def initialize(division)
        @qb_connection = division.qb_connection
      end

      def fetch
        types.each do |type|
          results = service(type).all || []
          results.each do |qb_object|
            find_or_create(qb_object_type: type, qb_object: qb_object)
          end
        end
      end

      private

      def find_or_create(qb_object_type:, qb_object:)
        raise NotImplementedError
      end

      def types
        raise NotImplementedError
      end

      def service(type)
        ::Quickbooks::Service.const_get(type).new(@qb_connection.auth_details)
      end
    end
  end
end
