import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/split_bill_model.dart';

final splitHistoryProvider =
    StateNotifierProvider<SplitHistoryNotifier, List<SplitBill>>((ref) {
      return SplitHistoryNotifier();
    });

class SplitHistoryNotifier extends StateNotifier<List<SplitBill>> {
  SplitHistoryNotifier() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('split_history');
    if (stored != null) {
      state = stored.map((s) => SplitBill.fromJson(s)).toList();
    }
  }

  Future<void> addSplit(SplitBill split) async {
    state = [split, ...state];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'split_history',
      state.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> deleteSplit(String id) async {
    state = state.where((s) => s.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'split_history',
      state.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> updateSplit(String id, String newTitle) async {
    state = [
      for (final split in state)
        if (split.id == id)
          SplitBill(
            id: split.id,
            title: newTitle,
            date: split.date,
            totalAmount: split.totalAmount,
            currency: split.currency,
            peopleCount: split.peopleCount,
            perPersonAmount: split.perPersonAmount,
            surplus: split.surplus,
            roundUnit: split.roundUnit,
          )
        else
          split,
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'split_history',
      state.map((s) => s.toJson()).toList(),
    );
  }
}
