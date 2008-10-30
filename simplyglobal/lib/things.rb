ActionController::Base.class_eval do
	# Check if it should render with the language defined in SimplyGlobal
	def render_with_simply_global(options = nil, extra_options = {}, &block)
		if should_use_locale?(options) 
			# If it's a partial, try to load it
			if options && options[:partial]
				logger.debug("It's a partial at #{options[:partial]}")
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
	
		render_without_simply_global(options, extra_options, &block)
	end
	
	# Redirect with SimplyGlobal 
	def redirect_to_with_simply_global(options = {}, response_status = {})
		# Check if a hash because redirect_to is called recursively
		# First time, the options is a hash
		# Second time, the options is a string containing the translated URL
		if options.is_a? Hash 
			if should_use_locale?(options)
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
		options ||= {}
		(options[:use_simply_global]) && SimplyGlobal.locale
	end
end

ActionView::Base.class_eval do
	def render_with_simply_global(options = {}, old_local_assigns = {}, &block)
		if (options[:use_simply_global]) && options[:partial]
			logger.debug("It's a partial at #{options[:partial]}")
			new_path = "#{options[:partial]}_#{SimplyGlobal.locale.to_s}"
			logger.debug("New path : #{new_path}")
			
			check = new_path.split(/\//) 
			check[check.length-1] = "_" << check[check.length-1]
			check.insert(0, @template.controller.controller_name) if check.length == 1
			check = check.join("/")
			
			logger.debug("CHECK : " + check)
			
			check = "#{RAILS_ROOT}/app/views/#{check}.html.erb"
			options[:partial] = new_path if File.exist? check
		end
		
		render_without_simply_global(options, old_local_assigns, &block)
	end 

	alias_method_chain :render, :simply_global
end

ActionView::Helpers::DateHelper.class_eval do
	def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
		from_time = from_time.to_time if from_time.respond_to?(:to_time)
		to_time = to_time.to_time if to_time.respond_to?(:to_time)
		distance_in_minutes = (((to_time - from_time).abs)/60).round
		distance_in_seconds = ((to_time - from_time).abs).round
	
		case distance_in_minutes
		  when 0..1
			return (distance_in_minutes == 0) ? "less than a minute".t : "%d minute".t(1) unless include_seconds
			case distance_in_seconds
			  when 0..4 then "less than %d seconds".t(5)
			  when 5..9 then "less than %d seconds".t(10)
			  when 10..19 then "less than %d seconds".t(20)
			  when 20..39 then "half a minute"
			  when 40..59 then "less than a minute".t
			  else "%d minute".t(1)
			end
	
		  when 2..44 then "%d minutes".t(distance_in_minutes)
		  when 45..89 then "about 1 hour".t
		  when 90..1439 then "about %d hours".t((distance_in_minutes.to_f / 60.0).round)
		  when 1440..2879 then "1 day".t
		  when 2880..43199 then "%d days".t((distance_in_minutes / 1440).round)
		  when 43200..86399 then "about 1 month".t
		  when 86400..525599 then "%d months".t((distance_in_minutes / 43200).round)
		  when 525600..1051199 then "about 1 year".t
		  else "over %d years".t((distance_in_minutes / 525600).round)
		end
	end	
end
