#!/usr/bin/env ruby
require "pathname"
require "fileutils"
require "time"

class Avocado
  def self.length
    25 * 60
  end

  def self.run(args)
    command = args.shift || "status"
    Runner.new(command, args).run
  end

  def self.current_file
    @current_file ||= Pathname.new("~/.avocado").expand_path
  end

  def self.current_file=(path)
    @current_file = path
  end

  class Runner
    attr_reader :command
    MAPPING = {
      ["start"] => :start,
      ["stop"] => :stop,
      ["status", "st"] => :status,
      ["history", "h"] => :history,
      ["watch", "w"] => :watch,
    }

    def initialize(command = "status", options = {})
      mapping = MAPPING.detect { |k, v| k.include?(command) }
      raise "Unknown command #{command}" unless mapping
      @command = mapping[1]
      raise "Unknown command #{command}" unless @command
      @options = options
    end

    def current_file
      Avocado.current_file
    end

    def run
      success, output = self.public_send(command)
      Result.new(success: success, command: command, output: output)
    end

    def start
      description = @options.first
      FileUtils.touch(current_file)

      current_lines = current_file.readlines
      lines = current_lines << Line.new(start: Time.now, description: description).to_s
      current_file.open("w+") { |f| f.write lines.join("\n") }
      [true, "Avocado #{description} started"]
    end

    def stop
      lines = current_file.readlines
      line = Avocado.parse(lines.pop) if lines.last

      line.stop = Time.now
      lines << line.to_s

      current_file.open("w+") { |f| f.write lines.join("\n") }
      [true, "Avocado #{line.description} stopped"]
    end

    def status
      lines = current_file.readlines
      line = if lines.last
        line = Avocado.parse(lines.pop)
        if line.running_over_time?
          stop
          # maybe a line.reload ?
          line = Avocado.parse(current_file.readlines.last)
        end
        line
      end

      output = case
      when line.nil?
        "No avocado currently running"
      when line.done?
        "No avocado currently running"
      else
        "Avocado running: '#{line.description}' with #{line.minutes_remaining} minutes remaining"
      end

      [true, output]
    end

    class Result
      attr_reader :success, :command, :output
      def initialize(success:, command:, output: nil)
        @success = success
        @command = command
        @output = output
      end
    end

  end

  class Line
    attr_reader :description
    attr_accessor :start, :stop

    def initialize(start:, stop: nil, description: nil)
      @start = start
      @stop = stop
      @description = description
    end

    def done?
      @start && @stop
    end

    def to_s
      [start, stop, description].compact.join(";")
    end

    def running_over_time?
      !done? && (seconds_elapsed > length)
    end

    def autocomplete
      self.stop = self.start + length
    end

    def seconds_elapsed
      Time.now - (@start)
    end

    def seconds_remaining
      length - seconds_elapsed
    end

    def minutes_remaining
      (seconds_remaining / 60).truncate
    end

    def time_left
      seconds_part = (seconds_remaining - (minutes_remaining * 60)).round
      "#{minutes_remaining}:#{seconds_part}"
    end

    def length
      25 * 60
    end
  end

  def self.parse(line)
    parts = line.split(";")
    start = Time.parse(parts[0])
    case parts.size
    when 1
      Line.new(start: start)
    when 2
      stop_or_description = parts[1]
      begin
        stop = Time.parse(stop_or_description)
      rescue ArgumentError
        description = parts[1]
      end
      Line.new(start: start, stop: stop, description: description)
    when 3
      stop = Time.parse(parts[1])
      description = parts[2]
      Line.new(start: start, stop: stop, description: description)
    else
      raise ArgumentError, "Invalid line format #{line}"
    end
  end

  attr_reader :command, :current_file, :past_file

  def watch
    if !current_file.exist?
      abort "no avocado running"
    end
    if current_file.exist? && seconds_remaining <= 0
      abort "no avocado running"
    end
    while(current_file.exist? && seconds_remaining > 0)
      puts "current avocado running - #{time_left} left"
      sleep 1
    end
    exit(true)
  end

  def history
    history_file.read
  end

  def debug
    p "secs elapsed", seconds_elapsed
    p "mins remaining", minutes_remaining
    p "secs remaining", seconds_remaining
  end

  def seconds_elapsed
    Time.now - current_file.mtime
  end

  def seconds_remaining
    length - seconds_elapsed
  end

  def minutes_remaining
    (seconds_remaining / 60).truncate
  end

  def time_left
    seconds_part = (seconds_remaining - (minutes_remaining * 60)).round
    "#{minutes_remaining}:#{seconds_part}"
  end

  def length
    60 * 25
  end

end
