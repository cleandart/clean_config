import 'package:unittest/unittest.dart';
import 'package:clean_config/configuration.dart' as c;
import 'package:clean_config/configuration.dart';

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

  test('Should work with parent', () {
    config.add("child", {
      "name" : "Carrot",
      "id" : "8",
      "page" : {
        "myurl" : $((c) => '${c['name']}/${c['id']}')
      }
    }, parent: "master");
    expect(config.get("child"),equals({
      'page': {
        'title': 'My new homepage',
        'url': 'master',
        'myurl': 'Carrot/8'
      },
      'name': 'Carrot',
      'id': '8',
      '__name__': 'child'
    }));
  });

  test('Long parent chain', () {
    var numParents = 10;
    for (int i = 0; i < numParents; i++) {
      config.add("name${i}",{
        "key${i}" : "value${i}",
        "computation${i}" : $((c) => "Value is ${c['key${i}']} of map ${c['__name__']}"),
        "innerMap" : {
          "computation${i}" : $((c) => "Computation is: ${c['computation${i}']}")
        }
      }, parent: i == 0 ? null : "name${i-1}");
    }
    var expectedMap = {"__name__":"name${numParents-1}"};
    for (int i = 0; i < numParents; i++) {
      expectedMap["key${i}"] = "value${i}";
      expectedMap["computation${i}"] = "Value is value${i} of map name${i}";
      var innerMap = {};
      for (int j = 0; j < numParents; j++) {
        innerMap["computation${j}"] = "Computation is: Value is value${j} of map name${j}";
      }
      expectedMap["innerMap"] = innerMap;
    }
    expect(config.get("name${numParents-1}"), equals(expectedMap));
  });
}