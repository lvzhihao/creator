Meteor.startup ->

	odataV4Mongodb = Npm.require 'odata-v4-mongodb'
	querystring = Npm.require 'querystring'

	visitorParser = (visitor)->
		parsedOpt = {}

		if visitor.projection
			parsedOpt.fields = visitor.projection

		if visitor.hasOwnProperty('limit')
			parsedOpt.limit = visitor.limit

		if visitor.hasOwnProperty('skip')
			parsedOpt.skip = visitor.skip

		if visitor.sort
			parsedOpt.sort = visitor.sort

		parsedOpt

	dealWithExpand = (createQuery, entities, key)->
		if _.isEmpty createQuery.includes
			return

		obj = Creator.Objects[key]
		_.each createQuery.includes, (include)->
			console.log 'include: ', include
			navigationProperty = include.navigationProperty
			console.log 'navigationProperty: ', navigationProperty
			field = obj.fields[navigationProperty]
			if field and field.type is 'lookup'
				lookupCollection = Creator.Collections[field.reference_to]
				queryOptions = visitorParser(include)

				_.each entities, (entity, idx)->
					if entity[navigationProperty]
						if field.multiple
							multiQuery = _.extend {_id: {$in: entity[navigationProperty]}}, include.query
							entities[idx][navigationProperty] = lookupCollection.find(multiQuery, queryOptions).fetch()
						else
							singleQuery = _.extend {_id: entity[navigationProperty]}, include.query
							entities[idx][navigationProperty] = lookupCollection.findOne(singleQuery, queryOptions)

		return

	_.each Creator.Collections, (value, key, list)->
		if not Creator.Objects[key]?.enable_api
			return

		if SteedosOdataAPI
			console.log key

			SteedosOdataAPI.addCollection Creator.Collections[key],
				excludedEndpoints: []
				routeOptions:
					authRequired: SteedosOData.AUTHREQUIRED
					spaceRequired: false
				endpoints:
					getAll:
						action: ->
							console.log "getAll ------ #{key}"
							collection = Creator.Collections[key]
							if not collection
								statusCode: 404
								body: {status: 'fail', message: 'Collection not found'}

							permissions = Creator.getObjectPermissions(@spaceId, @userId, key)
							if permissions.viewAllRecords
									console.log 'queryParams: ', @queryParams
									console.log 'urlParams: ', @urlParams
									console.log 'bodyParams: ', @bodyParams
									console.log 'querystring: ', querystring.unescape(querystring.stringify(@queryParams))
									createQuery = odataV4Mongodb.createQuery(querystring.unescape(querystring.stringify(@queryParams)))

									if key is 'cfs.files.filerecord'
										createQuery.query['metadata.space'] = @urlParams.spaceId
									else
										createQuery.query.space = @urlParams.spaceId

									console.log 'createQuery: ', createQuery

									entities = []
									if @queryParams.$top isnt '0'
										console.log visitorParser(createQuery)
										entities = collection.find(createQuery.query, visitorParser(createQuery)).fetch()
									scannedCount = collection.find(createQuery.query).count()

									if entities
										dealWithExpand(createQuery, entities, key)

										body = {}
										headers = {}
										body['@odata.context'] = SteedosOData.getODataContextPath(@urlParams.spaceId, key)
										body['@odata.count'] = scannedCount
										body['value'] = entities
										headers['Content-type'] = 'application/json;odata.metadata=minimal;charset=utf-8'
										headers['OData-Version'] = SteedosOData.VERSION
										{body: body, headers: headers}
									else
										statusCode: 404
										body: {status: 'fail', message: 'Unable to retrieve items from collection'}
							else
								statusCode: 400
								body: {status: 'fail', message: 'Action not permitted'}
					post:
						action: ->
							collection = Creator.Collections[key]
							if not collection
								statusCode: 404
								body: {status: 'fail', message: 'Collection not found'}

							permissions = Creator.getObjectPermissions(@spaceId, @userId, key)
							if permissions.allowCreate
									@bodyParams.space = @spaceId
									entityId = collection.insert @bodyParams
									entity = collection.findOne entityId
									if entity
										statusCode: 201
										{status: 'success', value: entity}
									else
										statusCode: 404
										body: {status: 'fail', message: 'No item added'}
							else
								statusCode: 400
								body: {status: 'fail', message: 'Action not permitted'}
					get:
						action: ->
							collection = Creator.Collections[key]
							if not collection
								statusCode: 404
								body: {status: 'fail', message: 'Collection not found'}

							permissions = Creator.getObjectPermissions(@spaceId, @userId, key)
							if permissions.allowRead
									selector = {_id: @urlParams.id, space: @spaceId}
									entity = collection.findOne selector
									if entity
										{status: 'success', value: entity}
									else
										statusCode: 404
										body: {status: 'fail', message: 'Item not found'}
							else
								statusCode: 400
								body: {status: 'fail', message: 'Action not permitted'}
					put:
						action: ->
							collection = Creator.Collections[key]
							if not collection
								statusCode: 404
								body: {status: 'fail', message: 'Collection not found'}

							permissions = Creator.getObjectPermissions(@spaceId, @userId, key)
							if permissions.allowEdit
									selector = {_id: @urlParams.id, space: @spaceId}
									entityIsUpdated = collection.update selector, $set: @bodyParams
									if entityIsUpdated
										entity = collection.findOne @urlParams.id
										{status: 'success', value: entity}
									else
										statusCode: 404
										body: {status: 'fail', message: 'Item not found'}
							else
								statusCode: 400
								body: {status: 'fail', message: 'Action not permitted'}
					delete:
						action: ->
							collection = Creator.Collections[key]
							if not collection
								statusCode: 404
								body: {status: 'fail', message: 'Collection not found'}

							permissions = Creator.getObjectPermissions(@spaceId, @userId, key)
							if permissions.allowDelete
									selector = {_id: @urlParams.id, space: @spaceId}
									if collection.remove selector
										{status: 'success', message: 'Item removed'}
									else
										statusCode: 404
										body: {status: 'fail', message: 'Item not found'}
							else
								statusCode: 400
								body: {status: 'fail', message: 'Action not permitted'}
