// lib/battle_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/leveling.dart'; // our leveling utility

/// --------------------------------------
/// BATTLE & ENCOUNTER SYSTEM
/// --------------------------------------
/// 5-monster progression:
/// 1) Slime   - lowest HP / reward
/// 2) Goblin
/// 3) Zombies
/// 4) Witch
/// 5) Dragon  - highest HP / reward
/// After defeating one monster, you move to the next.
/// After Dragon, it loops back to Slime.

class BattleScreen extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> characterRef;

  const BattleScreen({super.key, required this.characterRef});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final List<_Monster> _monsters = [
    _Monster(
      name: 'Slime',
      assetPath: 'lib/assets/images/slime.png',
      maxHp: 200,
      xpReward: 20,
    ),
    _Monster(
      name: 'Goblin',
      assetPath: 'lib/assets/images/goblin.png',
      maxHp: 350,
      xpReward: 30,
    ),
    _Monster(
      name: 'Zombies',
      assetPath: 'lib/assets/images/zombies.png',
      maxHp: 500,
      xpReward: 40,
    ),
    _Monster(
      name: 'Witch',
      assetPath: 'lib/assets/images/witch.png',
      maxHp: 750,
      xpReward: 55,
    ),
    _Monster(
      name: 'Dragon',
      assetPath: 'lib/assets/images/dragon.png',
      maxHp: 1000,
      xpReward: 80,
    ),
  ];

  int _currentMonsterIndex = 0;
  late int _enemyHp;

  final int _damagePerHit = 20;
  bool _isAttacking = false;

  @override
  void initState() {
    super.initState();
    _enemyHp = _monsters[_currentMonsterIndex].maxHp;
  }

  @override
  Widget build(BuildContext context) {
    final monster = _monsters[_currentMonsterIndex];
    final double hpPercent = _enemyHp / monster.maxHp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Arena'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enemy card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enemy: ${monster.name}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Center(
                      child: Image.asset(
                        monster.assetPath,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: hpPercent.clamp(0.0, 1.0),
                      minHeight: 16,
                    ),
                    const SizedBox(height: 4),
                    Text('HP: $_enemyHp / ${monster.maxHp}'),
                    const SizedBox(height: 4),
                    Text('Reward: ${monster.xpReward} XP'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Battle instructions
            const Text(
              'Tap "Attack" to damage the enemy.\n'
              'Defeating stronger monsters gives more XP.',
            ),

            const Spacer(),

            // Attack button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAttacking
                    ? null
                    : () async {
                        // Deal damage to the enemy
                        setState(() {
                          _enemyHp -= _damagePerHit;
                          if (_enemyHp < 0) _enemyHp = 0;
                          _isAttacking = true;
                        });

                        // If defeated → add XP
                        if (_enemyHp <= 0) {
                          final defeatedMonster = _monsters[_currentMonsterIndex];
                          final int xpReward = defeatedMonster.xpReward;

                          try {
                            // Use leveling.dart to award XP and handle level-ups
                            final result = await widget.characterRef
                                .awardXpAndMaybeLevelUp(
                              xpReward,
                              increments: {'dailyMonsterProgress': 1},
                            );

                            final leveled = result['leveled'] as bool;

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${monster.name} defeated! +$xpReward XP gained.',
                                  ),
                                ),
                              );
                            }

                            // Move to next monster and reset HP
                            setState(() {
                              _currentMonsterIndex =
                                  (_currentMonsterIndex + 1) % _monsters.length;
                              _enemyHp =
                                  _monsters[_currentMonsterIndex].maxHp;
                            });
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }

                        if (mounted) {
                          setState(() => _isAttacking = false);
                        }
                      },
                child: const Text('Attack (-20 HP)'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Each defeated monster can also count toward your\n'
              '“Defeat 5 monsters” daily quest.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Monster {
  final String name;
  final String assetPath;
  final int maxHp;
  final int xpReward;

  const _Monster({
    required this.name,
    required this.assetPath,
    required this.maxHp,
    required this.xpReward,
  });
}
