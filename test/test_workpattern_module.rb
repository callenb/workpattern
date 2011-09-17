require File.dirname(__FILE__) + '/test_helper.rb'
require File.dirname(__FILE__) + '/mock_date_time.rb'

class TestWorkpatternModule < Test::Unit::TestCase #:nodoc:

  def setup
    Workpattern.clear()
  end
  
  must "create workpattern with given name" do
    wp = Workpattern.new()
    assert_equal Workpattern::DEFAULT_WORKPATTERN_NAME, wp.name, 'not returned the default workpattern name'
    assert_equal Workpattern::DEFAULT_BASE_YEAR, wp.from.year, 'not returned the default workpattern base year'
    assert_equal Workpattern::DEFAULT_SPAN, wp.span, 'not returned the default workpattern span'
    
    mywp_name='barrie callender'
    mywp_base=1963
    mywp_span=48
    mywp = Workpattern.new(mywp_name, mywp_base,mywp_span)
    assert_equal mywp_name, mywp.name, 'not returned the supplied workpattern name'
    assert_equal mywp_base, mywp.from.year, 'not returned the supplied workpattern base year'
    assert_equal mywp_span, mywp.span, 'not returned the supplied workpattern span'
    
  end
  
  must "raise error when creating workpattern with existing name" do
    
    assert_raise NameError do
      mywp_name='duplicate'
      wp=Workpattern.new(mywp_name)    
      wp=Workpattern.new(mywp_name)
    end
  end
  
  must "return an array of all known workpattern objects" do
    names =%w{fred harry sally}
    names.each {|name| wp=Workpattern.new(name)}
    wp_names = Workpattern.to_a
    
    assert_equal names.size, wp_names.size, "lists are not the same size"
    
    wp_names.each {|name, wp| assert names.include?(name)}
  end
  
  must "return empty array when no workpatterns exist" do
    assert Workpattern.to_a.empty?
  end
  
  must "return existing workpattern" do
    assert true
  end
  
  must "raise error when workpattern does not exist" do
    assert true
  end
  
  must "delete existing workpattern" do
    assert true
  end
  
  must "be silent deleting workpattern that does not exist" do
    assert true
  end
  
  must "delete all workpatterns" do
    assert true
  end
  
  
end