library configuration;

import 'package:useful/useful.dart';

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
  
  _convert(Map map, condition, convertValue) {
    var res = {};
    map.forEach((k, v)) {
      v = if (condition(v)) convertValue(v);
      res[k] = v;
    }
  }
  /**
   * Recursively converts [other] to [ConfigMap].
   */
  ConfigMap(other, {ConfigMap this.root: null}) {
    if (root == null) root = this;
    _data = _convert(other, (v) => v is Map, (v) => new ConfigMap(root: root, other: v));
  }

  /**
   * Recursively converts to [Map]
   */
  Map toMap() {
    return _convert(_data, (v) => v is ConfigMap, (v) => v.toMap());
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
    if (!_configurations.containsKey(name)) throw new ArgumentError("Configuration does not exist.");
    var config = _configurations[name];
    var parent = config["parent"];
    
    var configMap = config["configMap"];
    
    if (parent != null) configMap = mergeMaps(get(parent), configMap);
    
    return new ConfigMap(configMap).toMap();
  }
}
