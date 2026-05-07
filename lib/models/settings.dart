class Settings {
  final String targetAppPackage;
  bool lockActiveStatus;

  Settings({
    required this.targetAppPackage,
    this.lockActiveStatus = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1, // Only one settings row
      'targetAppPackage': targetAppPackage,
      'lockActiveStatus': lockActiveStatus ? 1 : 0,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      targetAppPackage: map['targetAppPackage'],
      lockActiveStatus: map['lockActiveStatus'] == 1,
    );
  }
}
