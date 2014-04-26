# coding: utf-8
require 'sunflower'


s = Sunflower.new.login

is_main = lambda{|t| !t.index(':') or !s.ns_local_for(t.split(':')[0]) }

anm = s.make_list('category', 'Kategoria:Artykuły na medal').select(&is_main)
anm_b = s.make_list('category', 'Kategoria:Byłe artykuły na medal').select(&is_main)
da = s.make_list('category', 'Kategoria:Dobre artykuły').select(&is_main)
# da_b = s.make_list('category', '').select(&is_main) # nie ma


output = []
output << '{| class=wikitable'
output << '! Autor'
output << '! Tekst'

do_break = false
trap("INT"){ do_break = true }

data = anm.map{|a| [a, 'AnM'] } + da.map{|a| [a, 'DA'] } + anm_b.map{|a| [a, 'BAnM'] }
data = data.uniq{|(title, type)| title }
data.sort.each do |title, type|
	break if do_break
	$stderr.puts title

	api_url = 'action=query&prop=revisions&format=json&rvprop=user%7Csize%7Csha1&rvlimit=max&titles='
	res = s.API_continued api_url+CGI.escape(title), 'revisions', 'rvcontinue'

	revisions = res["query"]["pages"].values.first["revisions"].reverse
	revisions.unshift({'user' => nil, 'size' => 0, 'sha1' => '...'})
	
	# compare revisions - if two have the same sha1, drop all between them
	sha1s = revisions.map{|a| a['sha1'] }.sort
	# find sha1s that appear more than once
	rep_sha1s = sha1s.group_by{|a| a}.values.select{|a| a.length>1 }.map{|a| a.uniq}.flatten
	
	rep_sha1s.each do |sha1|
		ind_a = revisions.index{|r| r['sha1'] == sha1 }
		ind_b = revisions.rindex{|r| r['sha1'] == sha1 }
		next if !ind_a or !ind_b or ind_a == ind_b
		# drop revs between the indices, including the last, excluding the first
		revisions[(ind_a+1)..ind_b] = []
	end
	
	user_bytes = {}

	revisions.each_cons(2) do |prev, cur|
		user_bytes[ cur['user'] ] ||= 0
		user_bytes[ cur['user'] ] += cur['size'] - prev['size']
	end

	max_user, max_bytes =* user_bytes.to_a.max_by{|user, bytes| bytes }
	creators = user_bytes.to_a.select{|u, b| b >= max_bytes/2 }.sort_by{|u, b| b }.reverse
	pp creators
	
	creators.sort.each do |(user, bytes)|
		output << '|-'
		output << '| ' + user
		output << "| #{type}: #{title}"
	end
end

output << '|}'

s.summary = 'test automatycznej aktualizacji listy'
page = s.page 'Wikipedia:Lista wikipedystów-autorów artykułów medalowych/tabela'
page.text = <<EOF % output.join("\n")
<!-- Uwaga
   --
   --  NIE ZMIENIAJ TEJ LISTY SAMEMU
   --
   -- Lista ta jest potrzebna do generowania automatycznie listy za pomocą bota 
   -- Zmiana tutaj powoduje zmiany listy więc przy następnej aktualizacji listy zostaną wprowadzone te edycje. 
   --  
   -- Jeżeli widzisz tutaj błędy poinformuj wikipedystę PMG (zalecane), napisz o problemie w dyskusji tej strony
   -- lub (jeżeli koniecznie musisz) wyedytuj stronę źródłową.
   -->  

''Kursywą'' zaznaczono byłe artykuły na medal.

%s

[[Kategoria:Artykuły na medal| ]]
EOF

page.save
