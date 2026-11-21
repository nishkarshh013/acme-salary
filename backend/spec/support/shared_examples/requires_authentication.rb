# Usage in a request spec:
#   it_behaves_like "requires authentication", :get, "/api/countries"
#   it_behaves_like "requires authentication", :get, -> { "/api/employees/#{employee.id}" }
RSpec.shared_examples "requires authentication" do |method, path|
  it "returns 401 without a session (#{method.upcase} #{path.respond_to?(:call) ? 'path' : path})" do
    public_send(method, path.respond_to?(:call) ? instance_exec(&path) : path)

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq("errors" => [ "Not logged in" ])
  end
end
