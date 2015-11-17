require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def set_envs(params)
  stub_const('ENV', params )
end

describe "Conferred" do
  context "simple config methods " do
    describe "accessor methods" do
      it "returns environment setting" do
        set_envs "MY_SETTING" => "my value"
        expect(Conferred.my_setting).to eq("my value")
      end

      it "returns nil if not set" do
        set_envs "YOUR_SETTING" => ""
        expect(Conferred.your_setting).to eq("")
      end
    end

    describe "bang methods" do
      it "raises error if missing" do
        expect { Conferred.missing_setting! }.to raise_error("MISSING_SETTING missing from environment")
      end

      it "returns value if present" do
        set_envs "ANOTHER_SETTING" => "value 123"
        expect(Conferred.another_setting!).to eq("value 123")
      end
    end

    describe "query methods" do
      it "is true when set" do
        set_envs "A_SETTING" => "value 123"
        expect(Conferred.a_setting?).to eq true
      end
      it "is false when missing" do
        expect(Conferred.another_setting?).to eq false
      end
    end
  end


  describe "providers" do
    describe "#provider" do
      it "defaults to 'env'" do
        expect(Conferred.provider).to eq "env"
      end

      it "raises on missing provider" do
        Conferred.provider = "none"
        expect{Conferred.foo}.to raise_error NoMethodError
      end

      it "sets a provider" do
        Conferred.provider = "etcd"
        expect(Conferred.provider).to eq "etcd"
      end
    end

    describe "#namespace" do
      before do
        Conferred.provider = "etcd"
        Conferred.namespace = "section"
      end

      it "sets a namespace" do
        expect(Conferred.namespace).to eq "section"
      end

      it "passes the namespace to etcd" do
        expect(Net::HTTP).to receive(:get)
          .with(URI('http://localhost:2379/section/secret'))
        Conferred.secret
      end
    end

    describe "etcd" do
      it "calls the correct lookup function based on provider" do
        Conferred.provider="etcd"
        Conferred.namespace=nil
        allow(Net::HTTP).to receive(:get)
          .with(URI('http://localhost:2379/secret'))
          .and_return('{"action":"get","node":{"key":"/secret","value":"foo","modifiedIndex":2962,"createdIndex":2962}}')
        expect(Conferred.secret).to eq "foo"
      end
    end
  end
end
