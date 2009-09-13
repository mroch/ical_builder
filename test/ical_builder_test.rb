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
    @builder.gibberish(Date.new(2009, 9, 11))
    assert_equal "GIBBERISH:20090911\r\n", @builder.to_s
  end

  should "handle date-time property values (4.3.5)" do
    # Local time after 12pm
    @builder.gibberish(Time.local(2009, 9, 11, 13, 45, 22))
    assert_equal "GIBBERISH:20090911T134522\r\n", @builder.to_s
    
    # Local time before 12pm
    @builder = Builder::Ical.new
    @builder.gibberish(Time.local(2009, 9, 11, 1, 45, 22))
    assert_equal "GIBBERISH:20090911T014522\r\n", @builder.to_s
    
    # UTC after 12pm
    @builder = Builder::Ical.new
    @builder.gibberish(Time.utc(2009, 9, 11, 13, 45, 22))
    assert_equal "GIBBERISH:20090911T134522Z\r\n", @builder.to_s
    
    # UTC before 12pm
    @builder = Builder::Ical.new
    @builder.gibberish(Time.utc(2009, 9, 11, 1, 45, 22))
    assert_equal "GIBBERISH:20090911T014522Z\r\n", @builder.to_s
  end

  should "handle lists of values (4.1.1)" do
    @builder.gibberish(['foo', 'bar'])
    assert_equal "GIBBERISH:foo,bar\r\n", @builder.to_s
  end

  should "handle lists of values with only one item (4.1.1)" do
    @builder.gibberish(['foo'])
    assert_equal "GIBBERISH:foo\r\n", @builder.to_s
  end

  should "allow newlines (4.3.11)" do
    @builder.text("Foo bar\nBaz bliffl")
    assert_equal "TEXT:Foo bar\nBaz bliffl\r\n", @builder.to_s
  end

  should "handle values with multiple parts (4.1.1)" do
    @builder.gibberish({ :foo => 'bar', :bymonth => 11, :byday => '1SU' })
    assert_equal "GIBBERISH:BYDAY=1SU;BYMONTH=11;FOO=bar\r\n", @builder.to_s
  end

  should "handle values and properties with multiple values" do
    @builder.gibberish({ :freq => 'YEARLY', :bymonth => 11, :byday => '1SU' }, { :foo => 'bar', :baz => 'bliffl' })
    assert_equal "GIBBERISH;BAZ=bliffl;FOO=bar:BYDAY=1SU;BYMONTH=11;FREQ=YEARLY\r\n", @builder.to_s
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

  should "append arbitrary text" do
    @builder.foo("bar")
    @builder << "ARBITRARY-PROPERTY:\"Lorem ipsum dolor sit amet\"\r\n"
    assert_equal "FOO:bar\r\nARBITRARY-PROPERTY:\"Lorem ipsum dolor sit amet\"\r\n", @builder.to_s
  end

  should "not fold lines less than 75 characters long" do
    @builder.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
    assert_equal "TEXT:Lorem ipsum dolor sit amet, consectetur adipiscing elit.\r\n", @builder.to_s
  end

  should "not fold lines exactly 75 characters long" do
    @builder.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec nullam.")
    assert_equal "TEXT:Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec nullam.\r\n", @builder.to_s
  end

  should "not fold lines exactly 75 characters long even if they end in whitespace" do
    @builder.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec nullam ")
    assert_equal "TEXT:Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec nullam \r\n", @builder.to_s
  end

  should "fold lines longer than 75 characters" do
    @builder.description("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam eget elit tellus. In hac habitasse platea dictumst. Vestibulum tincidunt velit id erat interdum id tristique diam blandit. Praesent nullam.")
    assert_equal \
      "DESCRIPTION:Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam eg\r\n et elit tellus. In hac habitasse platea dictumst. Vestibulum tincidunt vel\r\n it id erat interdum id tristique diam blandit. Praesent nullam.\r\n",
      @builder.to_s
  end

  should "fold lines longer than 75 characters even if only whitespace" do
    @builder.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec nullam. ")
    assert_equal "TEXT:Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec nullam.\r\n  \r\n", @builder.to_s
  end

  should "fold arbitrary text" do
    @builder << "TEXT:Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam eget elit tellus. In hac habitasse platea dictumst.\r\n"
    assert_equal "TEXT:Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam eget elit\r\n  tellus. In hac habitasse platea dictumst.\r\n", @builder.to_s
  end

  should "always place FREQ first in RRULE values" do
    @builder.rrule({ :freq => 'YEARLY', :interval => 1, :byday => '1SU' })
    assert_equal "RRULE:FREQ=YEARLY;BYDAY=1SU;INTERVAL=1\r\n", @builder.to_s
  end

  should "format RRULEs properly even with only FREQ" do
    @builder.rrule({ :freq => 'YEARLY' })
    assert_equal "RRULE:FREQ=YEARLY\r\n", @builder.to_s
  end

end
