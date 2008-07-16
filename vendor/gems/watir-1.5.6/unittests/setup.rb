# libraries used by feature tests
require 'watir'
END {$ie.close if $ie && $ie.exists?; Watir::IE.quit} # close ie at completion of the tests

require 'test/unit'
require 'watir/testcase'

# rename goto_page to be goto_page

# Better would be to add this to a module that was included in all the tests.
class Test::Unit::TestCase
  # navigate the browser to the specified page in unittests/html
  def goto_page page
    new_url = $htmlRoot + page
    browser.goto new_url
  end
  # navigate the browser to the specified page in unittests/html IF the browser is not already on that page.
  def uses_page page
    new_url = $htmlRoot + page
    browser.goto new_url unless browser.url == new_url
  end
  def browser
    $ie
  end
end

topdir = File.join(File.dirname(__FILE__), '..')
Dir.chdir topdir do
  $all_tests = Dir["unittests/*_test.rb"]
  $xpath_tests = Dir["unittests/*_xpath_test.rb"]
end

$window_tests =
    [
     'attach_to_existing_window', # could actually run robustly as part of the core suite!
     'attach_to_new_window', # creates new window
     'close_window', # creates new window
     'frame_links', # visible
     'iedialog', # visible
     #ie-each
     'js_events', # is always visible
     'jscript',
     'modal_dialog', # modal is visible
     #new (named oddly)
     'open_close',
     'send_keys', # visible
    ].collect {|x| "unittests/windows/#{x}_test.rb"}

$non_core_tests = 
    ['popups', # has problems when run in a suite (is ok when run alone); 
               # must be visible
               # will be revised to use autoit 
               # takes 15 seconds to run
     'images', # save file must must be visible
#     'screen_capture', # is always visible; takes 25 seconds
     'filefield', # is always visible; takes 40 seconds 
     'minmax', # becomes visible
     'dialog' # visible
    ].collect {|x| "unittests/#{x}_test.rb"}

$core_tests = $all_tests - $non_core_tests - $window_tests - $xpath_tests

$ie = Watir::IE.new
$ie.speed = :fast

$myDir = File.expand_path(File.dirname(__FILE__))
$myDir.sub!( %r{/cygdrive/(\w)/}, '\1:/' ) # convert from cygwin to dos
# if you run the unit tests from a local file system use this line
$htmlRoot =  "file:///#{$myDir}/html/" 
# if you run the unit tests from a web server use this line
#   $htmlRoot =  "http://localhost:8080/watir/html/"