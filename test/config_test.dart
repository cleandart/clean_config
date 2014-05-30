// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:clean_config/clean_config.dart' as c;
import 'package:clean_config/clean_config.dart';

main() {
  run();
}

run() {

  c.Configuration config;

  setUp(() {
    config = new c.Configuration();
    config.add("master", {
      "page": { // you can use nested values
        "title": "My new homepage",
        "url": $((c) => c['__name__']), // and reference other values in config
      },
    });
  });

  test("Merge maps.", () {
    // given
    var a = {
        'author': {
          'name': 'John',
          'age': 47,
        },
        'contractor': 'Peter Pan',
    };

    var b = {
        'author': {
          'surname': 'Mensah',
          'age': 48,
        },
        'contractor': {
          'name': 'Peter',
          'surname': 'Pan',
        },
    };

    // when
    var result = mergeMaps(a, b);

    // then
    expect(result, {
        'author': {
          'name': 'John',
          'surname': 'Mensah',
          'age': 48,
        },
        'contractor': {
          'name': 'Peter',
          'surname': 'Pan',
        },
    });
  });

  test('Should compute the right values', () {
    config.add("random", {
       "id" : "13",
       "user" : {
         "name" : "John",
         "surname" : "Doe",
         "fullname" : $((c) => '${c['user']['name']} ${c['user']['surname']}'),
         "hash" : $((c) => '${c['id']}${c['user']['fullname']}')
       }
    });

    expect(config.get("random"), equals({
      "__name__" : "random",
      "id" : "13",
      "user" : {
        "name" : "John",
        "surname" : "Doe",
        "fullname" : "John Doe",
        "hash" : "13John Doe"
      }
    }));
  });

  test('Parent chain and computed values', () {
    // given
    config.add("parent", {'name': $((c) => "${c['firstname']} ${c['surname']}")});
    config.add("child", {"firstname": "Peter", "surname": "Pan"}, parent: "parent");

    // when
    expect(config.get("child")['name'], "Peter Pan");
  });

  test('Should work with parent', () {
    config.add("child", {
      "name" : "Carrot",
      "id" : "8",
      "page" : {
        "myurl" : $((c) => '${c['name']}/${c['id']}')
      }
    }, parent: "master");
    expect(config.get("child"), equals({
      'page': {
        'title': 'My new homepage',
        'url': 'child',
        'myurl': 'Carrot/8'
      },
      'name': 'Carrot',
      'id': '8',
      '__name__': 'child'
    }));
  });

}