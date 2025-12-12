// lib/utils/leveling.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' show pow;

/// Simple XP system with exponential-ish growth
class Leveling {
  /// XP required for the next level
  static int xpForNextLevel(int level) {
    return (100 * pow(1.25, level - 1)).round();
  }
}

/// Extension on Firestore DocumentReference for character leveling
extension FirebaseLevelingExt on DocumentReference<Map<String, dynamic>> {
  /// Award XP to this character, handle level-ups, and increment optional fields
  ///
  /// - xpToAward: XP to add
  /// - increments: additional fields to increment (e.g., dailyMonsterProgress)
  /// Returns a map with updated xp, level, xpToNextLevel, and leveled status
  Future<Map<String, dynamic>> awardXpAndMaybeLevelUp(
    int xpToAward, {
    Map<String, dynamic>? increments,
  }) async {
    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(this);
      final data = snap.data() ?? {};

      int currentXp = (data['xp'] ?? 0) as int;
      int currentLevel = (data['level'] ?? 1) as int;
      int xpToNext = (data['xpToNextLevel'] ??
          Leveling.xpForNextLevel(currentLevel)) as int;

      currentXp += xpToAward;

      bool leveled = false;
      while (currentXp >= xpToNext) {
        leveled = true;
        currentXp -= xpToNext;
        currentLevel += 1;
        xpToNext = Leveling.xpForNextLevel(currentLevel);
      }

      final Map<String, dynamic> updatePayload = {
        'xp': currentXp,
        'level': currentLevel,
        'xpToNextLevel': xpToNext,
      };

      if (increments != null && increments.isNotEmpty) {
        increments.forEach((k, v) {
          updatePayload[k] = FieldValue.increment(v as num);
        });
      }

      tx.set(this, updatePayload, SetOptions(merge: true));

      return {
        'xp': currentXp,
        'level': currentLevel,
        'xpToNextLevel': xpToNext,
        'leveled': leveled,
      };
    });
  }
}
