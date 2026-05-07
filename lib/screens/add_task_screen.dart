import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final List<int> _selectedDays = [];
  final List<String> _days = ['M', 'T', 'W', 'Th', 'F', 'S', 'Su'];
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuestProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Quest')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Quest Title',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            if (provider.categories.isNotEmpty) ...[
              const Text('CATEGORY', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedCategoryId,
                hint: const Text("Select Category"),
                isExpanded: true,
                dropdownColor: Colors.black87,
                items: provider.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
            const Text('REPEAT SCHEDULE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: List.generate(_days.length, (index) {
                final isSelected = _selectedDays.contains(index);
                return FilterChip(
                  label: Text(_days[index]),
                  selected: isSelected,
                  selectedColor: Theme.of(context).primaryColor,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(index);
                      } else {
                        _selectedDays.remove(index);
                      }
                    });
                  },
                );
              }),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                onPressed: () {
                  if (_titleController.text.isNotEmpty) {
                    final newTask = Task(
                      id: "task_${DateTime.now().millisecondsSinceEpoch}",
                      title: _titleController.text,
                      categoryId: _selectedCategoryId ?? 'default',
                      date: DateTime.now().toIso8601String(),
                      repeatDays: _selectedDays,
                    );
                    provider.addTask(newTask);
                    Navigator.pop(context);
                  }
                },
                child: const Text('ADD QUEST', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
