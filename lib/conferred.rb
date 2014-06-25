class Conferred

  class << self
    def method_missing(setting, *args, &block)
      method = :env_value
      method = :env_value? if setting[-1] == "?"
      method = :env_value! if setting[-1] == "!"
      self.send method, setting
    end

    def env_name(method_name)
      method_name.to_s.chomp("!").chomp("?").upcase
    end

    def env_value(env)
      ENV[self.env_name(env)]
    end

    def env_value?(env)
      self.env_value(env) != nil
    end

    def env_value!(env)
      self.env_value(env) || raise("#{self.env_name(env)} missing from environment")
    end
  end
end
