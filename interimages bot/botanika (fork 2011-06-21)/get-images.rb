# InterImages v 0.2 by Matma Rex
# matma.rex@gmail.com
# released under CC-BY-SA 3.0


def wiki_normalize filename # let's just ignore %-escapes.
	filename[0].upcase + filename[1..-1].gsub('_',' ')
end

def get_images home, name
	# use regex, since
	# http://pl.wikipedia.org/w/api.php?action=query&prop=images&titles=A&format=jsonfm
	# has a lot of false positives
	image = /
		(?:
			\[\[ # [[
			[^:\[\]\n]+:\s* # Image:, Grafika:, etc.
			|
			\|\s*[^=\|]+\s*=\s* # infobox entry
			(?:  [^:\[\]\n]+:\s*  )? # Image:, Grafika:, etc. - optional
		)
		([^\[\]\|\n]+?\.(?:jpe?g|png|svg|tiff?)) # something that resembles an image filename
		\s*
		(?:\||\]\]) # | or ]]
	/ix
	
	homesym = home.to_sym
	
	flowers={}
	flowers[homesym] = Sunflower.new "#{home}.wikipedia.org"
	flowers[homesym].warnings = false

	res = flowers[homesym].API "action=query&prop=langlinks&lllimit=500&titles=#{CGI.escape name}"
	interwiki = res['query']['pages'].first['langlinks']
	return [{}, {}] if !interwiki
	
	interwikimap={}
	interwiki.each do |iw|
		lang, iname = iw['lang'], iw['*']
		interwikimap[lang] = iname
	end
	
	
	page = Page.new name, home
	scan = page.text.scan(image).flatten.map{|a| wiki_normalize a}
	if scan.length>0
		images={}
	else
		images = []
		interwiki.each do |iw|
			lang, iname = iw['lang'], iw['*']
			langsym = lang.to_sym
			flowers[langsym] ||= Sunflower.new "#{lang}.wikipedia.org"
			flowers[langsym].warnings = false
			
			next if iname.include? '#'
			page = Page.new iname, lang
			
			scan = page.text.scan(image).flatten.map{|a| wiki_normalize a}
			images += scan.zip([lang] * scan.length).flatten.each_slice(2).to_a
		end
		
		images.delete_if{|img, lang| scan.include? img}
		
		images = images.inject({}){|hsh, pair| img, lang = *pair; hsh[img]||=[]; hsh[img]<<lang; hsh}
	end
	
	[images, interwikimap]
end
