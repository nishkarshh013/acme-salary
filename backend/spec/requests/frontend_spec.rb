require "rails_helper"

RSpec.describe "Serving the React app", type: :request do
  let(:app_html) { "<!doctype html><title>ACME Salary</title><div id=\"root\"></div>" }

  # The real index.html is the frontend build, copied into public/ only in
  # the Docker image; specs serve a stand-in from a temporary directory.
  around do |example|
    original = Rails.configuration.x.frontend_index
    Dir.mktmpdir do |dir|
      index = Pathname(dir).join("index.html")
      index.write(app_html)
      Rails.configuration.x.frontend_index = index
      example.run
    end
  ensure
    Rails.configuration.x.frontend_index = original
  end

  it "returns the app's HTML for a page path, so a link like /employees/123 works on reload" do
    get "/employees/123"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/html")
    expect(response.body).to eq(app_html)
    expect(response.headers["Cache-Control"]).to eq("no-cache")
  end

  it "returns the app's HTML for the root path and for paths with dots" do
    get "/"
    expect(response.body).to eq(app_html)

    get "/insights/countries/2.json"
    expect(response.body).to eq(app_html)
  end

  it "doesn't need a session: the page holds no data" do
    get "/insights"

    expect(response).to have_http_status(:ok)
  end

  it "returns the JSON 404 for an unknown API path, whatever the method, without a session" do
    get "/api/unknown"

    expect(response).to have_http_status(:not_found)
    expect(response.media_type).to eq("application/json")
    expect(response.parsed_body).to eq("errors" => [ "Not found" ])

    post "/api/unknown/deeper", params: { a: 1 }, as: :json
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body).to eq("errors" => [ "Not found" ])

    get "/api"
    expect(response.parsed_body).to eq("errors" => [ "Not found" ])
  end

  it "keeps the health check at /up" do
    get "/up"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to eq(app_html)
  end

  it "returns a plain 404 when the frontend hasn't been built (development without the Docker image)" do
    Rails.configuration.x.frontend_index = Pathname("/nonexistent/index.html")

    get "/employees"

    expect(response).to have_http_status(:not_found)
    expect(response.body).to be_empty
  end
end

RSpec.describe "The React app's index.html", type: :request do
  it "is public/index.html by default, where the Dockerfile puts the frontend build" do
    expect(Rails.configuration.x.frontend_index).to eq(Rails.public_path.join("index.html"))
  end
end
