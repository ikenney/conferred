require 'json'

class Conferred
  @@provider = "env"
  class << self
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
      @@namespace || ENV["CONFERRED_ETC_NAMESPACE"] || ""
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
      #raise "iConferred: Undefined provider (#{@@provider})" unless self.responds_to setting_method_name
      self.send(setting_method_name, key) 
    end

    def setting_value?(key)
      self.setting_value(key) != nil
    end

    def setting_value!(key)
      self.setting_value(key) || raise("#{self.setting_name(key)} missing from environment")
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
      URI("http://localhost:2379/#{etcd_setting_namespace}#{key}")
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
