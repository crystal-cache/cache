require "./spec_helper"

describe Cache::DataCompressor do
  it "should deflate/inflate data" do
    string = "this is test string"

    compressed_string = Cache::DataCompressor.deflate(string)
    decompressed_string = Cache::DataCompressor.inflate(compressed_string)

    string.should eq(decompressed_string)
  end

  it "should deflate data with base64" do
    string = "hello"

    Cache::DataCompressor.deflate(string).should eq("eJzLSM3JyQcABiwCFQ==\n")
  end
end
