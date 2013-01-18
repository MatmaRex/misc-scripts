# coding: utf-8
require 'rest-client'
require 'sunflower'
require 'nokogiri'

class MatchData
	# allow accessing by symbols (named captures)
	def values_at *indices
		indices.map{|i| self[i]}
	end
end

# Version of any software.
class Array
	include Comparable
end


targets = {
	amaya: 'Szablon:Ostatnie stabilne wydanie/Amaya',
	aqq: 'Szablon:Ostatnie stabilne wydanie/AQQ',
	camino: 'Szablon:Ostatnie stabilne wydanie/Camino',
	ccleaner: 'Szablon:Ostatnie stabilne wydanie/CCleaner',
	comodocis: 'Szablon:Ostatnie stabilne wydanie/Comodo Internet Security',
	dillo: 'Szablon:Ostatnie stabilne wydanie/Dillo',
	
	chrome: 'Szablon:Ostatnie stabilne wydanie/Google Chrome',
	opera: 'Szablon:Ostatnie stabilne wydanie/Opera',
	seamonkey: 'Szablon:Ostatnie stabilne wydanie/SeaMonkey',
	safari: 'Szablon:Ostatnie stabilne wydanie/Safari',
}

# common regexen
#   (?<v>[\d.]+)
# 
#   (?<d>\d{1,2})
#   (?<m>\d{1,2})
#   (?<m>[A-Z][a-z]+)
#   (?<y>\d{4})

data = {
	amaya: {
		url: 'http://www.w3.org/Amaya/User/New.html',
		version: {
			css: 'h2',
			regex: /Amaya (?<v>[\d.]+)/
		},
		date: {
			css: 'h2+p',
			regex: /(?<d>\d{1,2}) (?<m>[A-Z][a-z]+) (?<y>\d{4})/
		}
	},
	aqq: {
		url: 'http://www.aqq.eu/',
		version: {
			css: '.moduletable h3+div',
			regex: /AQQ (?<v>[\d.]+)/
		},
		date: :today
	},
	camino: {
		url: 'http://caminobrowser.org/download/',
		version: {
			regex: /Camino (?<v>[\d.]+) is the latest stable release of Camino/
		},
		date: :today
	},
	ccleaner: {
		url: 'http://www.piriform.com/ccleaner/download',
		css: '.versionHistory li',
		regex: /\A\s*v(?<v>[\d.]+)\s*\((?<d>\d{1,2}) (?<m>[A-Z][a-z]+) (?<y>\d{4})\)/
	},
	comodocis: {
		url: 'http://www.comodo.com/home/download/release-notes.php?p=cis',
		css: 'h4',
		regex: /Version (?<v>[\d.]+): (?<d>\d{1,2}) (?<m>[A-Z][a-z]+), (?<y>\d{4})/
	},
	dillo: {
		url: 'http://www.dillo.org/download.html',
		version: {
			css: 'body p b',
			regex: /dillo-(?<v>[\d.]+)/
		},
		date: :today
	},
	opera: {
		url: 'http://www.opera.com/docs/changelogs/windows/',
		version: {
			css: '.diamonds li a',
			regex: /Opera (?<v>[\d.]+)/ # todo: may, in fact, catch betas
		},
		date: {
			css: '.diamonds li',
			regex: /(?<d>\d{2})\.(?<m>\d{2})\.(?<y>\d{4})/
		}
	},
	chrome: {
		url: 'http://googlechromereleases.blogspot.com/search/label/Stable%20updates',
		version: {
			regex: /updated to (?<v>[\d.]+)/
		},
		date: {
			css: '.post-subhead',
			regex: /(?:[A-Z][a-z]+), (?<m>[A-Z][a-z]+) (?<d>\d{1,2}), (?<y>\d{4})/
		}
	},
	chrometest: {
		url: 'http://googlechromereleases.blogspot.com/search/label/Beta%20updates',
		version: {
			regex: /updated to (?<v>[\d.]+)/
		},
		date: {
			css: '.post-subhead',
			regex: /(?:[A-Z][a-z]+), (?<m>[A-Z][a-z]+) (?<d>\d{1,2}), (?<y>\d{4})/
		}
	},
	seamonkey: {
		url: 'http://www.seamonkey-project.org/releases/',
		version: {
			css: 'h2',
			regex: /SeaMonkey (?<v>[\d.]+)/
		},
		date: {
			css: '.release-date',
			regex: /Released (?<m>[A-Z][a-z]+) (?<d>\d{1,2}), (?<y>\d{4})/
		}
	},
	safari: {
		url: 'https://swdlp.apple.com/cgi-bin/WebObjects/SoftwareDownloadApp.woa/wa/getProductData?localang=pl_pl&grp_code=safari&returnURL=http://www.apple.com/pl/safari/download&isMiniiFrameReq=N',
		version: {
			css: 'label.platform',
			regex: /\ASafari (?<v>[\d.]+)/
		},
		date: :today
	},
	ubuntu: {
		url: 'http://www.ubuntu.com/download/ubuntu/download',
		version: {
			css: '#vernum'
		},
		date: :today
	},
	openttd: {
		url: 'http://www.openttd.org/en/download-stable',
		regex: /Latest release in stable is (?<v>[\d.]+), released on (?<y>\d{4})-(?<m>\d{1,2})-(?<d>\d{1,2})/
	},
	simutrans: {
		url: 'http://www.simutrans.com/download.htm',
		css: 'h2',
		regex: /Latest official release:\s+Simutrans (?<v>[\d.]+) \((?<d>\d{1,2})-(?<m>[A-Z][a-z]+)-(?<y>\d{4})\)/
	},
	battleforwesnoth: {
		url: 'http://www.wesnoth.org/',
		version: {
			css: '.download',
			regex: /Download Wesnoth (?<v>[\d.]+)/
		},
		date: :today
	}
}

s = Sunflower.new.login
data.each_pair do |key, info|
	next if !targets[key]
	
	# version
	url = (info[:version]||{})[:url] || info[:url]
	css = (info[:version]||{})[:css] || info[:css]
	regex = (info[:version]||{})[:regex] || info[:regex]
	
	version = RestClient.get url
	version = (Nokogiri::HTML version).at(css).content.to_s if css
	version = version.match(regex)[:v] if regex
	
	# date
	if info[:date] == :today
		#date = Time.now.strftime '%Y|%m|%d <!-- bot używa aktualnej daty -->'
		date = '<dzis?>'
	else
		url = (info[:date]||{})[:url] || info[:url]
		css = (info[:date]||{})[:css] || info[:css]
		regex = (info[:date]||{})[:regex] || info[:regex]
		
		date = RestClient.get url
		date = (Nokogiri::HTML date).at(css).content.to_s if css
		date = date.match(regex).values_at(:y, :m, :d) if regex
		
		
		# sanitize the date
		year, mon, day = *date # these are all strings right now
		date = Time.utc(
			(year.length < 4 ? '20'+year : year).to_i, # make sure year is 4 digits long
			(mon.to_i == 0 ? mon.downcase[0..2] : mon.to_i), # month is a three-letter name or a number
			day.to_i # day is... fine.
		)
		date = date.strftime '%Y|%m|%d'
	end
	
	
	p = Page.new targets[key]
	found_version = p.text.match(/Ostatnio_wydana_wersja\s*=\s*([\d.]+)/)[1] rescue nil
	found_date = p.text.match(/Data_ostatniego_wydania\s*=\s*\{\{[dD]ata wydania\|([\d\|]+)\}\}/)[1] rescue nil
	
	puts targets[key]
	puts "#{version} vs #{found_version or '<brak/nierozpoznano>'}"
	puts "#{date} vs #{found_date or '<brak/nierozpoznano>'}"
	puts ''
end

