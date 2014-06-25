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
end
