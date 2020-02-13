describe "Creating a webhook" do
  before do
    td.create_pact_with_hierarchy("Some Consumer", "1", "Some Provider")
  end

  let(:headers) { {'CONTENT_TYPE' => 'application/json'} }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true)}
  let(:webhook_json) { webhook_hash.to_json }
  let(:webhook_hash) do
    {
      description: "trigger build",
      enabled: false,
      events: [{
        name: 'something_happened'
      }],
      request: {
        method: 'POST',
        url: 'https://example.org',
        headers: {
          :"Content-Type" => "application/json"
        },
        body: {
          a: 'body'
        }
      }
    }
  end

  subject { post(path, webhook_json, headers) }

  context "for a consumer and provider" do
    let(:path) { "/webhooks/provider/Some%20Provider/consumer/Some%20Consumer" }

    context "with invalid attributes" do
      let(:webhook_hash) { {} }

      its(:status) { is_expected.to be 400 }

      it "returns a JSON content type" do
        expect(subject.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
      end

      it "returns the validation errors" do
        expect(response_body[:errors]).to_not be_empty
      end
    end

    context "with valid attributes" do
      its(:status) { is_expected.to be 201 }

      it "returns the Location header" do
        expect(subject.headers['Location']).to match(%r{http://example.org/webhooks/.+})
      end

      it "returns a JSON Content Type" do
        expect(subject.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
      end

      it "returns the newly created webhook" do
        expect(response_body).to include webhook_hash
      end
    end
  end

  context "for a provider" do
    let(:path) { "/webhooks" }

    before do
      webhook_hash[:provider] = { name: "Some Provider" }
    end

    its(:status) { is_expected.to be 201 }

    it "creates a webhook without a consumer" do
      subject
      expect(PactBroker::Webhooks::Webhook.first.provider).to_not be nil
      expect(PactBroker::Webhooks::Webhook.first.consumer).to be nil
    end
  end

  context "for a consumer" do
    let(:path) { "/webhooks" }
    before do
      webhook_hash[:consumer] = { name: "Some Consumer" }
    end

    its(:status) { is_expected.to be 201 }

    it "creates a webhook without a provider" do
      subject
      expect(PactBroker::Webhooks::Webhook.first.consumer).to_not be nil
      expect(PactBroker::Webhooks::Webhook.first.provider).to be nil
    end
  end

  context "with no consumer or provider" do
    let(:path) { "/webhooks" }

    its(:status) { is_expected.to be 201 }

    it "creates a webhook without a provider" do
      subject
      expect(PactBroker::Webhooks::Webhook.first.consumer).to be nil
      expect(PactBroker::Webhooks::Webhook.first.provider).to be nil
    end
  end

  context "with a UUID" do
    let(:path) { "/webhooks/1234123412341234" }

    subject { put(path, webhook_json, headers) }

    its(:status) { is_expected.to be 201 }
  end
end
