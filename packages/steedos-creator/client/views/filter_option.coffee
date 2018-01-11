Template.filter_option.helpers 
    schema:() -> 
        schema= 
            field:
                type: String
                label: "field"
                autoform:
                    type: "select"
                    defaultValue: ()->
                        return "name"
                    options: ()->
                        keys = Creator.getSchema(Session.get("object_name"))._firstLevelSchemaKeys
                        keys = _.map keys, (key) ->
                            return {label: key, value: key}
                        return keys
            operation:
                type: String
                label: "operation"
                autoform:
                    type: "select"
                    defaultValue: ()->
                        return "EQUALS"
                    options: ()->
                        options = [
                            {label: "equals", value: "EQUALS"},
                            {label: "not equal to", value: "NOT_EQUAL"},
                            {label: "less than", value: "LESS_THAN"},
                            {label: "greater than", value: "GREATER_THAN"},
                            {label: "less or equal", value: "LESS_OR_EQUAL"},
                            {label: "greater or equal", value: "GREATER_OR_EQUAL"},
                            {label: "contains", value: "CONTAINS"},
                            {label: "does not contain", value: "NOT_CONTAIN"},
                            {label: "starts with", value: "STARTS_WITH"},
                        ]
            value:
                type: String
                label: "value"
                autoform:
                    type:()->
                        return Session.get("schema_type")

        new SimpleSchema(schema)

    filter_item: ()->
        filter_item = Template.instance().data?.filter_item
        schema_type = ""
        if filter_item and filter_item.field
            _schema = Creator.getSchema(Session.get("object_name"))._schema
            _.each _schema, (obj, key)->
                if key == filter_item.field
                    schema_type = obj.autoform.type || "text"
        
        Session.set "schema_type", schema_type
        
        return filter_item

Template.filter_option.events 
    "click .save-filter": (event, template) ->
        filter = AutoForm.getFormValues("filter-option").insertDoc

        index = this.index
        filter_items = Session.get("filter_items")
        filter_items[index] = filter

        Session.set("filter_items", filter_items)
        template.$(".uiPanel--default").css({"top": "-1000px", left: "-1000px"})

    'change select[name="field"]': (event, template) ->
        field = $(event.currentTarget).val()
        _schema = Creator.getSchema(Session.get("object_name"))._schema
        type = ""
        _.each _schema, (obj, key)->
            if key == field
                type = obj.autoform.type || "text"

        Session.set "schema_type", type

        console.log type
        