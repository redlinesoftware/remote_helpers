# All remote actions are automatically enabled to show a gui indicator during a remote call with this plugin.
#
# == Note
#
# If you have installed another plugin that overrides rails methods such as <tt>remote_function</tt>,
# <tt>form_remote_tag</tt>, or <tt>submit_to_remote</tt> then this plugin may not work as intended. So if
# you find that some methods aren't working as expected then this could be a possible problem.  This also
# holds for the other plugins overriding the same methods.

# Default values that can be overridden in <tt>environment.rb</tt>
#
# * <tt>default_image</tt> - The default image indicator
# * <tt>default_id</tt> - The default css id given to the indicator image
#
# == Examples
#
# * <tt>RemoteIndicator.default_image = 'spinner.gif'</tt>
# * <tt>RemoteIndicator.default_id = 'spinner'</tt>
class RemoteIndicator
  @@default_image = 'indicator.gif'
  cattr_accessor :default_image

  @@default_id    = 'indicator'
  cattr_accessor :default_id
end

# Progress indication is built in using the <tt>indicator</tt> method and the optional <tt>:indicator</tt> option for remote calls.
# See <tt>remote_function</tt> documentation for more information.
#
# The <tt>:indicator</tt> options adds the functionality of using a remote indicator (an image) during the execution
# of all remote functions.
#
# Functionality added to disable the form by default during a remote call using methods such as <tt>remote_function</tt>,
# <tt>form_remote_tag</tt>, <tt>remote_form_for</tt> and <tt>submit_to_remote</tt>.
#
# This is useful to prevent a user from submitting a form twice while a remote call is in progress
# since the submit button will be disabled and therefore not clickable.
#
# Additional options:
# * <tt>:indicator</tt> - The css id of an element to show and hide during a remote call.
#   Defaults to <tt>RemoteIndicator.default_id</tt>.
#   Set :indicator to false if no indicator is to be used.
# * <tt>:disable_form</tt> - Specifies if the form will disable or not during the remote call.
#   Defaults to true.
# Set :disable_form to false to keep the form enabled during a remote function call.
module ActionView::Helpers::PrototypeHelper

  # Creates an indicator image.  The options supplied are the same used with +image_tag+
  #
  # Current and additional options are:
  # * <tt>:id</tt> - The css id of the indicator image.  Defaults to <tt>RemoteIndicator.default_id</tt>
  # * <tt>:hide</tt> - Hide the image by default.  Defaults to true.
  #
  # === Examples
  # 
  # Using a custom indicator id
  #   <%= indicator :id => 'spinner' %>
  #
  # Using many indicators on the same page 
  #   <% collection.each do |id| %>
  #     <%= link_to_remote :url => {:action => 'dosomething'}, :indicator => "link#{id}" %> <%= indicator :id => "link#{id}" %>
  #   <% end %>
  def indicator(options = {})
    options.reverse_merge!(:id => RemoteIndicator.default_id, :hide => true)

    options[:style] = [options[:style], 'display:none'].compact.join(';') if options.delete(:hide)

    image_tag RemoteIndicator.default_image, options
  end

  alias :remote_function_old :remote_function

  # === Examples
  #
  # * To use the default values - <tt><%= remote_function :url => {:action => 'dosomething'} %> <%= indicator %></tt>
  # * To disable the gui indicator - <tt><%= remote_function :url => {:action => 'dosomething'}, :indicator => false %></tt>
  # * To use a custom :id - <tt><%= remote_function :url => {:action => 'dosomething'}, :indicator => 'custom' %> <%= indicator :id => 'custom' %></tt>
  #
  # === Examples using :disable_form
  # See module documentation for usage of the <tt>:disable_form</tt> option.
  #
  # Automatically disables a form (no additional options)
  #   <%= remote_function(:update => 'someid', :submit => 'myform', :url => {:action => 'dosomething'}) %>
  #
  # Prevents a form from being disabled
  #   <%= remote_function(:update => 'someid', :submit => 'myform', :url => {:action => 'dosomething'}, :disable_form => false) %>
  #
  # No form disabled as no :submit option is provided
  #   <%= remote_function(:update => 'someid', :url => {:action => 'dosomething'}) %>
  #
  # ==== IMPORTANT GOTCHA
  # Don't forget to use <tt><%= indicator %></tt> on the page with remote calls or the javascript will fail
  # and your action won't complete (In development mode you will be shown an alert if the indicator has not been defined).
  # This doesn't apply if you set the indicator to false... <tt>:indicator => false</tt>.
  def remote_function(options)
    options.reverse_merge! :indicator => RemoteIndicator.default_id

    if indicator = options.delete(:indicator)
      before_js = "Element.show('#{indicator}')"
      event_options = {
        :before => (RAILS_ENV == 'development' ? "try { #{before_js} } catch(e) { alert('The remote helper indicator \\'#{indicator}\\' has not been defined.\\n\\nEither define the indicator with the \\'indicator\\' method or pass :indicator => false as an option to disable the indicator.') }" : before_js),
        :complete => "Element.hide('#{indicator}')"
      }

      add_callback_code! options, event_options
    end

    add_disable_options! options
    remote_function_old(options)
  end

  alias :form_remote_tag_old :form_remote_tag
  
  # See module documentation for usage of the <tt>:disable_form</tt> option.
  # See <tt>remote_function</tt> documentation for usage of the <tt>:indicator</tt> option.
  #
  # === Examples
  #
  # Automatically disables a form (no additional options)
  #   <%= form_remote_tag(:url => {:action => 'dosomething'}) %>
  #
  # Prevents the form from being disabled
  #   <%= form_remote_tag(:url => {:action => 'dosomething'}, :disable_form => false) %>
  def form_remote_tag(options = {})
    options.reverse_merge! :disable_form => true

    if options.delete(:disable_form)
      add_callback_code! options, {:before => "var form = this; Form.disable(form)", :complete => "Form.enable(form)"}
    end
    
    form_remote_tag_old(options)
  end

  alias :submit_to_remote_old :submit_to_remote

  # See module documentation for usage of the <tt>:disable_form</tt> option.
  # See <tt>remote_function</tt> documentation for usage of the <tt>:indicator</tt> option.
  #
  # The option <tt>:disable_form</tt> disables a form (specified using the :submit option)
  #
  # === Example
  #
  # Automatically disables a form (no additional options)
  #   <%= submit_to_remote('name', 'Submit', :submit => 'myform', :url => {:action => 'dosomething'}) %>
  #
  # Prevents a form from being disabled
  #   <%= submit_to_remote('name', 'Submit', :submit => 'myform', :url => {:action => 'dosomething'}, :disable_form => false) %>
  def submit_to_remote(name, value, options = {})
    add_disable_options! options
    submit_to_remote_old(name, value, options)
  end

private
  def add_disable_options!(options)
    options.reverse_merge! :disable_form => true

    if options.delete(:disable_form) && options[:submit]
      add_callback_code! options, {:before => "Form.disable('#{options[:submit]}')", :complete => "Form.enable('#{options[:submit]}')"}
    end
  end
  
  def add_callback_code!(options, code)
    options[:before] = [code[:before], options[:before]].compact.join(';')
    options[:complete] = [code[:complete], options[:complete]].compact.join(';')
  end
end
