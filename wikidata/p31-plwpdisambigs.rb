# coding: utf-8
require 'sunflower'
require 'pp'

wd = Sunflower.new('www.wikidata.org').login
wdtoken = wd.API("action=tokens&type=edit")['tokens']['edittoken']

items = RestClient.get 'http://tools.wmflabs.org/wikidata-todo/autolist2.php?language=pl&project=wikipedia&category=Strony%20ujednoznaczniaj%C4%85ce&depth=12&wdq=claim%5B31%3A4167410%5D&mode=cat_no_wdq&statementlist=&run=Run&label_contains=&label_contains_not=&chunk_size=100&download=1'
items = items.strip.split(/\s+/)

puts "To do: #{items.length}"

items.each do |id|
	print "#{id}... "

	result = wd.API(
		action: 'wbcreateclaim',
		token: wdtoken,
		entity: id,
		summary: "[[Property:P31]]: [[Q4167410]] (from pl.wikipedia)",
		bot: true,
		property: 'P31',
		snaktype: 'value',
		value: { 'entity-type' => 'item', 'numeric-id' => 4167410 }.to_json,
	)
	
	p result['success']
end
