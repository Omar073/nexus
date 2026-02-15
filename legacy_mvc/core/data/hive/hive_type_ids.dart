/// Keep Hive typeIds stable forever.
/// When adding a new type, append a new id; never reuse old ids.
class HiveTypeIds {
  static const int category = 0;
  static const int taskAttachment = 1;
  static const int task = 2;
  static const int syncOperation = 3;
  static const int reminder = 4;
  static const int syncMetadata = 5;
  static const int noteAttachment = 6;
  static const int note = 7;
  static const int habit = 8;
  static const int habitLog = 9;
}
