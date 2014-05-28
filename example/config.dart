// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clean_config/clean_config.dart';

main() {
  var config = new Configuration();

  config.add("master", {
    "page": { // you can use nested values
      "title": "My new homepage",
      "url": $((c) => c['__name__']), // and reference other values in config
    },
  });


  config.add("random", {
    "id" : "13",
    "user" : {
      "name" : "John",
      "surname" : "Doe",
      "fullname" : $((c) => '${c['user']['name']} ${c['user']['surname']}'),
      "hash" : $((c) => '${c['id']}${c['user']['fullname']}')
    }
  });

  // Find configuration by registered name.
  print(config.get("master"));
  print(config.get("random"));
}
