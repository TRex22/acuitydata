require "test_helper"

class AcuityDataTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil AcuityData::VERSION
  end

  def test_that_the_client_has_compatible_api_version
    assert_equal 'v1', AcuityData::Client.compatible_api_version
  end

  def test_that_the_client_has_api_version
    assert_equal 'v1 2024-03-19', AcuityData::Client.api_version
  end
end
