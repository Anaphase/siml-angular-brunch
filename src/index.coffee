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
    @public = config.paths.public
    @outFile = (Object.keys config.files.templates.joinTo)[0] or "templates.js"
    @rootDir = config.files.templates.joinTo[@outFile]
    @createRouter = !!config.plugins?.siml?.createRouter
    @routerOptions = config.plugins?.siml?.routerOptions
    @templateModuleName = config.plugins?.siml?.moduleName or 'templates'
  
  # Basically does nothing except test compilation and throw an error if compilation fails
  compile: (data, path, callback) ->
    
    try
      content = siml.angular.parse data, { pretty: no }
      
    catch e
      error = "Error: #{e.message}"
      if e.type
        error = e.type + error
      if e.filename
        error += " in '#{e.filename}:#{e.line}:#{e.column}'"
      
    finally
      callback error, ''
  
  # compile all .siml files and write them to the public folder
  onCompile: (compiled) ->
    
    templates = @getTemplates compiled
    
    router_module = if @createRouter then @getRouterModule(templates) or '' else ''
    template_module = @getTemplateModule templates
    
    write "#{@public}#{sysPath.sep}#{@outFile}", "#{template_module}\n#{router_module}", yes
  
  # Reads and compiles the SMIL files
  # Returns an array of objects with 'path' and 'content' values
  getTemplates: (compiled) ->
    
    templates = []
    files = (result.sourceFiles for result in compiled when result.path is "#{@public}#{sysPath.sep}#{@outFile}")[0]
    
    for file in files when file.compilerName is 'SIMLCompiler'
      
      path = file.path.replace @rootDir, ''
      
      path_hunks = path.split sysPath.sep
      
      name = path_hunks.pop()[...-@extension.length-1]
      
      path_hunks.push name + '.html'
      
      data = fs.readFileSync file.path, 'utf8'
      content = siml.angular.parse data, { pretty: no }
      templates.push
        name: name
        content: content
        path: sysPath.join.apply this, path_hunks
    
    templates
    
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
    