import 'dart:convert';
void main() {
  Map<String, dynamic> target = {"a": {"b": 1}};
  Map<String, dynamic> source = jsonDecode('{"a": {"c": 2}}');
  
  void _deepMerge(Map<String, dynamic> target, Map<String, dynamic> source) {
    source.forEach((key, value) {
      print('key: $key, value type: ${value.runtimeType}');
      if (value is Map<String, dynamic>) {
        if (!target.containsKey(key)) {
          target[key] = value;
        } else if (target[key] is Map<String, dynamic>) {
          _deepMerge(target[key] as Map<String, dynamic>, value);
        } else {
          target[key] = value;
        }
      } else if (value is Map) {
         print('value is Map but not Map<String, dynamic>');
         target[key] = value;
      } else {
        target[key] = value;
      }
    });
  }
  
  _deepMerge(target, source);
  print(target);
}
