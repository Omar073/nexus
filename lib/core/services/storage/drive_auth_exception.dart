/// Thrown when Drive operations need re-auth.
class DriveAuthRequiredException implements Exception {
  const DriveAuthRequiredException(this.message);
  final String message;

  @override
  String toString() => message;
}
