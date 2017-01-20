class MS.Views.LogListView extends Backbone.View

  initialize: (options) ->
    console.log(@$el)
    new MS.Views.AutoLoadingIndicatorView()
    @refreshUrl = options.refreshUrl
    @logFormModalView = options.logFormModalView

  events:
    'click .log [data-action="edit"]': 'openEditLog'
    'confirm:complete .log [data-action="delete"]': 'deleteLog'

  openEditLog: (e) ->
    e.preventDefault()
    logId = @$(e.currentTarget).closest('.log').data('id')
    @logFormModalView.showEdit(logId, '', @refresh.bind(@))

  deleteLog: (e) ->
    e.preventDefault()
    logId = @$(e.currentTarget).closest('.log').data('id')
    $.ajax(method: "DELETE", url: "/admin/logs/#{logId}")
    .done => @refresh()
    .fail (response) -> MS.alert(response.responseText)

  refresh: () ->
    $.get @refreshUrl, (html) =>
      @$el.html(html)
      @afterRefresh() if @afterRefresh