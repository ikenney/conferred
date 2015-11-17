require 'json'

class Conferred
  @@provider = "env"
  class << self
    attr_accessor :namespace
    
    def provider=(value)
      @@provider=value
    end

    def provider
      @@provider || "env"
    end

    def method_missing(setting, *args, &block)
      if setting =~ /#{provider}_setting_value/
        super
        return
      end
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
        ""
      end
    end

    def etcd_setting_endpoint(key)
      URI("http://localhost:2379/#{etcd_setting_namespace}#{key}")
    end

    def etcd_setting_namespace
      self.namespace ? "#{self.namespace}/" : ""
    end

    def setting_method_name
      "#{self.provider}_setting_value".to_sym
    end
  end
end
