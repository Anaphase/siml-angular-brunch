fs = require 'fs'
siml = require 'siml'
sysPath = require 'path'
mkdirp  = require 'mkdirp'

write = (path, content, append=no) ->
  return unless content?
  dir = sysPath.dirname sysPath.normalize(path)
  mkdirp dir, '0775', (err) ->
    throw err if err?
    if append?
      fs.appendFile path, content, (err) -> throw err if err?
    else
      fs.writeFile path, content, (err) -> throw err if err?

module.exports = class SIMLAngularBrunch

  brunchPlugin: yes
  type: 'template'
  extension: 'siml'

  constructor: (config) ->
    @templates = []
    @public = config.paths.public
    @outFile = (Object.keys config.files.templates.joinTo)[0] or 'templates.js'
    @rootDir = config.files.templates.joinTo[@outFile]
    @createRouter = !!config.plugins?.siml?.createRouter
    @routerOptions = config.plugins?.siml?.routerOptions
    @templatePrefix = config.plugins?.siml?.templatePrefix or ''
    @templateModuleName = config.plugins?.siml?.moduleName or 'templates'
    @templatePathSeparator = config.plugins?.siml?.templatePathSeparator or '/'

  # Compiles all the templates and stores the data in @templates
  compile: (data, path, callback) ->

    try

      content = siml.angular.parse data, { pretty: no }

      path = path.replace @rootDir, ''
      path_hunks = path.split sysPath.sep
      name = path_hunks.pop()[...-@extension.length-1]
      path_hunks.push name
      path = sysPath.join.apply this, path_hunks

      @templates[path] =
        name: name
        content: content

    catch e
      error = "Error: #{e.message}"
      if e.type
        error = e.type + error
      if e.filename
        error += " in '#{e.filename}:#{e.line}:#{e.column}'"

    finally
      callback error, ''

  # Writes all the compiled templates to the AngularJS module and possibly contructs the router
  onCompile: (generated_files) ->

    router_module = if @createRouter then '\n' + @getRouterModule(@templates) or '' else ''
    template_module = @getTemplateModule @templates

    data =
      """
      \n
      /* siml-angular-brunch start */

      #{template_module}
      #{router_module}

      /* siml-angular-brunch end */

      """

    write @public + sysPath.sep + @outFile, data, yes

  # Generates the AngularJS template module
  getTemplateModule: (templates) ->

    content = []
    prefix = if @templatePrefix is '' then '' else "#{@templatePrefix}#{@templatePathSeparator}"

    for template_path, template of templates
      template_path = prefix + template_path.replace(/\//g, @templatePathSeparator)
      escaped_content = template.content.replace(/'/g, "\\'")
      escaped_content = template.content.replace(/\n/g, "\\n")
      content.push "$templateCache.put('#{template_path}', '#{escaped_content}');"

    """
    // siml-angular-brunch templates
    angular.module('#{@templateModuleName}', [])
      .run(['$templateCache', function($templateCache) {
        #{content.join '\n    '}
      }])
    """

  # Generates the AngularJS router module
  getRouterModule: (templates) ->

    content = []

    # takes a snake-case-file-name and converts it to ClassCaseControllerName
    snakeCaseToClassCase = (string) ->
      string[0].toUpperCase() + string[1..].replace /\-(.{1})/g, (whole, matched) -> matched.toUpperCase()

    for template_path, template of templates

      continue unless @routerOptions.onlyUse? and template_path.indexOf(@routerOptions.onlyUse) is 0

      route_name = template_path[template_path.indexOf(sysPath.sep, 1)..]
      controller_name = snakeCaseToClassCase template.name

      content.push "$routeProvider.when('#{route_name}', { controller: '#{controller_name}', templateUrl: '#{template_path}' });"

    if @routerOptions.defaultRoute?
      content.push "$routeProvider.otherwise({ redirectTo: '#{@routerOptions.defaultRoute}' });"

    """
    // siml-angular-brunch router
    angular.module('#{@routerOptions.moduleName or 'router'}', [])
      .config(['$routeProvider', function($routeProvider) {
        #{content.join '\n    '}
      }])
    """
