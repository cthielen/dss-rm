DssRm.Models.Role = Backbone.Model.extend(
  urlRoot: "/roles"
  
  initialize: ->
    @resetNestedCollections()
    @on 'sync', @resetNestedCollections, this
    
  resetNestedCollections: ->
    console.log "role #{@cid} resetting nested collections"
    
    @entities = new DssRm.Collections.Entities(@get('entities')) if @entities is `undefined`
    @assignments = new Backbone.Collection(@get('assignments')) if @assignments is `undefined`
    
    # Reset nested collection data
    @entities.reset @get('entities')
    @assignments.reset @get('assignments')
    
    console.log "role now has #{@assignments.length} assignments"
    
    # Enforce the design pattern by removing from @attributes what is represented in a nested collection
    delete @attributes.entities
    delete @attributes.assignments
  
  tokenize: (str) ->
    String(str).replace(RegExp(" ", "g"), "-").replace(/'/g, "").replace(/"/g, "").toLowerCase()
  
  # Returns the entity if it is assigned to this role
  # Accepts an entity or an entity_id
  has_assigned: (entity, include_calculated = true) ->
    if entity.get == undefined
      # Looks like 'entity' is an ID
      id = entity
    else
      # Looks like 'entity' is a model
      id = (entity.get('group_id') || entity.id)
    
    assignment = @assignments.findWhere { entity_id: id }
    
    return assignment if (assignment and ((assignment.get('calculated') == false) or include_calculated))
  
  toJSON: ->
    json = {}

    json.name = @get('name')
    json.token = @get('token')
    json.description = @get('description')
    json.ad_path = @get('ad_path')

    # Note we use Rails' nested attributes here
    if @assignments.length
      json.role_assignments_attributes = @assignments.map (assignment) =>
        id: assignment.get('id')
        entity_id: assignment.get('entity_id')
        role_id: @get('id')
        _destroy: assignment.get('_destroy')
    
    role: json
)

DssRm.Collections.Roles = Backbone.Collection.extend(
  model: DssRm.Models.Role
  url: "/roles"
)
