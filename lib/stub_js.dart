// Stub implementation for js interop
// This file is only used on non-web platforms

class JsContext {
  bool hasProperty(String name) => false;
  dynamic operator [](String key) => null;
}

class JsObject {
  JsObject(dynamic constructor, [List<dynamic>? arguments]);

  static dynamic jsify(Object object) => object;

  dynamic callMethod(String method, [List<dynamic>? args]) => null;
}

final JsContext context = JsContext();
