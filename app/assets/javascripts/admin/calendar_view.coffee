# Common functions for calendars application-wide.
class MS.Views.CalendarView extends Backbone.View

  events:
    'click .cal-step': 'stepClick'

  initializeCalendar: (params, context, settings) ->
    @$calendar = @$('#calendar')
    @stepModal = params.stepModal
    @locale = params.locale
    defaultCalendarSettings =
      eventAfterRender: @eventAfterRender.bind(context)
      eventDrop: @eventDrop.bind(context)
      loading: @loading.bind(context)
      events: params.calendarEventsUrl
      lang: @locale
      height: 'auto'
      allDayDefault: true
    options = $.extend defaultCalendarSettings, settings
    @$calendar.fullCalendar(options)

  stepClick: (e) ->
    @stepModal.show(@$(e.currentTarget).data('step-id'), @refresh.bind(@))

  dayClick: (date) ->
    if @$el.find('#calendar[data-project-id]').length
      @stepModal.new(@$el.find('#calendar').data('project-id'), @refresh.bind(@),
        date: date.format('YYYY-MM-DD'))

  # Load custom content inside the fullCalendar rendered event rather than title only
  eventAfterRender: (calEvent, initialElement) ->
    $(initialElement).find('.fc-content').append(calEvent.html)
    $(initialElement).addClass(calEvent.event_classes)
    $(initialElement).data('step-id', calEvent.model_id)
    $(initialElement).find('.fc-title').remove()

  eventDrop: (event, delta, revertFunc) ->
    if event.model_type == 'ProjectStep'
      if event.is_finalized
        unless @moveStepModalView
          @moveStepModalView = new MS.Views.MoveStepModalView
            el: $("<div>").appendTo(@$el)
            context: 'calendar_drag'

        @moveStepModalView.show(event.model_id, delta.days())
        .done => @refresh()
        .fail => revertFunc()
      else
        $.post("/admin/timeline_step_moves/#{event.model_id}/simple_move",
          _method: "PATCH"
          scheduled_start_date: event.start.format('YYYY-MM-DD'))
          .done => @refresh()

    else if event.model_type == 'BasicProject' || event.model_type == 'Loan'
      # We use a 1ms timeout so that fullCalendar can finish drawing the event in the new calendar cell.
      setTimeout =>
        if confirm(I18n.t("loan.move_date_confirm.body", locale: @locale))
          $.post "/admin/projects/#{event.model_id}/change_date",
            _method: "PATCH"
            which_date: event.event_type
            new_date: event.start.format('YYYY-MM-DD')
        else
          revertFunc()
      ,1

  loading: (isLoading) ->
    MS.loadingIndicator[if isLoading then 'show' else 'hide']()

  renderLegend: (e) ->
    legendContent = @$('#legend-content').html()

    @$('.fc-legend-button').attr({
      'data-html': 'true',
      'data-toggle': 'popover',
      'data-content': legendContent,
      'data-title': I18n.t('calendar.legend', locale: @locale)
      })
    @$('.fc-legend-button').popover
      placement: 'left'
      sanitize: 'false'
      trigger: 'click'

  refresh: (e) ->
    @$calendar.fullCalendar('refetchEvents')
