class MS.Views.LogsListView extends Backbone.View

  el: '.logs-list'

  initialize: (options) ->
    @refreshUrl = options.refreshUrl

  events:
    'click .log [data-action="edit"]': 'openEditLog'
    'confirm:complete .log [data-action="delete"]': 'deleteLog'
    'ajax:complete': 'refresh'

  openEditLog: (e) ->
    e.preventDefault()
    logId = @$(e.currentTarget).closest('.log').data('id')
    logModalView = new MS.Views.LogModalView(el: $("<div>").insertAfter(@$el))
    logModalView.showEdit(logId, '', @refresh.bind(@))

  deleteLog: (e) ->
    e.preventDefault()
    logId = @$(e.currentTarget).closest('.log').data('id')

    $.ajax(type: "DELETE", url: "/admin/logs/#{logId}")
    .done =>
      @refresh()
    .fail (response) ->
      MS.alert(response.responseText)
    return false

  refresh: () ->
    MS.loadingIndicator.show()
    $.get @refreshUrl, (html) =>
      @$el.replaceWith(html)
      # Fixes modal overlay bug in some logs list contexts
      $('.modal').modal('hide')
      MS.loadingIndicator.hide()
