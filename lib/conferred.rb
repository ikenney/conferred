require 'json'

class Conferred
  DEFAULT_ETCD_HOST = "172.17.42.1"
  DEFAULT_ETCD_PORT = "2379"
  DEFAULT_ETCD_SCHEME = "http"

  @@provider = "env"
  @@etcd_scheme = DEFAULT_ETCD_SCHEME
  @@etcd_host = DEFAULT_ETCD_HOST
  @@etcd_port = DEFAULT_ETCD_PORT
  @@namespace = ""

  class << self
   # attr_writer :etcd_port, :etcd_scheme, :etcd_host
    def provider=(value)
      @@provider=value
    end

    def provider
      @@provider || ENV["CONFERRED_PROVIDER"] || "env"
    end

    def namespace=(value)
      @@namespace=value
    end

    def namespace
      @@namespace || ENV["CONFERRED_ETCD_NAMESPACE"] || ""
    end

    def etcd_host
      # if not provided set host to default docker host ip from within a container 
      @@etcd_host || ENV["CONFERRED_ETCD_HOST"] || DEFAULT_ETCD_HOST
    end

    def etcd_port
      @@etcd_port || ENV["CONFERRED_ETCD_PORT"] || DEFAULT_ETCD_PORT
    end

    def etcd_scheme
      @@etcd_scheme || ENV["CONFERRED_ETCD_SCHEME"] || DEFAULT_ETCD_SCHEME
    end

    def etcd_port=(port)
      @@etcd_port = port
    end

    def etcd_host=(host)
      @@etcd_host = host
    end

    def etcd_scheme=(scheme)
      @@etcd_scheme = scheme
    end

   def method_missing(setting, *args, &block)
      super if setting =~ /#{provider}_setting_value/
      method = :setting_value
      method = :setting_value? if setting[-1] == "?"
      method = :setting_value! if setting[-1] == "!"
      self.send method, setting 
    end

    def setting_name(method_name)
      method_name.to_s.chomp("!").chomp("?").upcase
    end

    def setting_value(key)
      #raise "Conferred: Undefined provider (#{@@provider})" unless self.responds_to setting_method_name
      self.send(setting_method_name, key) 
    end

    def setting_value?(key)
      self.setting_value(key) != nil
    end

    def setting_value!(key)
      self.setting_value(key) || raise("#{self.setting_name(key)} missing from environment")
    end

    def etcd_setting_prefix
      "#{self.etcd_scheme}://#{self.etcd_host}:#{self.etcd_port}/#{etcd_setting_namespace}"
    end

    private

    def env_setting_value(key)
      ENV[self.setting_name(key)]
    end

    def etcd_setting_value(key)
      begin
        resp = JSON.parse(Net::HTTP.get(etcd_setting_endpoint(key)))
        resp["node"]["value"]
      rescue
        env_setting_value(key)
      end
    end

    def etcd_setting_endpoint(key)
      URI("#{self.etcd_setting_prefix}#{key}")
    end

    def etcd_setting_namespace
      return "" unless self.namespace 
      return "" if self.namespace.empty?
      "#{self.namespace}/"
    end

    
    def setting_method_name
      "#{self.provider}_setting_value".to_sym
    end
  end
end
