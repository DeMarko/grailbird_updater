require 'minitest/autorun'

require 'grailbird_updater'

class GrailbirdUpdaterTest < Minitest::Unit::TestCase

  # this test is stupid, just there to demonstrate infrastructure
  def test_creation
    assert_kind_of GrailbirdUpdater, GrailbirdUpdater.new(".", 10, true)
  end
end

