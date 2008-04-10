ActionController::Base.class_eval do
	# Check if it should render with the language defined in SimplyGlobal
	def render_with_simply_global(options = nil, &block)
		if should_use_locale?(options) 
			# If it's a partial, try to load it
			if options && options[:partial]
				logger.debug("It a partial at #{options[:partial]}")
				options[:partial] << "_" << SimplyGlobal.locale.to_s
				logger.debug("The new partial is #{options[:partial]}")
			elsif !options || (options && !options[:template])
				# Check if the template file exists
				template = "#{controller_name}/#{action_name}_#{SimplyGlobal.locale.to_s}"
				logger.debug("Check if #{RAILS_ROOT}/app/views/#{template} exists")
				options ||= {}
				options[:template] = template if File.exist? "#{RAILS_ROOT}/app/views/#{template}.html.erb"
			end
		end
	
		render_without_simply_global(options, block)
	end
	
	# Redirect with SimplyGlobal
	def redirect_to_with_simply_global(options = {}, response_status = {})
		# Check if a hash because redirect_to is called recursively
		# First time, the options is a hash
		# Second time, the options is a string containing the translated URL
		if options.is_a? Hash 
			if should_use_locale?(options)
logger.debug("LOCALE : #{SimplyGlobal.locale.to_s}")
				options[:locale] = SimplyGlobal.locale.to_s
			end
			options[:use_simply_global] = nil if options[:use_simply_global]
		end
		
		redirect_to_without_simply_global(options, response_status)
	end
	
	alias_method_chain :render, :simply_global
	alias_method_chain :redirect_to, :simply_global
	
	private
	# Check if it should render with the language defined in SimplyGlobal
	def should_use_locale?(options={})
		(SimplyGlobal.always_use? || options[:use_simply_global]) && SimplyGlobal.locale
	end
end
	
