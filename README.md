siml-angular-brunch
===================

Adds [SIML](https://github.com/padolsey/SIML) support to [Brunch](http://brunch.io), with an AngularJS flavor.

How It Works
------------

This plugin compiles [SIML](https://github.com/padolsey/SIML) files into HTML and makes them available as CommonJS modules.

Usage
-----

Install the plugin via npm with `npm install --save siml-angular-brunch`.

Or, do manual install:

* Add `"siml-angular-brunch": "x.y.z"` to `package.json` of your Brunch app. Pick a plugin version that corresponds to your minor (y) Brunch version.
* If you want to use git version of plugin, add `"siml-angular-brunch": "git+ssh://git@github.com:Anaphase/siml-angular-brunch.git"`.

Sample Brunch config.coffee
---------------------------

```coffee-script
exports.config =
  files:
    templates:
      defaultExtension: 'siml'
      joinTo:
        'js/app.js' : /^app/ # search entire app directory for .siml files
```

License
-------

The MIT License (MIT)

Copyright (c) 2013 Colin Wood

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
