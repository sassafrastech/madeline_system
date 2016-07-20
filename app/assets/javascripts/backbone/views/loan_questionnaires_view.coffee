class MS.Views.LoanQuestionnairesView extends Backbone.View

  el: 'section.questionnaires'

  initialize: (options) ->
    @loanId = options.loanId
    @refreshContent()
    @filterSwitchView = new MS.Views.FilterSwitchView()

  events:
    'ajax:error': 'submitError'

  refreshContent: ->
    MS.loadingIndicator.show()
    @$('.questionnaires-content').load "/admin/loans/#{@loanId}/questionnaires", =>
      MS.loadingIndicator.hide()
      @initializeTree()
      @filterSwitchView.filterInit()

  submitError: (e) ->
    e.stopPropagation()
    MS.errorModal.modal('show')
    MS.loadingIndicator.hide()

  initializeTree: ->
    @tree = @$('.jqtree')
    # Initialize the jqtree
    @tree.tree
      dragAndDrop: false
      selectable: false
      useContextMenu: false
      # This is fired for each li element in the jqtree just after it's created.
      # We pull pieces from the hidden questionnaire below and insert them.
      # This runs during the loadData event below.
      onCreateLi: (node, $li) =>
        $question = @$(".question[data-id=#{node.id}]")
        $li.attr('data-id', node.id)
            .addClass($question.attr('class'))

        # Don't replace content of 'optional questions' groups
        unless node.id == undefined
          $li.find('.jqtree-title')
              .html($question.children().not('ol').clone())

    # Load the data into each tree from its 'data-data' attribute.
    @tree.each =>
      @tree.tree 'loadData', @tree.data('data')
      @groupOptional(@tree.tree 'getTree')

  groupOptional: (root) ->
    optionalGroupName = I18n.t('questionnaires.optional_questions')

    # Recurse, depth first
    if root.children.length
      @groupOptional(child) for child in root.children

      if root.children.some( (el) -> el.optional )
        # Add optional group to this level
        @tree.tree(
          'appendNode',
          { name: optionalGroupName },
          root
        )
        optionalGroup = root.children[root.children.length - 1]

        child_ids = root.children.map( (i) -> i.id )
        for id in child_ids
          node = @tree.tree('getNodeById', id) if id
          if node?.optional
            @tree.tree('moveNode', node, optionalGroup, 'inside')
