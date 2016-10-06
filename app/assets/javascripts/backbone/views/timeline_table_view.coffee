# Controls the timeline modal (no more than one per page).
class MS.Views.TimelineTableView extends Backbone.View

  el: 'section.timeline-table'

  initialize: (options) ->
    @loanId = options.loanId

  events:
    'click .timeline-action.new': 'newGroup'

  refresh: ->
    MS.loadingIndicator.show()
    @$('.timeline-table').empty()
    $.get "/admin/loans/#{@loanId}/timeline", (html) =>
      MS.loadingIndicator.hide()
      @$('.timeline-table').html(html)

  newGroup: (e) ->
    e.preventDefault()
    @modal = new MS.Views.ProjectGroupModalView(loanId: @loanId)

