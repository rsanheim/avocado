require "avocado"
require "minitest/autorun"

describe Avocado do
  it "works" do
    Avocado.run([])
  end

  describe "runner" do
    
  end

  describe "parsing" do
    it "is not done when there is just the start timestamp" do
      avocado = Avocado.parse("2017-02-02 13:24:13 -0600")
      refute avocado.done?
    end

    it "is done when it has both timestamps" do
      avocado = Avocado.parse("2017-02-02 13:24:13 -0600;2017-02-02 13:49:13 -0600")
      assert avocado.done?
    end

    it "can have an optional description" do
      avocado = Avocado.parse("2017-02-02 13:24:13 -0600;doing the things")
      assert_equal "doing the things", avocado.description
    end

    it "when it has start, end and description" do
      avocado = Avocado.parse("2017-02-02 13:24:13 -0600;2017-02-02 13:34:13 -0600;doing the things")
      assert_equal "doing the things", avocado.description
    end

  end
end
