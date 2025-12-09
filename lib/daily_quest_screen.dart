import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ------------------------------------------------------------
/// DAILY QUEST SCREEN (3 simple quests)
/// ------------------------------------------------------------
/// Quest 1: Walk 2000 steps      -> dailyGoal / dailyProgress
/// Quest 2: Walk 5000 steps      -> dailyQ2Goal / dailyQ2Progress
/// Quest 3: Defeat 5 monsters    -> dailyMonsterGoal / dailyMonsterProgress
///
/// All quests reset once per day using the "dailyDate" field.
class DailyQuestScreen extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> characterRef;

  const DailyQuestScreen({super.key, required this.characterRef});

  @override
  State<DailyQuestScreen> createState() => _DailyQuestScreenState();
}

class _DailyQuestScreenState extends State<DailyQuestScreen> {
  static const int _q1Goal = 2000;
  static const int _q2Goal = 5000;
  static const int _monsterGoal = 5;

  static const int _q1Reward = 50;       // XP for Quest 1
  static const int _q2Reward = 100;       // XP for Quest 2
  static const int _monsterReward = 70;  // XP for Quest 3

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _setupQuestsForToday();
  }

  Future<void> _setupQuestsForToday() async {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final snap = await widget.characterRef.get();
    final data = snap.data() ?? {};
    final String? existingDate = data['dailyDate'] as String?;

    // If it's a new day or quests were never set up, reset everything.
    if (existingDate != todayKey) {
      await widget.characterRef.set({
        'dailyDate': todayKey,

        // Quest 1 fields
        'dailyQ1Goal': _q1Goal,
        'dailyProgress': 0,
        'dailyQ1RewardClaimed': false,

        // Quest 2 fields
        'dailyQ2Goal': _q2Goal,
        'dailyQ2Progress': 0,
        'dailyQ2RewardClaimed': false,

        // Quest 3 fields (monsters)
        'dailyMonsterGoal': _monsterGoal,
        'dailyMonsterProgress': 0,
        'dailyMonsterRewardClaimed': false,
      }, SetOptions(merge: true));
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quests'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: widget.characterRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data?.data() ?? {};

            // Quest 1 values
            final int q1Goal = (data['dailyQ1Goal'] ?? _q1Goal) as int;
            final int q1Progress =
                (data['dailyProgress'] ?? 0) as int;
            final bool q1Claimed =
                (data['dailyQ1RewardClaimed'] ?? false) as bool;
            final bool q1Done = q1Progress >= q1Goal;
            final double q1Pct =
                q1Goal > 0 ? (q1Progress / q1Goal).clamp(0.0, 1.0) : 0.0;

            // Quest 2 values
            final int q2Goal = (data['dailyQ2Goal'] ?? _q2Goal) as int;
            final int q2Progress =
                (data['dailyQ2Progress'] ?? 0) as int;
            final bool q2Claimed =
                (data['dailyQ2RewardClaimed'] ?? false) as bool;
            final bool q2Done = q2Progress >= q2Goal;
            final double q2Pct =
                q2Goal > 0 ? (q2Progress / q2Goal).clamp(0.0, 1.0) : 0.0;

            // Quest 3 values (monsters)
            final int mGoal =
                (data['dailyMonsterGoal'] ?? _monsterGoal) as int;
            final int mProgress =
                (data['dailyMonsterProgress'] ?? 0) as int;
            final bool mClaimed =
                (data['dailyMonsterRewardClaimed'] ?? false) as bool;
            final bool mDone = mProgress >= mGoal;
            final double mPct =
                mGoal > 0 ? (mProgress / mGoal).clamp(0.0, 1.0) : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Quests",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Quest 1 card
                _buildQuestCard(
                  title: 'Quest 1: Walk $q1Goal steps',
                  progressText: '$q1Progress / $q1Goal steps',
                  percent: q1Pct,
                  completed: q1Done,
                  claimed: q1Claimed,
                  onClaim: () => _claimReward(_q1Reward, 'dailyQ1RewardClaimed'),
                ),

                const SizedBox(height: 16),

                // Quest 2 card
                _buildQuestCard(
                  title: 'Quest 2: Walk $q2Goal steps',
                  progressText: '$q2Progress / $q2Goal steps',
                  percent: q2Pct,
                  completed: q2Done,
                  claimed: q2Claimed,
                  onClaim: () => _claimReward(_q2Reward, 'dailyQ2RewardClaimed'),
                ),

                const SizedBox(height: 16),

                // Quest 3 card
                _buildQuestCard(
                  title: 'Quest 3: Defeat $mGoal monsters',
                  progressText: '$mProgress / $mGoal monsters',
                  percent: mPct,
                  completed: mDone,
                  claimed: mClaimed,
                  onClaim: () => _claimReward(
                    _monsterReward,
                    'dailyMonsterRewardClaimed',
                  ),
                ),

                const Spacer(),
                const Text(
                  'Step quests progress increases when you use the Step Tracker.\n'
                  'Monster quest progress increases when you defeat enemies in battle.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper to claim XP for any quest
  Future<void> _claimReward(int xpAmount, String claimedField) async {
    try {
      await widget.characterRef.set({
        'xp': FieldValue.increment(xpAmount),
        claimedField: true,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reward claimed! +$xpAmount XP.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  // Quest UI
  Widget _buildQuestCard({
    required String title,
    required String progressText,
    required double percent,
    required bool completed,
    required bool claimed,
    required VoidCallback onClaim,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent,
              minHeight: 12,
            ),
            const SizedBox(height: 4),
            Text(progressText),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: (!completed || claimed) ? null : onClaim,
              child: Text(
                claimed
                    ? 'Reward Claimed'
                    : (completed ? 'Claim Reward' : 'Not Complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
