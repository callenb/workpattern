require File.dirname(__FILE__) + '/test_helper.rb'

class TestWorkpatternModule < MiniTest::Unit::TestCase #:nodoc:

  def setup
    Workpattern.clear()
  end
  
  def test_must_create_workpattern_with_given_name
  
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
  
  def test_must_raise_error_when_creating_workpattern_with_existing_name

    assert_raises NameError do
      mywp_name='duplicate'
      wp=Workpattern.new(mywp_name)    
      wp=Workpattern.new(mywp_name)
    end

  end
  
  def test_must_return_an_array_of_all_known_workpattern_objects

    names =%w{fred harry sally}
    names.each {|name| wp=Workpattern.new(name)}
    wp_names = Workpattern.to_a
    
    assert_equal names.size, wp_names.size, "lists are not the same size"
    
    wp_names.each {|name, wp| assert names.include?(name)}
  end
  
  def test_must_return_empty_array_when_no_workpatterns_exist

    assert Workpattern.to_a.empty?
  end
  
  def test_must_return_existing_workpattern

    names =%w{fred harry sally}
    names.each {|name| wp=Workpattern.new(name)}
    
    names.each {|name|
      wp=Workpattern.get(name)
      }
  end
  
  def test_must_raise_error_when_workpattern_does_not_exist

    names =%w{fred harry sally}
    names.each {|name| wp=Workpattern.new(name)}
    assert_raises NameError do
      wp=Workpattern.get('missing')
    end
  end
  
  def test_must_delete_existing_workpattern_returning_true

    names =%w{fred harry sally}
    names.each {|name| wp=Workpattern.new(name)}
    names.each {|name| assert Workpattern.delete(name)}
  end
  
  def test_must_return_false_deleting_workpattern_that_does_not_exist
    names =%w{fred harry sally}
    names.each {|name| wp=Workpattern.new(name)}
    assert !Workpattern.delete('missing')
  end
  
  def test_must_delete_all_workpatterns

    names =%w{fred harry sally}
    names.each {|name| wp=Workpattern.new(name)}
    Workpattern.clear
    assert Workpattern.to_a.empty?
  end
  
  
end
