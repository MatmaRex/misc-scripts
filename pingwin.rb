# coding: utf-8
require 'sunflower'
s = Sunflower.new.login


cwel = nil

# if false


users = %w[83.5. 83.10. 83.29. 83.30.]
kwds = [
	/[vw]+[iíj]+c?k[iíj]+nger/i,
	/beau|leinad/i,
	/pingwinojad|bocian|wandal penisowy/i,
	/mi[rłl]os[łl]aw/i,
	/b o c i a n|p i n g w i n o j a d/i,
	/achtung/i,
	/auschwitz($|[^-])/i,
	/h[ea]il\b/i,
	/abuse/i,
	/13\/88/i,
]

res = []


dosc = false
trap("INT"){dosc = true}
i = 0

users.each do |u|
	q = "action=query&list=usercontribs&uclimit=max&ucuserprefix=#{u}"
	# q += "&ucprop=user|title|timestamp|comment"
	q += "&ucend=2012-05-01T18:04:13Z"

	a = s.API q
	res += a['query']['usercontribs']
	
	while a['query-continue']
		a = s.API(q + "&uccontinue=" + a["query-continue"]["usercontribs"]["uccontinue"])
		res += a['query']['usercontribs']
		
		p i+=1
		break if dosc
	end
	
	break if dosc
end

puts 'got it'


cwel = res.select{|a| a['ns']==3 || a['commenthidden'] || (a['comment'] && kwds.any?{|k| k =~ a['comment'] }) }

p cwel.length

puts cwel.first(10).map{|a| a['comment'] }

require 'pp'
pp cwel.first 100

File.binwrite('res-marshal', Marshal.dump(res) )
File.binwrite('cwel-marshal', Marshal.dump(cwel) )

# else
# cwel = Marshal.load File.binread 'cwel-marshal'
# end


File.write 'data.txt', <<EOF
{| class="wikitable sortable"
! IP !! Czas !! Diff !! Strona !! Opis zmian
#{
	cwel.map{|a|
<<EOFF
|-
| #{a['user']}
| #{a['timestamp']}
| [https://pl.wikipedia.org/w/index.php?diff=#{a['revid']}&dir=prev]
| [https://pl.wikipedia.org/w/index.php?title=#{CGI.escape a['title']} #{a['title']}]
| <nowiki>#{a['comment']}</nowiki>
EOFF
	}.join("")
	}
|}
EOF

File.write 'data2.txt', "IP,Czas,Diff,Strona,Opis zmian\n" + cwel.map{|a| a.values_at('user', 'timestamp', 'revid', 'title', 'comment').map{|a| a.inspect}.join(",") }.join("\n")

