Meteor.methods
	start_instanceToArchive: (spaces, flows, sDate, fDate) ->
		try
			ins_ids = []
			# 获取某时间段需要同步的申请单
			start_date = new Date(sDate)
			end_date = new Date(fDate)
			instances = Creator.Collections["instances"].find(
				{"submit_date":{$gt:start_date, $lt:end_date}, "values.record_need":"true", is_deleted: false, state: "completed"},
				{fields: {_id:1}}
			).fetch()


			if (instances)
				instances.forEach (ins)->
					ins_ids.push(ins._id)
			
			instancesToArchive = new InstancesToArchive(spaces, flows, ins_ids)
			instancesToArchive.syncNonContractInstances()
			return result
		catch e
			error = e
			return error
		