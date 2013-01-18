# coding: utf-8

require 'sunflower'
require 'parallel_each'

s = Sunflower.new 'commons.wikimedia.org'

cat = 'Category:Featured pictures on Wikimedia Commons'
base = {action:'query', list:'categorymembers', cmprop:'title', cmlimit:500}

r = s.API base.merge(cmtitle: cat)
list = r['query']['categorymembers'].map{|v| v['title']}

while r['query-continue']
	r = s.API base.merge(cmtitle: cat).merge(cmcontinue: r['query-continue']['categorymembers']['cmcontinue'])
	list += r['query']['categorymembers'].map{|v| v['title']}
end

list = list.select{|a| a.start_with? 'File:'}





preferred_langs = %w[pl en de fr it es ja ru nl pt]

results = []
if File.exist? 'medale-marshal'
	results = Marshal.load File.binread 'medale-marshal'
else
	tt=Thread.new{loop{ File.open('medale-marshal', 'w'){|f| f.write Marshal.dump results}; sleep 30 } }

	list.p_each(10) do |img|
		res = s.API(action:'query', prop:'globalusage', gulimit:500, titles:img)
		data = res['query']['pages'].first['globalusage']
		
		ll = nil
		preferred_langs.each do |lang|
			uses = data.select{|a| a['wiki']=="#{lang}.wikipedia.org"}.map{|a| a['title']}
			uses = uses.reject{|a| a.include? ':'}
			uses = uses.map{|a| "[[:#{lang}:#{a}]]"}
			uses[3..-1]='...' if uses.length>3
			
			if !uses.empty?
				ll = lang
				results << "#{img}|{{#{lang=='pl' ? 'tak' : 'nie'}}} #{uses.join ', '}"
				break
			end
		end
		
		# image unused in all major languages
		if !ll
			results << "#{img}|{{nie}}"
		end
		
		puts "#{img} / #{ll}"
	end
	
	tt.kill
	File.open('medale-marshal', 'w'){|f| f.write Marshal.dump results}
end

base = "Wikiprojekt:Ilustrowanie/Medalowe zasoby Commons"
s = Sunflower.new('pl.wikipedia.org').login
s.summary = "aktualizacja list"

results.sort.each_slice(200).with_index do |res, i|
	p = Page.new "#{base}/#{i+1}", 'pl'
	p.text = ["Patrz: [[Wikiprojekt:Ilustrowanie/Medalowe zasoby Commons]].", '', '<gallery>', res, '</gallery>'].flatten.join "\n"
	p.save
	
	# f = File.open "medalowe#{i+1}.txt", 'w'
	# f.puts '<gallery>'
	# f.puts res
	# f.puts '</gallery>'
	# f.close
end
