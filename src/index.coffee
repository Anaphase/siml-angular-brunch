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

module.exports = class SIMLCompiler
  
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
    @templateModuleName = config.plugins?.siml?.moduleName or 'templates'
  
  # Compiles all the templates and stores the data in @templates
  compile: (data, path, callback) ->
    
    try
      
      content = siml.angular.parse data, { pretty: no }
      
      path = path.replace @rootDir, ''
      path_hunks = path.split sysPath.sep
      name = path_hunks.pop()[...-@extension.length-1]
      path_hunks.push name
      
      @templates.push
        name: name
        content: content
        path: sysPath.join.apply this, path_hunks
      
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
    
    write "#{@public}#{sysPath.sep}#{@outFile}", template_module + router_module, yes
  
  # Generates the AngularJS template module
  getTemplateModule: (templates) ->
    
    content = ''
    
    for template in templates
      escaped_content = template.content.replace(/'/g, "\\'")
      content += "\n    $templateCache.put('#{template.path}', '#{escaped_content}');"
    
    """
    angular.module('#{@templateModuleName}', [])
      .run(['$templateCache', function($templateCache) {
        #{content}
      }])
    """
  
  # Generates the AngularJS router module
  getRouterModule: (templates) ->
    
    content = ''
    
    for template in templates
      
      continue unless @routerOptions.onlyUse? and template.path.indexOf(@routerOptions.onlyUse) is 0
      
      route_name = template.path[template.path.indexOf(sysPath.sep, 1)..][...-5]
      controller_name = template.name[0].toUpperCase() + template.name[1..-1]
      
      content += "\n    $routeProvider.when('#{route_name}', { controller: '#{controller_name}', templateUrl: '#{template.path}' });"
    
    if @routerOptions.defaultRoute?
      content += "\n    $routeProvider.otherwise({ redirectTo: '#{@routerOptions.defaultRoute}' });"
    
    """
    angular.module('#{@routerOptions.moduleName or 'router'}', [])
      .config(['$routeProvider', function($routeProvider) {
        #{content}
      }])
    """
    