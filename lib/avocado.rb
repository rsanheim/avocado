#!/usr/bin/env ruby
require "pathname"
require "fileutils"

class Avocado
  def self.run(args)
    command = args.shift
    new(command, args).run
  end

  MAPPING = {
    ["start"] => :start,
    ["stop"] => :stop,
    ["status", "st"] => :status,
    ["history", "h"] => :history,
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

  def start
    status
  end

  def current_file
    @current_file ||= Pathname.new("~/.avocado").expand_path
  end

  def history_file
    @history_file ||= Pathname.new("~/.avocado_history").expand_path
  end

  def start
    FileUtils.touch(current_file)
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
