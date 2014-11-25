// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_config;

/**
 * Recursively merges Map [b] into [a].
 *
 * If there are under a specific key distinct values in [a] and [b] which
 * are not Maps, the value in [b] is used.
 */
Map mergeMaps(Map a, Map b) {
  a = new Map.from(a);
  b = new Map.from(b);

  b.forEach((k, v) {
    if (a[k] is Map && v is Map) v = mergeMaps(a[k], v);
    a[k] = v;
  });

  return a;
}

/// Class that computes value using given computation on ConfigMap lazily.
class ComputedValue {
  final _computation;
  ComputedValue(dynamic this._computation(ConfigMap config));

  /** Lazy compute the value */
  getValue(config) => _computation(config);
}

/**
 * Function used to access different parts of the ConfigMap.
 *
 * [computation] is given a ConfigMap in a structure it'd have when it's constructed.
 * Values in this ConfigMap can be accessed just like in a regular Map using operator [].
 */
$(dynamic computation(ConfigMap config)) => new ComputedValue(computation);

/**
 * ConfigMap may be used just as a regular Map, but in addition, parts of the ConfigMap
 * may be referenced even in construction of it using function [$]. Therefore, some duplications
 * may be removed.
 *
 * Example:
 *
 *    ConfigMap configMap = new ConfigMap(
 *      {
 *        "id" : "13",
 *        "user" : {
 *          "name" : "John",
 *          "surname" : "Doe",
 *          "fullname" : $((c) => '${c['user']['name']} ${c['user']['surname']}'),
 *          "hash" : $((c) => '${c['id']}${c['user']['fullname']}')
 *        }
 *      });
 *
 *    Map config = configMap.toMap();
 *    print(config['user']['fullname']); // "John Doe"
 */
class ConfigMap {
  ConfigMap root;
  Map _data;

  Map _convert(Map map, getValue) {
    var res = {};
    map.forEach((k, v) {
      res[k] = getValue(k,v);
    });
    return res;
  }
  /**
   * Recursively converts [other] to [ConfigMap].
   *
   * Maps nested in Lists or in any other structures, besides Maps, are not converted.
   */
  ConfigMap(Map other, {ConfigMap this.root: null}) {
    if (root == null) root = this;
    _data = _convert(other, (k,v) => v is Map ? new ConfigMap(v, root:root) : v);
  }

  /**
   * Recursively converts to [Map]
   */
  Map toMap() {
    return _convert(_data, (k,v) => v is ConfigMap ? v.toMap() : this[k]);
  }

  /**
   * Accessing keys using this operator evaluates the computation on requested position
   */
  operator[](key) {
    _data[key] = (_data[key] is ComputedValue) ?
                     _data[key].getValue(root) :
                     _data[key];
    return _data[key];
  }
}

/**
 * Stores all configurations, and allows a tree-like heritage structure of configurations.
 *
 * Every configuration is stored under a name. If the configuration specifies a parent name, the child
 * Map is merged into the parent Map (see [mergeMaps]).
 */
class Configuration {

  final Map<String, Map > _configurations = {};

  /**
   * Register configuration under [name].
   *
   * If [parent] is specified, this [configuration] merges into the configuration
   * of parent Map.
   */
  void add(String name, Map configuration, {String parent: null}) {
    configuration['__name__'] = name;
    _configurations[name] = {
      "parent": parent,
      "configMap": configuration,
    };
  }

  /**
   * Get configuration stored under [name].
   *
   * Name of the configuration is stored under key "__name__".
   * Throws [ArgumentError] if configuration with [name] does not exists.
   */
  Map get(String name) {
    return new ConfigMap(_get(name)).toMap();
  }

  Map _get(String name) {
    if (!_configurations.containsKey(name)) {
      throw new ArgumentError("Configuration with name '$name' does not exist.");
    }
    var config = _configurations[name];
    var parent = config["parent"];

    var configMap = config["configMap"];

    if (parent != null) configMap = mergeMaps(_get(parent), config["configMap"]);
    return configMap;
  }

  Iterable<String> get names => _configurations.keys;
}
