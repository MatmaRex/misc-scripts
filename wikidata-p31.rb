# coding: utf-8
require 'sunflower'
require 'pp'

wd = Sunflower.new('www.wikidata.org').login
wdtoken = wd.API("action=tokens&type=edit")['tokens']['edittoken']

wdq = JSON.parse RestClient.post('http://wdq.wmflabs.org/api', q: 'claim[31:215627,31:5] AND claim[31:95074]')
raise wdq['status']['error'] unless wdq['status']['error'] == 'OK'

items = wdq['items']

items.each do |item|
	id = "Q#{item}"
	print "#{id}... "
	
	# get claim info
	claims = wd.API(
		action: 'wbgetclaims',
		entity: id,
		property: 'P31',
	)
	# example format:
=begin
{"claims"=>
  {"P31"=>
    [{"id"=>"Q45581$90AF2374-7C91-4A6D-94C6-47CEB00DA1D8",
      "mainsnak"=>
       {"snaktype"=>"value",
        "property"=>"P31",
        "datatype"=>"wikibase-item",
        "datavalue"=>
         {"value"=>{"entity-type"=>"item", "numeric-id"=>5},
          "type"=>"wikibase-entityid"}},
      "type"=>"statement",
      "rank"=>"normal"},
     {"id"=>"Q45581$e0397f16-4868-0113-0d9b-7a450f5e8464",
      "mainsnak"=>
       {"snaktype"=>"value",
        "property"=>"P31",
        "datatype"=>"wikibase-item",
        "datavalue"=>
         {"value"=>{"entity-type"=>"item", "numeric-id"=>95074},
          "type"=>"wikibase-entityid"}},
      "type"=>"statement",
      "rank"=>"normal"}]}}
      
{"claims"=>
  {"P31"=>
    [{"id"=>"q264699$0F3EC9E3-3CFF-4300-8291-060709553FB8",
      "mainsnak"=>
       {"snaktype"=>"value",
        "property"=>"P31",
        "datatype"=>"wikibase-item",
        "datavalue"=>
         {"value"=>{"entity-type"=>"item", "numeric-id"=>5},
          "type"=>"wikibase-entityid"}},
      "type"=>"statement",
      "rank"=>"normal",
      "references"=>
       [{"hash"=>"7eb64cf9621d34c54fd4bd040ed4b61a88c4a1a0",
         "snaks"=>
          {"P143"=>
            [{"snaktype"=>"value",
              "property"=>"P143",
              "datatype"=>"wikibase-item",
              "datavalue"=>
               {"value"=>{"entity-type"=>"item", "numeric-id"=>328},
                "type"=>"wikibase-entityid"}}]},
         "snaks-order"=>["P143"]}]},
     {"id"=>"Q264699$ed0df052-40dc-14a5-bd16-058940dbf336",
      "mainsnak"=>
       {"snaktype"=>"value",
        "property"=>"P31",
        "datatype"=>"wikibase-item",
        "datavalue"=>
         {"value"=>{"entity-type"=>"item", "numeric-id"=>95074},
          "type"=>"wikibase-entityid"}},
      "type"=>"statement",
      "rank"=>"normal",
      "references"=>
       [{"hash"=>"0f96a2f54b19046c88588aa5f1ff93a0c4b28275",
         "snaks"=>
          {"P1080"=>
            [{"snaktype"=>"value",
              "property"=>"P1080",
              "datatype"=>"wikibase-item",
              "datavalue"=>
               {"value"=>{"entity-type"=>"item", "numeric-id"=>8539},
                "type"=>"wikibase-entityid"}}]},
         "snaks-order"=>["P1080"]}]}]}}
=end

	if !claims || !claims['claims']
		puts "Article deleted?"
		next
	end
	
	claim_list = claims['claims']['P31'].map{|c| 
		boring_keys = %w[id mainsnak]
		
		# the only references are "imported from", ignore them
		if c['references'] && c['references'].all?{|r| r['snaks-order'] == ['P143'] }
			boring_keys << 'references'
		end
		# defaults
		if c['type'] == 'statement'
			boring_keys << 'type'
		end
		if c['rank'] == 'normal'
			boring_keys << 'rank'
		end
		
		has_magic = (c.keys - boring_keys).length > 0
		
		{
			'id' => c['id'],
			'q' => c['mainsnak']['datavalue']['value']['numeric-id'],
			'has_magic' => has_magic,
		}
	}
	
	
	if claim_list.any?{|c| c['has_magic'] }
		puts "Special P31 claims"
		next
	end
	

	# filter out possibly problematic items
	valid_sets = [
		[ 5, 95074 ],
		[ 95074, 215627 ],
		[ 5, 95074, 215627 ],
	]
	
	used_qs = claim_list.map{|c| c['q'] }.sort
	if used_qs == [15632617]
		puts "Already processed"
		next
	end
	unless valid_sets.include? used_qs
		puts "Unrecognized set of P31 values: #{used_qs.inspect}"
		next
	end
	
	# remove all first
	claim_changes = claim_list.map{|c| { 'id' => c['id'], 'remove' => '' } }
	
	# add new one
	claim_changes.push({
		"mainsnak" => {
			"snaktype" => "value",
			"property" => "P31",
			"datatype" => "wikibase-item",
			"datavalue" => {
				"value" => {"entity-type" => "item", "numeric-id" => 15632617},
				"type" => "wikibase-entityid"
			},
		},
		"type" => "statement",
		"rank" => "normal",
	})

	result = wd.API(
		action: 'wbeditentity',
		id: id,
		token: wdtoken,
		summary: "[[Property:P31]]: ([[Q5]] | [[Q215627]]) + [[Q95074]] → [[Q15632617]]",
		bot: true,
		data: {'claims' => claim_changes}.to_json
	)
	
	p result['success']
	
end
