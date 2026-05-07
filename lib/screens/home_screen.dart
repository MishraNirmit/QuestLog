import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';
import 'analytics_screen.dart';
import 'add_task_screen.dart';
import 'add_category_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuestProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuestLog', style: TextStyle(fontFamily: 'monospace')),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCategoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Power Bar
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("POWER LEVEL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("${(provider.getPowerBarPercentage() * 100).toInt()}%",
                            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: provider.getPowerBarPercentage(),
                      backgroundColor: Colors.grey[800],
                      color: Theme.of(context).primaryColor,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("ACTIVE QUESTS", style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Expanded(
              child: provider.tasks.isEmpty
                  ? const Center(child: Text("No active quests.", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: provider.tasks.length,
                      itemBuilder: (context, index) {
                        final task = provider.tasks[index];
                        return Card(
                          color: Colors.black54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: task.isCompleted ? Theme.of(context).primaryColor : Colors.white24,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: task.isCompleted ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary,
                            ),
                            title: Row(
                              children: [
                                if (task.categoryId != 'default') ...[
                                  Builder(
                                    builder: (context) {
                                      final catIndex = provider.categories.indexWhere((c) => c.id == task.categoryId);
                                      if (catIndex != -1) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Icon(
                                            IconData(int.parse(provider.categories[catIndex].icon), fontFamily: 'MaterialIcons'),
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                                Expanded(
                                  child: Text(task.title, style: TextStyle(
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted ? Colors.white54 : Colors.white,
                                  )),
                                ),
                              ],
                            ),
                            onTap: () {
                              provider.toggleTaskCompletion(task.id);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
        },
      ),
    );
  }
}
