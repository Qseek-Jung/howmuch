import 'ledger_project.dart';

class LedgerBackup {
  final List<LedgerProject> projects;
  final Map<String, dynamic> settings;

  LedgerBackup({required this.projects, required this.settings});

  Map<String, dynamic> toJson() => {
    'version': 2,
    'projects': projects.map((p) => p.toJson()).toList(),
    'settings': settings,
  };

  factory LedgerBackup.fromJson(dynamic json) {
    if (json is List) {
      // Legacy format
      return LedgerBackup(
        projects: json.map((p) => LedgerProject.fromJson(p)).toList(),
        settings: {},
      );
    }

    final map = json as Map<String, dynamic>;
    return LedgerBackup(
      projects: (map['projects'] as List? ?? [])
          .map((p) => LedgerProject.fromJson(p))
          .toList(),
      settings: map['settings'] as Map<String, dynamic>? ?? {},
    );
  }
}
