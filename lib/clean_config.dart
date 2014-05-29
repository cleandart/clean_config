// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_config;

Map mergeMaps(Map a, Map b) {
  a = new Map.from(a);
  b = new Map.from(b);

  b.forEach((k, v) {
    if (a[k] is Map && v is Map) v = mergeMaps(a[k], v);
    a[k] = v;
  });

  return a;
}

class ComputedValue {
  final _computation;
  bool _evaluated = false;
  dynamic _value;
  ComputedValue(dynamic this._computation(ConfigMap config));

  /** Lazy compute the value */
  getValue(config) {
    if (_evaluated) return _value;
    _value = _computation(config);
    _evaluated = true;
    return _value;
  }
}

$(dynamic computation(ConfigMap config)) => new ComputedValue(computation);

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
   */
  ConfigMap(other, {ConfigMap this.root: null}) {
    if (root == null) root = this;
    _data = _convert(other, (k,v) => v is Map ? new ConfigMap(v, root:root) : v);
  }

  /**
   * Recursively converts to [Map]
   */
  Map toMap() {
    return _convert(_data, (k,v) => v is ConfigMap ? v.toMap() : this[k]);
  }

  operator[](key) => _data[key] is ComputedValue ? _data[key].getValue(root) : _data[key];
}

class Configuration {

  final Map<String, Map > _configurations = {};

  /**
   * Register configuration under [name].
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
  Map get(name) {
    if (!_configurations.containsKey(name)) {
      throw new ArgumentError("Configuration with name '$name' does not exist.");
    }
    var config = _configurations[name];
    var parent = config["parent"];

    var configMap = config["configMap"];

    if (parent != null) configMap = mergeMaps(get(parent), config["configMap"]);

    return new ConfigMap(configMap).toMap();
  }

  Iterable<String> get names => _configurations.keys;
}
