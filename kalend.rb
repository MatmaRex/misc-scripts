# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

msc = %w[kotek stycznia lutego marca kwietnia maja czerwca lipca sierpnia września października listopada grudnia]

order = 
	(1..31).map{|a| "#{a} #{msc[1]}"} +
	(1..29).map{|a| "#{a} #{msc[2]}"} +
	(1..31).map{|a| "#{a} #{msc[3]}"} +
	(1..30).map{|a| "#{a} #{msc[4]}"} +
	(1..31).map{|a| "#{a} #{msc[5]}"} +
	(1..30).map{|a| "#{a} #{msc[6]}"} +
	(1..31).map{|a| "#{a} #{msc[7]}"} +
	(1..31).map{|a| "#{a} #{msc[8]}"} +
	(1..30).map{|a| "#{a} #{msc[9]}"} +
	(1..31).map{|a| "#{a} #{msc[10]}"} +
	(1..30).map{|a| "#{a} #{msc[11]}"} +
	(1..31).map{|a| "#{a} #{msc[12]}"}
;

if File.exist? 'kalend-mar'
	wyniki = Marshal.load File.binread 'kalend-mar'
else
	words = %w[antropolog bakteriolog biolog biotechnolog ekolog embriolog entomolog immunolog mikolog mikrobiolog paleoantropolog protistolog zoolog biochemik biofizyk botanik genetyk leśnik przyrodnik zootechnik lekarz]
	words += words.map{|w| w.sub(/g\Z/, 'żka').sub(/k\Z/, 'czka').sub(/rz\Z/, 'rka')} # kobiece warianty
	words += %w[oceanograf oceanografka hodowca hodowczyni]

	words2 = %w[zoo park DNA gatunek]+['ogród zoologiczny']


	regex = /\b#{Regexp.union words+words2}\b/

	year = /(?:\[\[)?(\d{1,4})(?:\]\])?/
	year_only = /\A\*\s*#{year}:?\s*\Z/
	regex = Regexp.union regex, year_only

	# hash - klucze to daty, wartosci - hashe {nagłówek => [linie...]}
	wyniki = {}


	order.each do |data|
		p = Page.new data
		p.text.scan(/\r?\n==+\s*(.+?)\s*==+\r?\n([\s\S]+?)(?=\r?\n==|\Z)/) do |header, text|
			lines = text.split /\r?\n/
			wyniki[data] ||= {}
			wyniki[data][header.strip] = lines.grep(regex)
		end
	end

	mar = File.open('kalend-mar', 'wb')
	mar.write Marshal.dump wyniki
	mar.close
end

out = File.open('kalend.txt', 'w')


start = /\*+(?:\s|&nbsp;?)*/
year = /(?:\[\[)?(\d{1,4})(?:\]\])?/
pause = /\s*(?:[-–—]|:?\*+)\s*/
text = /((?:(?:\[\[)?(?:Sir|Dame)(?:\]\])?\s*)?\[\[.+?\]\])\s*[,-–—]\s*(.+?)/
zmur = /\((?:zm|ur)\.?\s*#{year}\)/

year_only = /\A\*\s*#{year}:?\s*\Z/
is_okay = /\A#{start}#{year}/
regex = /\A#{start}#{year}#{pause}#{text}(?:#{zmur}|)\Z/

order.each do |data|
	out.puts "\n=== [[#{data}]] ==="
	if wyniki[data] and !wyniki[data].empty?
		wyniki[data].each_pair do |header, lines|
			lines = 
				case header
				when 'Urodzili się'
					lines.map.with_index do |ln, i|
						# try to fix up multiline years
						if ln !~ is_okay
							ln = lines[0...i].grep(year_only)[-1] + ln rescue ln
						end
						
						ln.match(regex) do |m|
							_, firstdate, name, text, seconddate = *m
							"* w #{firstdate} urodził(a) się #{name}#{seconddate && " (zm. #{seconddate})"} – #{text}"
						end or ln
					end
				when 'Zmarli'
					lines.map do |ln|
						ln.match(regex) do |m|
							_, firstdate, name, text, seconddate = *m
							"* w #{firstdate} zmarł(a) #{name}#{seconddate && " (ur. #{seconddate})"} – #{text}"
						end or ln
					end
				else
					lines
				end
			;
			
			out.puts(lines - lines.grep(year_only))
		end
	else
		out.puts "''brak''"
	end
end

out.close

