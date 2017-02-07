#!/usr/bin/env ruby
require "pathname"
require "fileutils"

class Avocado
  def self.run(args)
    command = args.shift
    new(command, args).run
  end

  class Line
    attr_reader :description
    
    def initialize(start_time:, end_time: nil, description: nil)
      @start_time = start_time
      @end_time = end_time
      @description = description
    end

    def done?
      !!(@start_time && @end_time)
    end
  end

  def self.parse(line)
    parts = line.split(";")
    start_time = parts[0]
    if parts.size == 2
      end_or_desc = parts[1]
      begin
        end_time = Time.parse(end_or_desc)
      rescue ArgumentError
        description = parts[1]
      end
    else
      end_time = parts[1]
      description = parts[2]
    end
    Line.new(start_time: start_time, end_time: end_time, description: description)
  end

  MAPPING = {
    ["start"] => :start,
    ["stop"] => :stop,
    ["status", "st"] => :status,
    ["history", "h"] => :history,
    ["watch", "w"] => :watch,
  }

  def initialize(command = :status, options = {})
    mapping = MAPPING.detect { |k, v| k.include?(command) }
    @command = mapping[1]
    raise "Unknown command #{command}" unless @command
    @options = options
  end

  def run
    puts self.public_send(command)
  end

  attr_reader :command, :current_file, :past_file

  def current_file
    @current_file ||= Pathname.new("~/.avocado").expand_path
  end

  def history_file
    @history_file ||= Pathname.new("~/.avocado_history").expand_path
  end

  def start
    FileUtils.touch(current_file)
    "success - started an avocado"
  end

  def stop
    history_file.open("a") do |file|
      file.puts "#{current_file.mtime} #{current_file.ctime + length}"
    end
    current_file.delete
    "stopped avocado"
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
