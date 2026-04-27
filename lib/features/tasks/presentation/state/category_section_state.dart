class CategorySectionState {
  bool isExpanded = true;
  final Map<String, bool> _subcategoryExpansion = {};

  bool isSubExpanded(String subcategoryId) =>
      _subcategoryExpansion[subcategoryId] ?? true;

  void toggleExpanded() {
    isExpanded = !isExpanded;
  }

  void toggleSubExpanded(String subcategoryId) {
    final current = isSubExpanded(subcategoryId);
    _subcategoryExpansion[subcategoryId] = !current;
  }
}
