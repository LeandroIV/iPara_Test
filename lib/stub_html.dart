// Stub implementation for html DOM
// This file is only used on non-web platforms

class Document {
  Element? getElementById(String id) => null;
  BodyElement? get body => null;
}

class Element {
  String? id;
  StyleElement style = StyleElement();
  bool? isConnected;
  List<Element> children = [];

  void add(Element child) {}
}

class DivElement extends Element {
  DivElement();
}

class BodyElement extends Element {
  List<Element> children = [];
}

class StyleElement {
  String visibility = '';
  String height = '';
  String width = '';
}

final Document document = Document();
