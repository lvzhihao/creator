Meteor.methods
	archive_receive: (object_name,selectedIds,space) ->
		result = []
		successNum = 0
		collection = Creator.Collections[object_name]
		totalNum = selectedIds.length
		result.push totalNum
		selectedIds.forEach (selectedId)->
			newSuccessNum = collection.direct.update({_id:selectedId},{$set:{is_received:true,received:new Date(),received_by:Meteor.userId(),modified:new Date(),modified_by:Meteor.userId()}})
			successNum = successNum+ newSuccessNum
			if newSuccessNum
				record = collection.findOne(selectedId,{fields:{fonds_name:1,archival_category_code:1,year:1,external_id:1}})
				if record?.fonds_name and record?.year
					fonds_name_code = Creator.Collections["archive_fonds"].findOne(record.fonds_name,{fields:{code:1}})?.code
					year = record.year
					count = collection.find({year:year,is_received:true}).count()
					strcount = "0000000" + count
					count_code = strcount.substr(strcount.length-6)
					electronic_record_code = fonds_name_code + "WS" + year + count_code
					collection.direct.update(selectedId,{$set:{electronic_record_code:electronic_record_code}})
				Meteor.call("archive_new_audit",selectedId,"接收档案","成功",space)
			else
				Meteor.call("archive_new_audit",selectedId,"接收档案","失败",space)
		result.push successNum
		return result