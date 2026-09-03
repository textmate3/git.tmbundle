SPEC_ROOT = File.dirname(__FILE__)
FIXTURES_DIR = "#{SPEC_ROOT}/fixtures"

# environment.rb pulls in the shared Bundle Support libraries. Inside TextMate
# the editor provides TM_SUPPORT_PATH. From a terminal, default it to the
# sibling bundle-support.tmbundle checkout.
ENV['TM_SUPPORT_PATH'] ||= File.expand_path('../../../bundle-support.tmbundle/Support/shared', SPEC_ROOT)

require SPEC_ROOT + '/../environment.rb'
require 'stringio'
require 'nokogiri'
require 'rspec/collection_matchers'
require SPEC_ROOT + "/../tmvc/spec/spec_helpers.rb"
require LIB_ROOT + "/ui.rb"
SpecHelpers::PUTS_CAPTURE_CLASSES << ::Git

RSpec.configure do |config|
  config.include SpecHelpers

  # A controller that discards its output sets $exit_status, which tmvc turns into
  # the process exit code from an at_exit hook. Under the suite that would make a
  # green run exit 200, so the status is cleared after every example.
  config.after(:each) { $exit_status = nil }

  # This suite was written for RSpec 1. The should expectation syntax and the
  # should_receive/stub mock syntax are still supported by rspec-expectations
  # and rspec-mocks behind these settings.
  config.expect_with(:rspec) { |expectations| expectations.syntax = [:should, :expect] }
  config.mock_with(:rspec)   { |mocks| mocks.syntax = [:should, :expect] }
end

shared_examples "Formatter with layout" do
  before(:each) do
    @h = Nokogiri::HTML(@output)
  end

  it "should include a style.css" do
    (@h / "link").map{|s| File.basename(s["href"])}.should include("style.css")
  end

  it "should include a prototype.js" do
    (@h / "script").map{|s| File.basename(s["src"].to_s)}.should include("prototype.js")
  end
end

class ArrayKeyedHash < Hash
  def []=(*args)
    value = args.pop
    super(args, value)
  end

  def [](*args)
    super(args)
  end
end

class Git
  alias :initialize_without_autopath :initialize
  def initialize(options = {})
    options = options.dup
    options[:path] ||= "/base"
    initialize_without_autopath(options)
  end

  class << self
    def reset_mock!
      command_response.clear
      command_output.clear
      commands_ran.clear
    end

    def command_response
      @@command_response ||= ArrayKeyedHash.new
    end

    def command_output
      @@command_output ||= []
    end

    def commands_ran
      @@commands_ran ||= []
    end

    def stubbed_command(*args)
      commands_ran << args
      if command_response.empty?
        command_output.shift
      else
        r = command_response[*args] || ""
        if r.is_a?(Array)
          r.shift
        else
          r
        end
      end
    end
  end

  def command(*args)
    Git.stubbed_command(*args)
  end

  def popen_command(*args)
    StringIO.new(command(*args))
  end

  def git_dir(file_or_dir = paths.first)
    "/base/.git"
  end

  def paths(*args)
    [path]
  end

  def nca(*args)
    path
  end

  attr_writer :version
  def version; @version ||= "1.5.4.3"; end
end

def exit_with_output_status
end

[:exit_show_html, :exit_discard, :exit_show_tool_tip].each do |exit_method|
  Object.send :define_method, exit_method do
    $exit_status = Object.const_get(exit_method.to_s.upcase)
  end
end

class Object
  def self.singleton_new(*args)
    new_obj = new(*args)
    self.stub(:new).and_return(new_obj)
    new_obj
  end
end

module TextMate::UI
  def self.request_item(options = {}, &block)
    yield options[:items].first if block_given?
    options[:items].first
  end
end
