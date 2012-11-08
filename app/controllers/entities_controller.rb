class EntitiesController < ApplicationController
  filter_access_to :all
  respond_to :json

  #wrap_parameters (defined? params) ? params[:type].to_sym : Group

  def index
    @entities = current_user.manageable_ids
  end

  def show
    @entity = Entity.find(params[:id])
  end

  def create
    entity = Entity.new( params[:entity] )
    entity.save

    if params[:entity][:type] == "Group"
      Group.find(entity.id).owners << current_user # cannot add 'entity' directly b/c of Rails' limited STI
    end

    respond_with entity
  end

  def update
    entity = Entity.find(params[:id])

    entity.update_attributes(params[:entity])
    respond_with entity
  end

  private

  def build_params(entity, params)
    ret = {}
    entity.attribute_names.each do |atr|
      logger.info atr
      ret[atr.to_sym] = params[atr]
    end
    return ret
  end
end