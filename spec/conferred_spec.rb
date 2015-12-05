require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def set_envs(params)
  stub_const('ENV', params )
end

describe "Conferred" do
  before do
    #reset to defaults
    Conferred.namespace = nil
    Conferred.provider = nil
  end

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

      it "takes a provider from the environment" do
        ENV["CONFERRED_PROVIDER"] = "new"
        expect(Conferred.provider).to eq "new"
      end

      it "sets a provider" do
        Conferred.provider = "etcd"
        expect(Conferred.provider).to eq "etcd"
      end
    end

    context "provider: etcd" do
      before do
        Conferred.provider = "etcd"
      end

      describe "#namespace" do
        context "configured namespace" do
          before do
            Conferred.namespace = nil
          end

          it "defaults to empty namespace" do
            expect(Conferred.namespace).to eq ""
          end
            
          it "sets a namespace" do
            Conferred.namespace = "section"
            expect(Conferred.namespace).to eq "section"
          end

          it "reads from environment" do
            set_envs "CONFERRED_ETCD_NAMESPACE" => "xyz"
            expect(Conferred.namespace).to eq "xyz"
          end
        end

        context "inferred namespace" do
          before do
            set_envs "CONFERRED_ETCD_NAMESPACE" => "monty"
          end

          it "defers to the environment" do
            expect(Conferred.namespace).to eq "monty"
          end

          it "configured value overides environment" do
            Conferred.namespace = "sect"
            expect(Conferred.namespace).to eq "sect"
          end
        end
      end

      describe "#etcd_host" do
        before do
          Conferred.etcd_host = nil
        end 

        it "defaults to docker host" do
          expect(Conferred.etcd_host).to eq "172.17.42.1"
        end

        it "reads from CONFERRED_ETCD_HOST environment" do
          set_envs "CONFERRED_ETCD_HOST" => "myhost"
          expect(Conferred.etcd_host).to eq "myhost"
        end 
      end

      describe "#etcd_port" do
        before do
          Conferred.etcd_port = nil
        end
        it "defaults to 2379" do
          expect(Conferred.etcd_port).to eq "2379"
        end

        it "reads environment" do
          set_envs "CONFERRED_ETCD_PORT" => "1234"
          expect(Conferred.etcd_port).to eq "1234"
        end 

        it "allows assignment" do
          Conferred.etcd_port = "4321"
          expect(Conferred.etcd_port).to eq "4321"
        end
      end

      describe "#etcd_scheme" do
        before do
          Conferred.etcd_scheme = nil
        end
        it "defaults to http" do
          expect(Conferred.etcd_scheme).to eq "http"
        end

        it "reads environment" do
          set_envs "CONFERRED_ETCD_SCHEME" => "sftp"
          expect(Conferred.etcd_scheme).to eq "sftp"
        end 

        it "allows assignment" do
          Conferred.etcd_scheme = "https"
          expect(Conferred.etcd_scheme).to eq "https"
        end
      end



      describe "#etc_setting_prefix" do
        it "uses the provided settings" do
          Conferred.etcd_scheme = "https"
          Conferred.etcd_host = "etcd.host"
          Conferred.etcd_port = "2222"
          Conferred.namespace = "my-section"
          expect(Conferred.etcd_setting_prefix).to eq "https://etcd.host:2222/my-section/"
        end
      end

      describe "value lookup" do
        it "calls the correct lookup function based on provider" do
          allow(Net::HTTP).to receive(:get)
            .with(URI("#{Conferred.etcd_setting_prefix}secret"))
            .and_return('{"action":"get","node":{"key":"/secret","value":"foo","modifiedIndex":2962,"createdIndex":2962}}')
          expect(Conferred.secret).to eq "foo"
        end

        it "falls back to the environment" do
          ENV["EXTRA_SECRET"] = "shh"
          allow(Net::HTTP).to receive(:get)
            .with(URI("#{Conferred.etcd_setting_prefix}extra_secret"))
            .and_return("")
          expect(Conferred.extra_secret).to eq "shh"
        end
      end
    end
  end
end
