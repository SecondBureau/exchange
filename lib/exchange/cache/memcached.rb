module Exchange
  module Cache
    # @author Beat Richartz
    # A class that cooperates with the memcached gem to cache the data from the exchange api in memcached
    # 
    # @version 0.1
    # @since 0.1
    # @example Activate caching via memcache by setting the cache in the configuration to :memcached
    #   Exchange::Configuration.define do |c| 
    #     c.cache = :memcached
    #     c.cache_host = 'Your memcached host' 
    #     c.cache_port = 'Your memcached port'
    #   end
    class Memcached < Base
      class << self
        
        # instantiates a memcached client and memoizes it in a class variable.
        # Use this client to access memcached data. For further explanation of use visit the memcached gem documentation
        # @example
        #   Exchange::Cache::Memcached.client.set('FOO', 'BAR')
        # @return [::Memcached] an instance of the memcached client gem class
        
        def client
          @@client ||= ::Memcached.new("#{Configuration.cache_host}:#{Configuration.cache_port}")
        end
        
        # returns either cached data from the memcached client or calls the block and caches it in memcached.
        # This method has to be the same in all the cache classes in order for the configuration binding to work
        # @param [Exchange::ExternalAPI::Subclass] api The API class the data has to be stored for
        # @param [Hash] opts the options to cache with
        # @option opts [Time] :at the historic time of the exchange rates to be cached
        # @yield [] This method takes a mandatory block with an arity of 0 and calls it if no cached result is available
        # @raise [CachingWithoutBlockError] an Argument Error when no mandatory block has been given
         
        def cached api, opts={}, &block
          raise CachingWithoutBlockError.new('Caching needs a block') unless block_given?
          begin
            result = opts[:plain] ? client.get(key(api, opts)) : JSON.load(client.get(key(api, opts)))
          rescue ::Memcached::NotFound
            result = block.call
            if result && !result.to_s.empty?
              client.set key(api, opts), result.to_json, Configuration.update == :daily ? 86400 : 3600
            end
          end
          
          result
        end
        
      end
    end
  end
end