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
  /**
   * Recursively converts [other] to [ConfigMap].
   */
  ConfigMap({ConfigMap this.root: null, Map other: const {}}) {
    if (root == null) root = this;
    _data = {};
    other.forEach((k,v) {
      if (v is! Map) {
        _data[k] = v;
      } else {
        _data[k] = new ConfigMap(root:root,other:v);
      }
    });
  }

  Map toMap() {
    var res = {};
    _data.forEach((k,v) {
      if (v is ConfigMap) {
        res[k] = v.toMap();
      } else {
        res[k] = this[k];
      }
    });
    return res;
  }

  ConfigMap.config(ConfigMap this.root, Map this._data);
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
      "configMap": new ConfigMap(other:configuration)
    };
  }

  /**
   * Get configuration stored under [name].
   *
   * Name of the configuration is stored under key "__name__".
   * Throws [ArgumentError] if configuration with [name] does not exists.
   */
  Map get(name) {
    if (!_configurations.containsKey(name)) throw new ArgumentError("Configuration does not exist");
    var config = _configurations[name];
    if (config["parent"] == null) {
      return config["configMap"].toMap();
    } else {
      return mergeMaps(get(config["parent"]), config["configMap"]);
    }
  }
}