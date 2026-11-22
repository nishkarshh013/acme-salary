require "rails_helper"

RSpec.describe ImmutableAssets do
  def response_for(path, status: 200)
    app = ->(_env) { [ status, { "cache-control" => "no-cache" }, [ "body" ] ] }
    described_class.new(app).call(Rack::MockRequest.env_for(path))
  end

  it "lets browsers cache a hashed build file for a year" do
    _status, headers, _body = response_for("/assets/index-C2Y4hXW8.js")

    expect(headers["cache-control"]).to eq("public, max-age=31536000, immutable")
  end

  it "leaves other files and pages as they are" do
    expect(response_for("/index.html")[1]["cache-control"]).to eq("no-cache")
    expect(response_for("/employees/123")[1]["cache-control"]).to eq("no-cache")
  end

  it "doesn't mark a missing asset as cacheable" do
    expect(response_for("/assets/gone.js", status: 404)[1]["cache-control"]).to eq("no-cache")
  end
end
