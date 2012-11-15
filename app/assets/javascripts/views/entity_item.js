DssRm.Views.EntityItem = Support.CompositeView.extend({
  tagName: "li",

  events: {
    "click a>i": "patchTooltipBehavior"
  },

  initialize: function(options) {
    this.model.bind('change', this.render, this);

    this.highlighted = options.highlighted;
  },

  render: function () {
    this.$el.data('entity-id', this.model.get('id'));
    this.$el.html(JST['entities/item']({ entity: this.model }));
    this.$('span').html(this.model.escape('name'));
    this.$el.addClass(this.model.get('type'));
    this.$('.entity-details-link').attr("href", this.entityUrl());

    if(this.highlighted) {
      this.$el.css("box-shadow", "#08C 0 0 5px").css("border", "1px solid #08C");
    }

    return this;
  },

  entityUrl: function() {
    return "#" + "/entities/" + this.model.get('id');
  },

  // This is necessary to fix a bug in tooltips (as of Bootstrap 2.1.1)
  patchTooltipBehavior: function(e) {
    $(e.currentTarget).tooltip('hide');
  }
});
