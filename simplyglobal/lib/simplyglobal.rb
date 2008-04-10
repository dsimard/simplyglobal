class SimplyGlobal
	# Looks like we have to init the class variables
	
	@@languages = {}
	@@locale = nil
	@@always_use = true
	
	# Return the locale
	# If default, returns nil
	def self.locale
		@@locale
	end
	
	# Sets the locale
	# If string, it will be converted to a symbol
	def self.locale=(x)
		x = x.to_sym if x.is_a? String 	
		@@locale=x 
	end
	
	# Use for render and redirect to ?
	def self.always_use?
		@@always_use
	end
	
	def self.always_use=(b)
		@@always_use = b
	end
		
	# Add a language hash
	def self.add_language_hash(language, language_hash)
		raise "can't use :all as language id" if language == :all
		@@languages ||= {}
		@@languages[language] = language_hash
	end
	
	# Return a string from the hash selected by the locale
	# If locale is not set or the string does not exist, it returns the string itself
	def self.get_string(str, language=nil)	
		# Reload the language file if in development
		if RAILS_ENV == "development"
			file = "#{RAILS_ROOT}/config/initializers/simplyglobal.rb"
			load(file) if File.exist?(file)
		end
		
		# If language is :all, return an array of all translations
		if language == :all
			all = {}
			@@languages.each do |key, value|
				all[key] = value[str] if value[str]				
			end
			
			return all
		else
			# Get the locale to use
			locale = language
			locale ||= @@locale
		
			# Get the string in its localized version	
			translated = @@languages[locale][str] if locale && @@languages[locale]
			translated ||= str
			
			return translated			
		end
	end
end

class String
	# Translate a string using SimplyGlobal
	def t(*args)	
		# If the first arg is a symbol, use it for the translation
		if args && args[0] && args[0].is_a?(Symbol)
			locale = args[0] 
			
			# Remove the first argument
			args.slice!(0)
		end
		
		result = SimplyGlobal.get_string(self, locale)
		
		# Apply things like %d, %s, etc...
		if args && !args.empty?
			if result.is_a?(Hash)
				result = result.each do | key, value |
					result[key] = value%args
				end
			else
				result = result%args 
			end
		end
		
		result
	end
end
