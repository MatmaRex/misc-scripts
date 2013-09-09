# coding: utf-8
require 'sunflower'
require 'rest-client'
require 'nokogiri'
require 'progressbar'

def iw_translate article, sf, tolang
	res = sf.API action:'query', prop:'langlinks', lllimit:500, titles:article, redirects:true
	iwlinks = (res['query']['pages'].values.first['langlinks'] || []).map{|hsh| [ hsh['lang'], hsh['*'] ] }
	(Hash[iwlinks])[tolang]
rescue
	require 'pp'
	pp res
	raise $!
end

link_re = /\[\[(?:([^\|\]]+)\|)?([^\|\]]+)\]\]/
tpl_re = /\{\{(([^\|\}]+))(\|({{[^\{\}]+}}|[^\|\{\}])+)+\}\}/


unless ARGV.length.between? 3,4
	puts <<EOF
usage:
  to dump translated locally:
    ruby iwtranslate.rb xx From_title yy
  to upload to wiki:
    ruby iwtranslate.rb xx From_title yy To_title
  where "xx" is the source language and "yy" is the target language.
EOF
	exit
end

fromlng, fromtitle, tolng, totitle = *ARGV


s = Sunflower.new("#{fromlng}.wikipedia.org")
p = Page.new fromtitle, fromlng

iwcodes = s.API 'action=query&meta=siteinfo&siprop=interwikimap&sifilteriw=local'
iwcodes = iwcodes['query']['interwikimap'].map{|h| h['prefix'] }



pbar = ProgressBar.new("Links", p.text.scan(link_re).length)
p.text.gsub!(link_re) do
	pbar.inc
	target, alttext, all = $1||$2, $2, $&
	
	if target.downcase =~ /^(file|image|media):/
		all
	elsif target =~ /^(#{Regexp.union iwcodes}):/
		all.sub(/^\[\[:?/, '[[:') # dodaj dwukropek
	else
		colon = (target.downcase =~ /^category/ ? ':' : nil)
		"[[#{colon}#{iw_translate(target, s, tolng) || "#{colon ? '' : ':'}#{fromlng}:#{target}"}|#{alttext}]]"
	end
end
pbar.finish

pbar = ProgressBar.new("Templates", p.text.scan(tpl_re).length)
p.text.gsub!(tpl_re) do
	pbar.inc
	name, all = $1, $&
	
	resp = RestClient.post(
		"http://tools.wikimedia.pl/~beau/cgi-bin/convert.pl",
		noempty: true,
		oneline: true,
		source: all
	)
	transl = Nokogiri.HTML(resp).at('#mw_content textarea').text
	
	if transl and transl.strip != ''
		# citation template
		transl.strip
	elsif name.strip.downcase == 'main'
		all
			.sub(/main/i, 'osobny artykuł')
			.gsub(/\|([^|}]+)/){ '|' + (iw_translate($1, s, tolng) || ":#{fromlng}:#{$1}") }
	else
		"[[#{iw_translate('Template:'+name, s, tolng) || ":#{fromlng}:#{'Template:'+name}"}]] #{all}"
	end
end
pbar.finish

if totitle
	puts "Login: user/pass:"
	s2 = Sunflower.new("#{tolng}.wikipedia.org").login STDIN.gets.strip, STDIN.gets.strip
	tranlated_page = Page.new totitle, tolng
	tranlated_page.text = p.text + "\n[[:#{fromlng}:#{fromtitle}]]"
	tranlated_page.save totitle, "kopia z [[#{fromlng}:#{fromtitle}]] z przetłumaczonymi linkami, kategoriami i szablonami"
else
	p.text = p.text + "\n[[:#{fromlng}:#{fromtitle}]]"
	p.dump
end
