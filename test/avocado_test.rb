require "avocado"
require "timecop"
require "minitest/autorun"
require "minitest/focus"

Timecop.safe_mode = true

describe Avocado do
  describe "runner" do
    before do
      @tempfile = Tempfile.new("avocado")
      Avocado.current_file = Pathname.new(@tempfile.path)
    end

    after do
      @tempfile.close
      @tempfile.unlink
      Avocado.current_file = Pathname.new("~/.avocado").expand_path
    end

    it "runs status by default" do
      result = Avocado.run([])
      assert result.success
      assert_equal :status, result.command
      assert_equal "No avocado currently running", result.output
    end

    describe "status" do
      it "getting status after starting an avocado" do
        time = Time.parse("January 22 2017, 3:30 AM CST")
        two_minutes_later = Time.parse("January 22 2017, 3:32 AM CST")
        Timecop.freeze(time) do
          result = Avocado.run(["start", "doing things"])
          assert result.success
          Timecop.freeze(two_minutes_later) do
            result = Avocado.run(["status"])
            assert result.success
            assert_equal "Avocado running - 23 minutes remaining", result.output
          end
        end
      end

      it "reports correctly after a long absence" do
        time = Time.parse("January 22 2017, 3:30 AM CST")
        two_months_later = Time.parse("March 22 2017, 3:30 AM CST")
        Timecop.freeze(time) do
          result = Avocado.run(["start", "doing things"])
          assert result.success
          Timecop.freeze(two_months_later) do
            rseult = Avocado.run(["status"])
            assert result.success
            assert_equal "No avocado currently running", result.output
          end
        end
      end
    end

    it "start writes out the beginning timestamp" do
      time = Time.parse("January 22 2017, 3:30 AM CST")
      Timecop.freeze(time) do
        Avocado.run(["start"])
      end
      assert_equal "2017-01-22 03:30:00 -0600", Avocado.current_file.read
    end

    it "start can write a description" do
      time = Time.parse("January 22 2017, 3:30 AM CST")
      Timecop.freeze(time) do
        Avocado.run(["start", "doing things"])
      end
      assert_equal "2017-01-22 03:30:00 -0600;doing things", Avocado.current_file.read
    end

    it "start and stop writes out both timestamps" do
      time = Time.parse("January 22 2017, 3:30 AM CST")
      stop = nil
      Timecop.freeze(time) do
        Avocado.run(["start"])
        Timecop.travel(Avocado.length) do
          stop = Time.now
          Avocado.run(["stop"])
        end
      end
      assert_equal "2017-01-22 03:30:00 -0600;#{stop}", Avocado.current_file.read
    end

    it "second avocado starts a new line" do
      start = Time.parse("January 22 2017, 3:30 AM CST")
      stop = nil
      second_start = nil
      Timecop.freeze(start) do
        Avocado.run(["start"])
        Timecop.travel(Avocado.length) do
          stop = Time.now
          Avocado.run(["stop"])
        end
        Timecop.travel(Avocado.length * 2) do
          second_start = Time.now
          Avocado.run(["start"])
        end
      end
      assert_equal "2017-01-22 03:30:00 -0600;#{stop}\n#{second_start}", Avocado.current_file.read
    end
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

    it "can write to string" do
      avocado = Avocado.parse("2017-02-02 13:24:13 -0600;2017-02-02 13:34:13 -0600;doing the things")
      assert_equal "2017-02-02 13:24:13 -0600;2017-02-02 13:34:13 -0600;doing the things", avocado.to_s
    end

    it "has start and end time" do
      start_time = Time.parse("2017-02-02 13:24:13 -0600")
      end_time = Time.parse("2017-02-02 13:49:13 -0600")

      avocado = Avocado.parse("2017-02-02 13:24:13 -0600;2017-02-02 13:49:13 -0600")
      assert_equal end_time, avocado.stop
      assert_equal start_time, avocado.start
    end

  end
end
