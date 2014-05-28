import 'package:clean_config/configuration.dart';

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