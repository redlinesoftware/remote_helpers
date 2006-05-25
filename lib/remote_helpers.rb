# put the defaults in a seperate namespace
# shorter and more related path name for overiding the options
class RemoteIndicator
  @@default_image = 'indicator.gif'
  cattr_accessor :default_image

  @@default_id    = 'indicator'
  cattr_accessor :default_id
end

module ActionView::Helpers::PrototypeHelper

  def indicator(options = {:id => RemoteIndicator.default_id})
    options.reverse_merge! :hide => true

    if options.delete(:hide)
      options[:style] = '' if options[:style].nil?
      options[:style] = (options[:style] || '') + ';display:none'
    end

    image_tag RemoteIndicator.default_image, options
  end

  alias :remote_function_old :remote_function

  # Set the :indicator option to an id of an element to show and hide during a remote call.
  # Set :indicator to false if no indicator is to be used (default is RemoteIndicator::DEFAULT_INDICATOR_ID).
  def remote_function(options)
    options.reverse_merge! :indicator => RemoteIndicator.default_id

    if indicator = options.delete(:indicator)
      options[:before] = "Element.show('#{indicator}');#{options[:before]}"
      options[:complete] = "Element.hide('#{indicator}');#{options[:complete]}"
    end

    remote_function_old(options)
  end

  alias :form_remote_tag_old :form_remote_tag
  
  # The option :disable_form disables a form (specified using the :submit option)
  # during a remote call if set to true (default).
  # Set :disable_form to false to keep the form enabled during a remote form submission.
  def form_remote_tag(options = {})
    options.reverse_merge! :disable_form => true

    if options.delete(:disable_form)
      options[:before] = "var form = this; Form.disable(form);#{options[:before]}"
      options[:complete] = "Form.enable(form);#{options[:complete]}"
    end
    
    form_remote_tag_old(options)
  end

  alias :submit_to_remote_old :submit_to_remote

  # The option :disable_form disables a form (specified using the :submit option)
  # during a remote call if set to true (default).
  # Set :disable_form to false to keep the form enabled during a remote form submission.
  def submit_to_remote(name, value, options = {})
    options.reverse_merge! :disable_form => true

    if options.delete(:disable_form)
      options[:before] = "Form.disable('#{options[:submit]}');#{options[:before]}"
      options[:complete] = "Form.enable('#{options[:submit]}');#{options[:complete]}"
    end

    submit_to_remote_old(name, value, options)
  end
end
