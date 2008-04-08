module ApplicationHelper
  
  def define_js_function(function_name, &block)
    parens = function_name.kind_of?(Symbol) ? "()" : ""
    update_page_tag do | page |
    	page << "function #{function_name}#{parens} {"
      yield page
    	page << "}"
    end	
  end
  
  
  def current_tag(tag_name, class_is_current_if, &block)
    puts class_is_current_if
    content_tag(tag_name, { :class => (:current if class_is_current_if) }, &block)
  end
  
  
end
