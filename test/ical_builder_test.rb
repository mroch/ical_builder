require 'test_helper'

class IcalBuilderTest < Test::Unit::TestCase

  def setup
    @builder = Builder::Ical.new
  end

  should "handle boolean property values (4.3.2)" do
    @builder.gibberish(true)
    assert_equal "GIBBERISH:TRUE\r\n", @builder.to_s
  end

  should "handle date property values (4.3.4)" do
    date = Date.new(2009, 9, 11)
    @builder.gibberish(date)
    assert_equal "GIBBERISH:20090911\r\n", @builder.to_s
  end

  should "handle date-time property values (4.3.5)" do
    # Local time after 12pm
    time = Time.local(2009, 9, 11, 13, 45, 22)
    @builder.gibberish(time)
    assert_equal "GIBBERISH:20090911T134522\r\n", @builder.to_s
    
    # Local time before 12pm
    time = Time.local(2009, 9, 11, 1, 45, 22)
    @builder = Builder::Ical.new
    @builder.gibberish(time)
    assert_equal "GIBBERISH:20090911T014522\r\n", @builder.to_s
    
    # UTC after 12pm
    time = Time.utc(2009, 9, 11, 13, 45, 22)
    @builder = Builder::Ical.new
    @builder.gibberish(time)
    assert_equal "GIBBERISH:20090911T134522Z\r\n", @builder.to_s
    
    # UTC before 12pm
    time = Time.utc(2009, 9, 11, 1, 45, 22)
    @builder = Builder::Ical.new
    @builder.gibberish(time)
    assert_equal "GIBBERISH:20090911T014522Z\r\n", @builder.to_s
  end

  should "handle lists of values (4.1.1)" do
    @builder.gibberish(['foo', 'bar'])
    assert_equal "GIBBERISH:foo,bar\r\n", @builder.to_s

    @builder = Builder::Ical.new
    @builder.gibberish(['foo'])
    assert_equal "GIBBERISH:foo\r\n", @builder.to_s
  end

  should "format parameters without double-quotes correctly" do
    @builder.organizer('MAILTO:jsmith@host.com', :cn => 'John Smith')
    assert_equal "ORGANIZER;CN=John Smith:MAILTO:jsmith@host.com\r\n", @builder.to_s
  end
  
  should "format parameters with double-quotes correctly" do
    @builder.organizer('MAILTO:jsmith@host.com', :cn => '"John Smith"')
    assert_equal "ORGANIZER;CN=\"John Smith\":MAILTO:jsmith@host.com\r\n", @builder.to_s
  end

  should "format parameters with dashes correctly" do
    @builder.attendee('MAILTO: jdoe@host.com', :delegated_from => '"MAILTO:jsmith@host.com"')
    assert_equal \
      "ATTENDEE;DELEGATED-FROM=\"MAILTO:jsmith@host.com\":MAILTO: jdoe@host.com\r\n", 
      @builder.to_s
  end

  should "format parameters with multiple values correctly" do
    @builder.attendee(
      'MAILTO:janedoe@host.com',
      :member => ['"MAILTO:projectA@host.com"', '"MAILTO:projectB@host.com"']
    )
    assert_equal \
      "ATTENDEE;MEMBER=\"MAILTO:projectA@host.com\",\"MAILTO:projectB@host.com\":MAILT\r\n O:janedoe@host.com\r\n",
      @builder.to_s
  end

  should "fold lines longer than 75 characters" do
    @builder.description("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam eget elit tellus. In hac habitasse platea dictumst. Vestibulum tincidunt velit id erat interdum id tristique diam blandit. Praesent nullam.")
    assert_equal \
      "DESCRIPTION:Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam eg\r\n et elit tellus. In hac habitasse platea dictumst. Vestibulum tincidunt vel\r\n it id erat interdum id tristique diam blandit. Praesent nullam.\r\n",
      @builder.to_s
  end

end
