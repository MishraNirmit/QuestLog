import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';
import '../models/category.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedIconIndex = 0;

  final List<IconData> _icons = [
    Icons.star,
    Icons.shield,
    Icons.fitness_center,
    Icons.menu_book,
    Icons.computer,
    Icons.eco,
    Icons.work,
    Icons.favorite,
    Icons.brush,
    Icons.music_note,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Category')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('SELECT ICON', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIconIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedIconIndex == index ? Theme.of(context).primaryColor : Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _icons[index],
                        color: _selectedIconIndex == index ? Colors.black : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                onPressed: () async {
                  if (_nameController.text.isNotEmpty) {
                    final provider = Provider.of<QuestProvider>(context, listen: false);
                    try {
                      final newCategory = Category(
                        id: "cat_${DateTime.now().millisecondsSinceEpoch}",
                        name: _nameController.text,
                        icon: _icons[_selectedIconIndex].codePoint.toString(),
                      );
                      await provider.addCategory(newCategory);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  }
                },
                child: const Text('CREATE CATEGORY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
