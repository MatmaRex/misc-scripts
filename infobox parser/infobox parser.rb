# coding: utf-8

class String
	def upcase_pl
		self.upcase.tr('ążśźęćńół', 'ĄŻŚŹĘĆŃÓŁ')
	end
	def downcase_pl
		self.downcase.tr('ĄŻŚŹĘĆŃÓŁ', 'ążśźęćńół')
	end
end

class Infobox < Hash
	attr_accessor :name
	def initialize name=nil
		@name = name
		super()
	end
	
	def [] a
		super(a.to_s)
	end
	def []= a, b
		super(a.to_s, b)
	end
	
	def rename f, t
		if self[t] and self[t].strip!=''
			# we already have this. just kill the other
			self.delete f
		else
			self[t] = self.delete f
		end
	end
	
	def self.extract_ib_from_text text, name=nil
		name_regex = case name
		when nil, false; /.+?/
		when Regexp;     name
		when String;     Regexp.escape name
		else;            name
		end
		
		# find the relevant part
		start_regex = /\{\{(#{name_regex})[ _]infobox/i
		match = text.match(start_regex)
		
		return nil if !match
		
		scanning = match.post_match
		
		infobox_text = []
		infobox_text << match.to_s
		
		# embedded templates...
		depth = 1
		until depth==0
			match = scanning.match(/[\s\S]+?(\{\{|\}\})/)
			return nil if !match
			
			infobox_text << match.to_s
			scanning = match.post_match
			depth += (match[1]=='}}' ? -1 : +1)
		end
		
		infobox_text.join('')
	end
	
	def self.find_in_text text, name=nil
		text = Infobox.extract_ib_from_text text, name
		return nil if !text || text.strip==''
		Infobox.parse text
	end
	
	def self.parse text
		ib = Infobox.new
		
		name = text.match(/\A\s*{{(.+?)[ _]infobox/)[1]
		text = text.sub(/\A\s*{{(.+?)[ _]infobox/, '')
		name[0] = name[0].upcase_pl # capitalize
		ib.name = name
		
		text = text.sub(/\s*\}\}\s*\Z/, '')
		
		# escape pipes in inner templates and links
		text.gsub!(/<<<(#+)>>>/, '<<<#\1>>>')
		3.times{ text.gsub!(/\{\{[^\}]+\}\}/){ $&.gsub(/\|/, '<<<#>>>') } }
		text.gsub!(/\[\[[^\]]+\]\]/){ $&.gsub(/\|/, '<<<#>>>') }
		
		
		# extract params
		pairs = text.scan(/\|\s*([^|=]+?)\s*=([\s\S]*?)(?=\||\Z)/)
		pairs.each do |name, data| # name is stripped, data isnt
			data = data.rstrip.sub(/\A[ \t]+/, '') # don't strip leading newlines; do strip trailing ones
			data = data.gsub(/<<<#>>>/, '|').gsub(/<<<#(#+)>>>/, '<<<\1>>>') # unescape
			
			ib[name] = data
		end
		
		ib
	end
	
	
	def pretty_format opts={}
		param_order = opts[:param_order] || self.keys
		reqd_params = opts[:reqd_params] || []
		
		# add the reqd params (as empty strings)
		hsh = (Hash[ reqd_params.zip( Array.new(reqd_params.length){''} ) ]).merge self
		
		crush = /\A(stopni|minut|sekund)(N|E|S|W)\Z/
		
		lines = []
		lines << "{{#{@name} infobox"
		
		maxlen = hsh.keys.map(&:length).max
		ordered_params = hsh.to_a.sort_by{|param, value| [param_order.index(param) || 9999, param] }
		lines += ordered_params.map.with_index do |(param, value), i|
			if param =~ crush
				kind = $2
				if ordered_params[i+1] and ordered_params[i+1][0] =~ crush and $2==kind # next is of the same kind (N/E/S/W)
					" | #{param} = #{value}{{#joinlines}}"
				else
					" | #{param} = #{value}"
				end
			else
				" | #{param.ljust maxlen} = #{value}"
			end
		end
		
		lines << "}}"
		lines.join("\n").gsub("{{#joinlines}}\n", '')
	end
end

