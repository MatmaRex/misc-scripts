require 'sunflower'

s = Sunflower.new.login
base = "action=query&generator=allpages&gapfilterredir=redirects&gaplimit=1000&prop=revisions&rvprop=content&gapfrom="
cont = false
list = []

trap("INT") do 
	puts list[-20..-1]
end

if File.exist? 'lista-marshal'
	list = Marshal.load File.binread 'lista-marshal'
	cont = list[-1][0]
	list.pop
else
	res = s.API(base)
	
	redirs = res['query']['pages'].map{|pageid, a| [a['title'], a['revisions'][0]['*']]}
	# funny stuff, some pages are broken and their text is... false
	list += redirs.select{|title, cont| cont.count('#')>1 rescue puts('!!!',title)&&false}
	
	cont = res['query-continue']['allpages']['gapfrom'] rescue nil
end

while cont
	puts cont, list.length
	
	res = s.API(base+CGI.escape(cont))
	
	redirs = res['query']['pages'].map{|pageid, a| [a['title'], a['revisions'][0]['*']]}
	# funny stuff, some pages are broken and their text is... false
	list += redirs.select{|title, cont| cont.count('#')>1 rescue puts('!!!',title)&&false}
	
	cont = res['query-continue']['allpages']['gapfrom'] rescue nil
	
	Marshal.dump list, f=File.open('lista-marshal', 'w')
	f.close
end

Marshal.dump list, f=File.open('lista-marshal', 'w')
f.close
