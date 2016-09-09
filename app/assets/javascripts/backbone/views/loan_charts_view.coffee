class MS.Views.LoanChartsView extends Backbone.View

  el: '.summary-chart'

  initialize: (params) ->
    @breakevenData = params.breakeven_data
    @breakevenFixedCosts = @breakevenData["fixed_costs"]
    @breakevenProductionCosts = @breakevenData["cogs"]
    @breakevenRevenue = @breakevenData["revenue"]
    @defaultChartOptions = {
      width: "100%"
    }

    @loadCharts()

  breakevenFixedCostsChart: ->
    columns = [
      {"label":I18n.t('loan.breakeven.fixed_costs', count: 1),"type":"string"},
      {"label":I18n.t('loan.breakeven.amount'),"type":"number"}
    ]

    rows = []
    for key,cost of @breakevenFixedCosts
      name = cost.name
      total = cost.amount
      rows.push({"c":[{"v": name},{"v": total, "f":null}]})

    options = @defaultChartOptions
    chartData = {"cols": columns, "rows": rows}
    chartData = new google.visualization.DataTable(chartData);
    chart = new google.visualization.PieChart(document.getElementById('breakeven-fixed-cost-chart'));
    chart.draw(chartData, options);

  breakevenProductProfitChart: ->
    columns = [
      {"label":I18n.t('loan.breakeven.product'),"type":"string"},
      {"label":I18n.t('loan.breakeven.profit'),"type":"number"}
    ]

    rows = []
    for key,product of @breakevenProductProfit()
      name = key
      total = product.profit
      rows.push({"c":[{"v": name},{"v": total, "f":null}]})

    options = @defaultChartOptions
    chartData = {"cols": columns, "rows": rows}
    chartData = new google.visualization.DataTable(chartData);
    chart = new google.visualization.PieChart(document.getElementById('breakeven-product-profit'));
    chart.draw(chartData, options);

  breakevenProductionCostsChart: ->
    columns = [
      {"label":I18n.t('loan.breakeven.product'),"type":"string"},
      {"label":I18n.t('loan.breakeven.production_cost'),"type":"number"}
    ]

    options = @defaultChartOptions
    rows = []
    for key,product of @breakevenProductionCosts
      name = product.name
      total = product.total
      rows.push({"c":[{"v": name},{"v": total, "f":null}]})

    chartData = {"cols": columns, "rows": rows}
    chartData = new google.visualization.DataTable(chartData);
    chart = new google.visualization.PieChart(document.getElementById('breakeven-production-cost-chart'));
    chart.draw(chartData, options);

  breakevenProductProfit: ->
    profitData = {}

    for key,product of @breakevenRevenue
      name = product.name
      revenue = product.total

      profitData[name] = {revenue: revenue}

    for key,product of @breakevenProductionCosts
      name = product.name
      cost = product.total

      profitData[name]['cost'] = cost
      profitData[name]['profit'] = profitData[name]['revenue'] - cost

    return profitData

  breakevenRevenueChart: ->
    columns = [
      {"label":I18n.t('loan.breakeven.product'),"type":"string"},
      {"label":I18n.t('loan.breakeven.revenue'),"type":"number"}
    ]

    options = @defaultChartOptions
    rows = []
    for key,product of @breakevenRevenue
      name = product.name
      total = product.total
      rows.push({"c":[{"v": name},{"v": total, "f":null}]})

    chartData = {"cols": columns, "rows": rows}
    chartData = new google.visualization.DataTable(chartData);
    chart = new google.visualization.PieChart(document.getElementById('breakeven-revenue-chart'));
    chart.draw(chartData, options);

  breakevenCostsChart: ->
    columns = [
      {"label":I18n.t('loan.breakeven.item'),"type":"string"},
      {"label":I18n.t('loan.breakeven.cost'),"type":"number"}
    ]
    rows = []

    rows.push({"c":[{"v": "Cost of Good Sold"},{"v": @breakevenData["total_cogs"], "f":null}]})
    rows.push({"c":[{"v": "Fixed Costs"},{"v": @breakevenData["total_fixed_costs"], "f":null}]})

    options = @defaultChartOptions
    chartData = {"cols": columns, "rows": rows}
    chartData = new google.visualization.DataTable(chartData)
    chart = new google.visualization.PieChart(document.getElementById('breakeven-costs-chart'))
    chart.draw(chartData, options);

  breakevenTotalCostsChart: ->
    columns = [
      {"label":I18n.t('loan.breakeven.item'),"type":"string"},
      {"label":I18n.t('loan.breakeven.cost'),"type":"number"}
    ]
    rows = []

    for key,product of @breakevenProductionCosts
      name = product.name
      total = product.total
      rows.push({"c":[{"v": name},{"v": total, "f":null}]})

    for key,cost of @breakevenFixedCosts
      name = cost.name
      total = cost.amount
      rows.push({"c":[{"v": name},{"v": total, "f":null}]})

    options = @defaultChartOptions
    slices = {}

    # Color is adjusted per item based on total items in a specific group
    # Fixed costs have a different base color than product costs
    productionCostLength = @breakevenProductionCosts.length
    fixedCostLength = rows.length - productionCostLength
    productionIncrement = parseInt((255-102)/productionCostLength)
    fixedCostIncrement = parseInt((255-57)/fixedCostLength)

    i = 0
    for key,row of rows
      if key < productionCostLength
        slices[parseInt(key)] = {color:
          "rgb(#{51 + (productionIncrement * parseInt(key))},
          #{102 + (productionIncrement * parseInt(key))},
          204)"
        }
      else
        slices[parseInt(key)] = {color:
          "rgb(220,
          #{57 + (fixedCostIncrement * i)},
          #{18 + (fixedCostIncrement * i)})"
        }
        ++i

    options.slices = slices
    chartData = {"cols": columns, "rows": rows}
    chartData = new google.visualization.DataTable(chartData)
    chart = new google.visualization.PieChart(document.getElementById('breakeven-total-costs-chart'))
    chart.draw(chartData, options);

  loadCharts: ->
    google.charts.load('current', {'packages':['corechart']});
    google.charts.setOnLoadCallback @breakevenRevenueChart.bind @
    google.charts.setOnLoadCallback @breakevenProductionCostsChart.bind @
    google.charts.setOnLoadCallback @breakevenFixedCostsChart.bind @
    google.charts.setOnLoadCallback @breakevenProductProfitChart.bind @
    google.charts.setOnLoadCallback @breakevenCostsChart.bind @
