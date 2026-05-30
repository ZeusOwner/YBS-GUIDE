extension StringSearch on String {
  bool containsIgnoreCase(String value) {
    return toLowerCase().contains(value.toLowerCase());
  }
}
