# Simple configuration helper

Gets rid of unwanted duplications in configuration Maps and allows configurations
to inherit key-value pairs from other configurations, creating a transparent code
with less duplications.

## Motivation

Every server needs some configuration, mostly it is stored in some Map. In many cases, parts of the 
configuration are dependent on each other (e.g. some Sockets use the same host as server, 
maybe some url is constructed from a host and port in other part of the config), and so
there may be many duplications. Now imagine you have more modes (developer mode, testing mode, live mode ..)
and each one of them needs a configuration of course - many parts of these configs would look very much alike.
This would create a long code with many duplications, which is hard to maintain.

But wait, there is a solution to this !

## What does it provide?

In general, it provides simplicity and convenience.

More specifically, there is a *ConfigMap*, in which you can reference other parts of it,
even when it's not constructed yet ! That means, you may explicitly express the relations
between parts of the configuration - and this removes any duplications.

In addition, it provides a class *Configuration*, which allows you to have more configurations
that inherit key-values from their parents (and this solves our problem in Motivation).
Therefore, the code explicitly expresses the structure of a configuration and dependence on other configurations,
which makes it much easier to read / maintain.

## Example

     config = new Configuration();
     config.add("master", {
       "mode" : $((c) => c['__name__']), // name of the config is stored under a special key
       "page": { // you can use nested values
         "title": $((c) => "My new homepage - ${c['mode']} mode",
         "host": "127.0.0.1"
         "port": 8080,
         "url": $((c) => 'http://${c['page']['host']}:${c['page']['port']}'), // and reference other values in config
       },
       "someSocket" : {
         "http" : $((c) => c['page']['host'],
         "port" : 27001,
       }
     });
 
     config.add("developer", {
       "page" : {
         "port" : 8088,
         // other parts are inherited
       }
     }, parent: "master");
     
     config.add("testing", {
       "mode" : "test",
       "page" : {
         "host" : $((c) => "${c['mode']}.example.com",
         "url" : $((c) => "http://${c['page']['host']}/"),
       }
     }, parent: "developer");
     
     config.add("live", {
       "page" : {
         "title" : "My new homepage",
         "url" : "http://example.com/",
       },
       "someSocket" : {
         "port" : 27091,
       }
     }, parent: "master");
     
     config.get("testing") == {
       "__name__" : "testing",
       "mode" : "test",
       "page" : {
         "title" : "My new homepage - test mode",
         "host" : "test.example.com",
         "port" : 8088,
         "url" : "http://test.example.com/",
       },
       "someSocket" : {
         "http" : "test.example.com",
         "port" : 27001,
       }
     };
