ActionController::Base.class_eval do
	# Check if it should render with the language defined in SimplyGlobal
	def render_with_simply_global(options = nil, &block)
		logger.debug("BEF")
		if should_use_locale?(options) 
			logger.debug("IN")
			# If it's a partial, try to load it
			if options && options[:partial]
				logger.debug("It a partial at #{options[:partial]}")
				options[:partial] << "_" << SimplyGlobal.locale.to_s
				logger.debug("The new partial is #{options[:partial]}")
			elsif !options || (options && !options[:template])
				logger.debug("TEMP")
				# Check if the template file exists
				template = "#{controller_name}/#{action_name}_#{SimplyGlobal.locale.to_s}"
				logger.debug("Check if #{RAILS_ROOT}/app/views/#{template} exists")
				options ||= {}
				options[:template] = template if File.exist? "#{RAILS_ROOT}/app/views/#{template}.html.erb"
			end
		end
		logger.debug("OUT")
	
		render_without_simply_global(options, block)
	end
	
	# Redirect with SimplyGlobal
	def redirect_to_with_simply_global(options = {}, response_status = {})
		if should_use_locale?(options)
			options[:locale] = SimplyGlobal.locale.to_s			
		end
		
		options[:use_simply_global] = nil if options[:use_simply_global]
		
		redirect_to_without_simply_global(options, response_status)
	end
	
	alias_method_chain :render, :simply_global
	alias_method_chain :redirect_to, :simply_global
	
	private
	# Check if it should render with the language defined in SimplyGlobal
	def should_use_locale?(options=nil)
		(SimplyGlobal.always_use? || (options && options[:use_simply_global])) && SimplyGlobal.locale
	end
end
	
