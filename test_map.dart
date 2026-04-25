void main() {
  Map<String, dynamic> accounts = {};
  Map<String, dynamic> getAcc(String id) {
    return accounts[id] ?? {};
  }
  var a = getAcc("test");
  print(a.runtimeType);
}
