# coding: utf-8
require 'sunflower'
require 'pp'

wp = Sunflower.new('w:pl').login
wd = Sunflower.new('www.wikidata.org').login

list = RestClient.get('http://users.v-lo.krakow.pl/~matmarex/szablony-z-interwiki.txt').force_encoding('utf-8').strip.split(/\r?\n/)
list = wp.make_list 'pages', list.map{|e| e.sub %r|/opis$|, '' }

def lang_to_wiki e
	e.gsub('-','_')+'wiki'
end
def wiki_to_lang e
	e.sub(/wiki$/, '').gsub('_','-')
end

class TryWithId < StandardError; end

list.pages.each do |p|
	title = p.title
	
	if p.text !~ /\[\[(?!(wikt|meta|pomoc|commons|species|szablon):)[a-z-]{2,8}:/
		p = wp.page p.title+'/opis'
		if p.text !~ /\[\[(?!(wikt|meta|pomoc|commons|species|szablon):)[a-z-]{2,8}:/
			next
		end
	end
	
	puts ''
	puts title
	
	# can be changed and retried from below
	additional = {sites: 'plwiki', titles: title}
	
	begin
		iteminfo = wd.API({ action: 'wbgetentities' }.merge additional)
		sitelinks = iteminfo['entities'] && iteminfo['entities'].values[0]['sitelinks'] || {}
		sitelinks = sitelinks.values.map{|e| [ e['site'], e['title'] ] }.sort
		
		localinfo = wp.API(
			action: 'query',
			prop: 'langlinks',
			format: 'json',
			lllimit: 'max',
			titles: title
		)
		langlinks = localinfo['query']['pages'].values[0]['langlinks'] || []
		langlinks = (langlinks.map{|e| [ lang_to_wiki(e['lang']), e['*'] ] } << ['plwiki', title]).sort
		
		merged = (langlinks+sitelinks).uniq
		
		if iteminfo['entities'].keys == ["-1"]
			id = nil
			json = {}
		else
			id = iteminfo['entities'].keys[0]
			json = iteminfo['entities'].values[0]
		end
		
		json['sitelinks'] ||= {}
		json['labels'] ||= {}
		%w[pageid ns title lastrevid modified id type claims].each{|a| json.delete a }
		
		# introduce new links and labels
		merged.each do |k, v|
			site = k
			language = wiki_to_lang k
			
			if !json['sitelinks'][site]
				json['sitelinks'][site] = {site: site, title: v}
				json['labels'][language] = {language: language, value: v}
			else
				# should we do something here?...
			end
		end
		
		wdtoken = wd.API("action=tokens&type=edit")['tokens']['edittoken']
		result =  wd.API((id ? {id: id} : {}).merge({
			action: 'wbeditentity',
			token: wdtoken,
			summary: "imported sitelinks from the Polish Wikipedia",
			bot: true,
			data: json.to_json
		}))
		
		if result['success']
			new_id = result['entity']['id']
			if result['warnings'] && result['warnings']['messages']['0']['name'] == 'edit-no-change'
				puts 'NO CHANGES'
			else
				puts "SUCCESS#{new_id && new_id!=id ? " NEW" : ''}"
			end
			
			merged.each do |k, v|
				v = Regexp.escape v
				k = Regexp.escape wiki_to_lang k
				
				p.text.gsub!(/\[\[#{k}:#{v}\]\]\s*/, '')
			end
			if p.text != p.orig_text
				p.text.gsub! %r|\n+</includeonly>|, "\n</includeonly>"
				p.text.gsub! %r|\n+</noinclude>|, "\n</noinclude>"
				p.text.gsub! %r|<noinclude>\s*</noinclude>|, ''
			end
			
			result = p.save p.title, "przeniesienie interwiki do Wikidanych#{new_id && new_id!=id ? " – nowy element [[d:#{new_id}|#{new_id.upcase}]]" : ''}"
			if result
				puts "SAVED AT PL.WP"
			end
			
		elsif result['error']
			er = result['error']
			if er['code'] == "save-failed" \
					&& er['messages']['0']['name'] == "wikibase-error-sitelink-already-used" \
					&& id.nil?
				# turns out there might be something we can pin this to!
				puts "CONFLICT with #{er['messages']['0']['parameters'][2]}..."
				additional = { ids: er['messages']['0']['parameters'][2] }
				raise TryWithId # bleh
			elsif er['code'] == "save-failed"
				puts "FAILED"
			else
				pp result
			end
		else 
			pp result
		end
	rescue TryWithId
		retry
	end
end
