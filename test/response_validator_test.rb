require_relative "test_helper"

describe Committee::ResponseValidator do
  before do
    @data = ValidApp.dup
    @headers = {
      "Content-Type" => "application/json"
    }
    @schema =
      JsonSchema.parse!(MultiJson.decode(File.read("./test/data/schema.json")))
    @schema.expand_references!
    # GET /apps/:id
    @get_link = @link = @schema.properties["app"].links[2]
    # GET /apps
    @list_link = @schema.properties["app"].links[3]
    @type_schema = @schema.properties["app"]
  end

  it "passes through a valid response" do
    call
  end

  it "passes through a valid list response" do
    @data = [@data]
    @link = @list_link
    call
  end

  it "detects an improperly formatted list response" do
    @link = @list_link
    @link.target_schema = nil
    e = assert_raises(Committee::InvalidResponse) { call }
    message = "List endpoints must return an array of objects."
    assert_equal message, e.message
  end

  it "detects an invalid response Content-Type" do
    @headers = {}
    e = assert_raises(Committee::InvalidResponse) { call }
    message =
      %{"Content-Type" response header must be set to "application/json".}
    assert_equal message, e.message
  end

  it "allows application/schema+json in responses as well" do
    @headers = { "Content-Type" => "application/schema+json" }
    call
  end

  it "raises errors generated by json_schema" do
    @data.merge!("name" => "%@!")
    e = assert_raises(Committee::InvalidResponse) { call }
    message = %{Invalid response.\n\n#/name: failed schema #/definitions/app/properties/name: %@! does not match /^[a-z][a-z0-9-]{3,30}$/.}
    assert_equal message, e.message
  end

  private

  def call
    Committee::ResponseValidator.new(@link).call(@headers, @data)
  end
end
