DssRm.Views.EntityItem = Support.CompositeView.extend({
  tagName: "li",

  events: {
    "click a>i"                 : "patchTooltipBehavior",
    "click a.entity-remove-link": "removeEntity"
  },

  initialize: function(options) {
    this.model.bind('change', this.render, this);

    this.highlighted = options.highlighted;
    this.faded = options.faded;
    this.read_only = options.read_only;
    this.current_role = options.current_role;
    this.current_application = options.current_application;
  },

  render: function () {
    var type = this.model.get('type');

    this.$el.data('entity-id', this.model.get('id'));
    this.$el.data('entity-name', this.model.get('name'));
    this.$el.html(JST['entities/item']({ entity: this.model }));
    this.$('span').html(this.model.escape('name'));
    this.$el.addClass(type.toLowerCase());
    this.$('.entity-details-link').attr("href", this.entityUrl()).on("click", function(e) {
      e.stopPropagation(); // the parent is looking for a click as well
      $(e.target).tooltip('hide'); // but stopPropagation will stop the tooltip from closing...
    });
    if(type == "Person") this.$('.entity-remove-link i').removeClass("icon-remove").addClass("icon-minus");

    if(this.highlighted) {
      if(type == "Person") {
        this.$el.css("box-shadow", "#08C 0 0 5px").css("border", "1px solid #08C");
      } else {
        // Group
        this.$el.css("box-shadow", "#468847 0 0 5px").css("border", "1px solid #468847");
      }
    }
    if(this.faded) {
      this.$el.css("opacity", "0.6");
      this.$("i.icon-minus").hide();
    }
    if(this.read_only) {
      this.$("i.icon-remove").hide();
      this.$("i.icon-search").hide();
    } else {
      this.$("i.icon-lock").hide();
    }

    return this;
  },

  entityUrl: function() {
    return "#" + "/entities/" + this.model.get('id');
  },

  // This is necessary to fix a bug in tooltips (as of Bootstrap 2.1.1)
  patchTooltipBehavior: function(e) {
    $(e.currentTarget).tooltip('hide');
  },

  removeEntity: function(e) {
    e.stopPropagation();

    $(e.target).tooltip('hide'); // stopPropagation means the tooltip won't close, so close it

    // This is not the same as unassigning. If somebody clicks the remove link
    // on an entity, they are either deleting a group or removing a favorite person.
    var type = this.model.get('type');

    if(type == "Group") {
      // Destroy the group
      this.model.destroy();
    } else if (type == "Person") {
      var model_id = this.model.get('id');

      var favorites_entity = DssRm.current_user.favorites.find(function(e) { return e.id == model_id; });
      DssRm.current_user.favorites.remove(favorites_entity);
      DssRm.current_user.favorites.trigger('change');
      DssRm.current_user.save();
    }
  }
});
