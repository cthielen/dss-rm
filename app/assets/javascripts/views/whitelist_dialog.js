DssRm.Views.WhitelistDialog = Support.CompositeView.extend({
  tagName: "div",
  className: "modal",
  id: "whitelistDialogModal",

  events: {
    "hidden"             : "cleanUpModal",
    "submit #new-address": "newAddress",
    "click a#remove_ip"  : "removeAddress"
  },

  initialize: function(options) {
    this.$el.html(JST['application/whitelist_dialog']());

    this.whitelist = options.whitelist;
  },

  render: function() {
    var self = this;

    this.$("tbody").empty();
    this.whitelist.each(function(ip) {
      var row = $("<tr><td>" + ip.address + "</td><td>" + ip.reason + "</td><td><a href=\"#\" id=\"remove_ip\">Remove</a></td></tr>");
      $(row).data("ip_id", ip.id);
      self.$("tbody").append(row);
    });

    return this;
  },

  newAddress: function(e) {
    var self = this;
    var new_address = $(e.currentTarget).find("input[name=address]").val();
    var new_reason = $(e.currentTarget).find("input[name=reason]").val();

    $.post(Routes.admin_api_whitelisted_ips_path(), { address: {address: new_address, reason: new_reason } }, function() {
        self.trigger('render');
      }
    );

    return false;
  },

  removeAddress: function(e) {
    var ip_id = $(e.currentTarget).parents("tr").data("ip_id");
    console.log("remove address");
    console.log(ip_id);

    return false;
  },

  cleanUpModal: function() {
    $("div#whitelistDialogModal").remove();

    // Need to change URL in case they want to open the same modal again
    Backbone.history.navigate("");
  }
});

  // Address was created. Keep the view up-to-date by adding the corresponding table row
  //$("form#new-address").bind("ajax:success", function(event, data, status, xhr) {
    //var address = data.api_whitelisted_ip;
    // Add the row
    //$("table#addresses tbody tr:last").after("<tr><td>" + address.address + "</td><td>" + address.reason + "</td><td><a href=\"/admin/api_whitelisted_ips/" + address.id + "\" data-confirm=\"Are you sure?\" data-method=\"delete\" data-remote=\"true\" rel=\"nofollow\">Remove</a></td></tr>");
    // Clear out the input
    //$("form#new-address #address_address").val("");
  //});

  // Address was deleted. Keep the view up-to-date by deleting the corresponding table row
  //$("table#addresses tbody").on("ajax:success", "tr td a", function(event, data, status, xhr) {
    //$(this).parent().parent().remove();
  //});
