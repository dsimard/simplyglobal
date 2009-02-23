class SimplyGlobal
	# Looks like we have to init the class variables	
	@@languages = {}
	@@locale = nil
	
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
		add_fr_strings
	end
	
	# Use for render and redirect to ?
	def self.always_use?
		warn 'This method is deprecated and does nothing'
		true
	end
	
	def self.always_use=(b)
		warn 'This method is deprecated and does nothing'
		true
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
	
	private
	# Error messages in french
	ERROR_MESSAGE_FR = {
	  :even=>"doit être pair", :too_long=>"est trop long (maximum de %d caractères)",
	  :greater_than_or_equal_to=>"doit être plus grand ou égal à %d",
	  :empty=>"ne peut être vide", :exclusion=>"est reservé",
	  :too_short=>"est trop court (minimum de %d caractères)",
	  :equal_to=>"doit être égal à %d", :invalid=>"est non-valide",
	  :wrong_length=>"n'est pas de la bonne longueur (devrait être %d caractères)",
	  :less_than=>"doit être moins de %d", :confirmation=>"n'égale pas la confirmatioon",
	  :taken=>"a déjà été utilisé", :less_than_or_equal_to=>"doit être plus petit ou égal à %d",
	  :accepted=>"doit être accepté", :not_a_number=>"n'est pas un nombre", :odd=>"doit être impair",
	  :blank=>"ne peut pas être vide", :greater_than=>"doit être plus grand que %d",
	  :inclusion=>"n'est pas inclus dans la liste"
	}
	
	# Time ago
	TIME_AGO_FR = {
		"less than a minute" => "moins d'une minute",
		"1 minute" => "1 minute",
		"%d minutes" => "%d minutes",
		"less than %d seconds" => "moins de %d secondes",
		"half a minute" => "une demi-minute",
		"about 1 hour" => "environ 1 heure",
		"about %d hour" => "environ %d heures",
		"1 day" => "1 jour",
		"%d days" => "%d jours",
		"about 1 month" => "environ 1 mois",
		"%d months" => "%d mois",
		"about 1 year" => "environ 1 an",
		"over %d years" => "plus de %d ans",
	}
	
	# Months
	MONTHS_FR = {
		"January" => "Janvier",
		"February" => "Février",
		"March" => "Mars",
		"April" => "Avril",
		"May" => "Mai",
		"June" => "Juin",
		"July" => "Juillet",
		"August" => "Août",
		"September" => "Septembre",
		"October" => "Octobre",
		"November" => "Novembre",
		"December" => "Décembre"
	}
	
	# If the users sets the local on fr, change default error messages
	def self.add_fr_strings
		if @@locale == :fr
			ActiveRecord::Errors.default_error_messages = ERROR_MESSAGE_FR
			@@languages[:fr] = {} if @@languages[:fr].nil?
			@@languages[:fr].merge!(TIME_AGO_FR)
			@@languages[:fr].merge!(MONTHS_FR)
			
			# Add months in lowercase
			months_lower = {}
			MONTHS_FR.each_pair do |k,v|
				months_lower[k.downcase] = v.downcase
			end
			@@languages[:fr].merge!(months_lower)
			
			# Add months abbreviations
			months_abbrev = {}
			MONTHS_FR.each_pair do |k,v|
				en = k[0..2]				
				fr = v[0..2]
				# I have to include decembre and august in exceptions because there is
				# an accent in the abbreviation
				fr = v[0..3] if ["july", "september", "december", "august"].include?(k.downcase)
				months_abbrev[en] = fr
				months_abbrev[en.downcase] = fr.downcase
			end
			@@languages[:fr].merge!(months_abbrev)
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
