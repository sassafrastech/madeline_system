class MS.Views.LoanQuestionnairesView extends Backbone.View

  el: 'section.questionnaires'

  initialize: (options) ->
    @loanId = options.loanId
    @locale = options.locale
    @initializeTree()
    @adjustAllTextareas()

    @$('.breakeven-tables').map (index, breakeven) =>
      new MS.Views.BreakevenView(el: breakeven)

  events:
    'ajax:error': 'submitError'
    'confirm:complete .linked-document [data-action="delete"]': 'removeLinkedDocument'
    'click .edit-action': 'editDocument'
    'focus .questionnaire-form form': 'setupDirtyForm'
    'tree.open': 'notifyExpandListeners'
    'change .answer-wrapper textarea': 'adjustTextArea'
    'keyup .answer-wrapper textarea': 'adjustTextArea'
    'keydown .answer-wrapper textarea': 'adjustTextArea'
    'paste .answer-wrapper textarea': 'adjustTextArea'
    'cut .answer-wrapper textarea': 'adjustTextArea'
    'clear .answer-wrapper textarea': 'adjustTextArea'
    'click .edit-rt-response': 'openRichTextModal'

  # Add a custom event for tree expansion. This event is listened to by LoanChartsView.
  notifyExpandListeners: (e) ->
    @$(e.node.element).find('[data-tree-expand-listener]').trigger('tree.expanded')
    @adjustAllTextareas()

  removeLinkedDocument: (e) ->
    e.preventDefault()
    $item = @$(e.currentTarget)
    $container = $item.closest('.linked-document')
    $container.find('input[type="text"]').val('')
    $item.hide()

  submitError: (e) ->
    e.stopPropagation()
    MS.errorModal.modal('show')
    MS.loadingIndicator.hide()

  initializeTree: ->
    @tree = @$('.jqtree')
    # Initialize the jqtree
    @tree.tree
      dragAndDrop: false
      saveState: true
      selectable: false
      useContextMenu: false
      # This is fired for each li element in the jqtree just after it's created.
      # We pull pieces from the hidden questionnaire below and insert them.
      # This runs during the loadData event below.
      onCreateLi: (node, $li) =>
        $question = @$(".question[data-id=#{node.id}]")
        $li.attr('data-id', node.id)
            .addClass($question.attr('class'))

        if node.id == 'optional_group'
          $li.addClass('optional-group')
        else
          $li.find('.jqtree-title')
            .replaceWith($question.children('.tree-view'))

    # Load the data into each tree from its 'data-data' attribute.
    @tree.each (index, tree) =>
      data = @groupOptional($(tree).data 'data')
      $(tree).tree 'loadData', data

  # Note: the grouping of optional questions that happens here and in _questionnaire_group
  # should probably be refactored someday to happen in the model
  groupOptional: (nodes) ->
    optionalGroupName = I18n.t('questionnaires.optional_questions', locale: @locale)

    # Recurse, depth first
    for node in nodes
      if node.children?.length
        node.children = @groupOptional(node.children)

    if nodes.some( (el) -> el.optional ) && !nodes.every( (el) -> el.optional )
      # Add optional group to this level
      nodes.push { id: 'optional_group', name: optionalGroupName, children: [] }
      optionalGroup = nodes[nodes.length - 1]

      for node in nodes
        if node.optional
          optionalGroup.children.push node

      # Remove original copies of optional nodes
      nodes = nodes.filter( (node) -> !node.optional )

    nodes

  editDocument: (e) ->
    # Fire a global event. Consider refactoring this in the style of notifyExpandListeners above.
    Backbone.trigger 'LoanQuestionnairesView:edit', @
    @adjustAllTextareas()

  # Sets up the dirtyForm plugin on the questionnaire form.
  # We need to do this on a focus event because the form is not always visible when the page loads,
  # and dirtyForms doesn't seem to work with a hidden form. The focus event can only be fired when the
  # form is visible. Also, calling .dirtyForms() on each focus event doesn't seem to cause any issues.
  setupDirtyForm: (e) ->
    @$('.questionnaire-form form').dirtyForms()

  adjustTextArea: (e) ->
    textarea = @$(e.target)
    textarea.height(0).height(textarea[0].scrollHeight)

  adjustAllTextareas: ->
    @$('.answer-wrapper textarea').trigger('change')

  openRichTextModal: (e) ->
    console.log("Edit response clicked")
    options = {}
    new MS.Views.RichTextModalView(e, options)
