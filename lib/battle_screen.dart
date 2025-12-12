// lib/battle_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/leveling.dart'; // our leveling utility

/// --------------------------------------
/// BATTLE & ENCOUNTER SYSTEM
/// --------------------------------------
/// - One enemy ("Slime") with 100 HP.
/// - "Attack" button deals 20 damage.
/// - When HP <= 0:
///     * Enemy is "defeated"
///     * Character gains +20 XP in Firestore
///     * Enemy HP resets to 100

class BattleScreen extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> characterRef;

  const BattleScreen({super.key, required this.characterRef});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  int enemyHp = 100;
  final int enemyMaxHp = 100;
  final int damagePerHit = 20;
  final int xpReward = 20;
  final String enemyName = 'Slime';
  bool isAttacking = false;

  @override
  Widget build(BuildContext context) {
    final double hpPercent = enemyHp / enemyMaxHp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Arena'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enemy: $enemyName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                'lib/assets/images/slime.png',
                height: 150,
              ),
            ),
            const SizedBox(height: 16),

            // Enemy HP bar
            LinearProgressIndicator(
              value: hpPercent.clamp(0.0, 1.0),
              minHeight: 16,
            ),
            const SizedBox(height: 4),
            Text('HP: $enemyHp / $enemyMaxHp'),
            const SizedBox(height: 24),

            // Battle instructions
            const Text(
              'Tap "Attack" to damage the enemy.\nDefeating the enemy gives +20 XP.',
            ),
            const Spacer(),

            // Attack button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAttacking
                    ? null
                    : () async {
                        // Deal damage to the enemy
                        setState(() {
                          enemyHp -= damagePerHit;
                          if (enemyHp < 0) enemyHp = 0;
                          isAttacking = true;
                        });

                        // If enemy is defeated → award XP
                        if (enemyHp <= 0) {
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
                                    '$enemyName defeated! +$xpReward XP'
                                    '${leveled ? ' and leveled up!' : ''}',
                                  ),
                                ),
                              );
                            }

                            // Reset enemy HP for next battle
                            setState(() {
                              enemyHp = enemyMaxHp;
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
                          setState(() => isAttacking = false);
                        }
                      },
                child: const Text('Attack (-20 HP)'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
