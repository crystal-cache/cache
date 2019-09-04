require "./spec_helper"

describe Cache::DataCompressor do
  it "should deflate/inflate data" do
    string = "this is test string"

    compressed_string = Cache::DataCompressor.deflate(string)
    decompressed_string = Cache::DataCompressor.inflate(compressed_string)

    string.should eq(decompressed_string)
  end
end
