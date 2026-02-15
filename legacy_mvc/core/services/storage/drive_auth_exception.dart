/// Exception thrown when Drive access requires authentication
class DriveAuthRequiredException implements Exception {
  const DriveAuthRequiredException(this.message);
  final String message;

  @override
  String toString() => message;
}
