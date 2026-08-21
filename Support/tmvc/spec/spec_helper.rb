SPEC_ROOT = File.dirname(__FILE__)

# tmvc.rb pulls in the shared Bundle Support libraries. Inside TextMate the
# editor provides TM_SUPPORT_PATH. From a terminal, default it to the sibling
# bundle-support.tmbundle checkout.
ENV['TM_SUPPORT_PATH'] ||= File.expand_path('../../../../bundle-support.tmbundle/Support/shared', SPEC_ROOT)

require SPEC_ROOT + "/../tmvc.rb"
require SPEC_ROOT + "/spec_helpers.rb"

RSpec.configure do |config|
  config.include SpecHelpers

  # This suite was written for RSpec 1. The should expectation syntax and the
  # should_receive/stub mock syntax are still supported by rspec-expectations
  # and rspec-mocks behind these settings.
  config.expect_with(:rspec) { |expectations| expectations.syntax = [:should, :expect] }
  config.mock_with(:rspec)   { |mocks| mocks.syntax = [:should, :expect] }
end