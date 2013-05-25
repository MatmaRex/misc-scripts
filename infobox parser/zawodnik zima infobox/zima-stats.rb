# coding: utf-8
require 'sunflower'
require 'pp'
require './../infobox parser.rb'

require 'io/console'
print 'Password: '
s = Sunflower.new('pl.wikipedia.org').login('MatmaBot', STDIN.noecho(&:gets).strip)
puts ''

titles = s.make_list 'whatembeds', 'Szablon:Zawodnik zima infobox'
titles = titles.sort#[0, 10]

most_used_keys = {}
key_usage = {}
done = 0

printer_lambda = lambda do
	File.open('zima.txt', 'w') do |f|
		keys = most_used_keys.sort_by{|k,v| -v}
		keys = keys.map{|k,v| "* #{k} (#{v<=done*0.01 ? "#{v}: "+key_usage[k].map{|a| "[[#{a}]]"}.join(', ') : v})"}
		
		f.puts keys
	end
end

print_em = false
trap("INT"){print_em = true}
at_exit &printer_lambda

titles.each_with_index do |title, i|
	p [i, title]
	
	p = Page.new title
	t = p.text

	ib = Infobox.new 'Zawodnik zima'

	# extract name and image
	t.gsub!(/{{Zawodnik zima infobox\|(.+?)}}/i){ib[:zawodnik] = $1.strip; ''}
	t.gsub!(/{{Zawodnik zima infobox\/grafika\|(.+?)}}/i){ib[:grafika] = $1.strip; ''}

	# remove sub-titles in the table
	t.gsub!(/{{Zawodnik zima infobox\/podrozdział\|(.+?)}}\s*(?={{Zawodnik zima infobox\/wiersz)/i, '')
	t.gsub!(/{{Zawodnik zima infobox\/koniec}}/i, '')

	# extract all the extractable rest
	t.gsub!(/{{Zawodnik zima infobox\/wiersz\|((?:\[\[[^\]]+\]\]|[^\[\|]+)+)\|((?:{{[^}]+}}|[^{}]+)+)}}/i){
		param, value = $1, $2
		ib[ param.downcase_pl.strip.gsub(/\[\[(?:[^\|\]]+\|)?([^\]]+)\]\]/, '\1') ] = value.strip; ''
	}

	# and just keep others.
	list = []
	t.gsub!(/{{Zawodnik zima infobox\/(rozdzia.|podrozdzia.|medal|medal bez|puchar|rekord)\|(.+?)}}/i){list << $&; ''}
	ib[:dorobek] = "\n" + list.join("\n") unless list.empty?
	
	ib.keys.each do |k|
		most_used_keys[k] ||= 0
		most_used_keys[k] += 1
		
		key_usage[k] ||= []
		key_usage[k] << title
	end
	
	done += 1
	
	if print_em
		printer_lambda.call
		print_em = false
	end
end

printer_lambda.call
