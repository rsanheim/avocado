#!/usr/bin/env ruby
require "pathname"
require "fileutils"

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
      success = self.public_send(command)
      Result.new(success: success, command: command)
    end

    def start
      description = @options.first
      FileUtils.touch(current_file)
      current_lines = current_file.readlines
      lines = current_lines << Line.new(start: Time.now, description: description).to_s
      current_file.open("w+") { |f| f.write lines.join("\n") }
      true
    end

    def stop
      lines = current_file.readlines
      line = Avocado.parse(lines.pop) if lines.last
      line.stop = Time.now
      lines << line.to_s

      current_file.open("w+") { |f| f.write lines.join("\n") }
      true
    end

    def status
      if current_file.exist?
        if seconds_remaining <= 0
          stop
          "stopping a avocado - current avocado running - #{time_left} left"
        else
          "current avocado running - #{time_left} left"
        end
      else
        "no avocado running"
      end
    end


    class Result
      attr_reader :success, :command
      def initialize(success:, command:)
        @success = success
        @command = command
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
      !!(@start && @stop)
    end

    def to_s
      [start, stop, description].compact.join(";")
    end
  end

  def self.parse(line)
    parts = line.split(";")
    start = parts[0]
    if parts.size == 2
      stop_or_desc = parts[1]
      begin
        stop = Time.parse(stop_or_desc)
      rescue ArgumentError
        description = parts[1]
      end
    else
      stop = parts[1]
      description = parts[2]
    end
    Line.new(start: start, stop: stop, description: description)
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
