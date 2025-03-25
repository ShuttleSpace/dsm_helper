extension StringExt on String {
  bool get isBlank => this.trim().isEmpty;
  bool get isNotBlank => this.trim().isNotEmpty;
}
