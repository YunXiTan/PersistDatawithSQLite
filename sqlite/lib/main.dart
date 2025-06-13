import 'package:flutter/material.dart';
import 'db_test.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const DogScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DogScreen extends StatefulWidget {
  const DogScreen({super.key});
  @override
  State<DogScreen> createState() => _DogScreenState();
}

class _DogScreenState extends State<DogScreen> {
  List<Dog> dogs = [];

  final nameController = TextEditingController();
  final ageController = TextEditingController();

  Future<void> _refreshDogs() async {
    final fetchedDogs = await DogDatabase.instance.getDogs();
    setState(() {
      dogs = fetchedDogs;
    });
  }

  Future<void> _addDog() async {
  final name = nameController.text.trim();
  final ageText = ageController.text.trim();

  if (name.isEmpty || ageText.isEmpty || int.tryParse(ageText) == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter a valid name and age.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final age = int.parse(ageText);
  final newDog = Dog(id: DateTime.now().millisecondsSinceEpoch, name: name, age: age);
  await DogDatabase.instance.insertDog(newDog);
  nameController.clear();
  ageController.clear();
  _refreshDogs();
}

  Future<void> _deleteDog(int id) async {
    await DogDatabase.instance.deleteDog(id);
    _refreshDogs();
  }

  Future<void> _editDog(Dog dog) async {
    final editNameController = TextEditingController(text: dog.name);
    final editAgeController = TextEditingController(text: dog.age.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Dog'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editNameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: editAgeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
            final newName = editNameController.text.trim();
            final newAgeText = editAgeController.text.trim();

            if (newName.isEmpty || newAgeText.isEmpty || int.tryParse(newAgeText) == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid name and age.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final newAge = int.parse(newAgeText);
            final updatedDog = Dog(id: dog.id, name: newName, age: newAge);
            await DogDatabase.instance.updateDog(updatedDog);
            Navigator.pop(context);
            _refreshDogs();
          },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshDogs();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐶 Dog Manager'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Add a New Dog',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addDog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Dog'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Dog List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dogs.length,
                itemBuilder: (context, index) {
                  final dog = dogs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.pets)),
                      title: Text(dog.name),
                      subtitle: Text('Age: ${dog.age}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editDog(dog),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteDog(dog.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}