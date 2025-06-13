import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class Dog {
  final int id;
  final String name;
  final int age;

  Dog({required this.id, required this.name, required this.age});

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'age': age};
  }

  @override
  String toString() {
    return 'Dog{id: $id, name: $name, age: $age}';
  }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Database database;
  List<Dog> dogList = [];

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  Future<void> initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'doggie_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
        );
      },
      version: 1,
    );
    await loadDogs();
  }

  Future<void> insertDog(Dog dog) async {
    await database.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadDogs();
  }

  Future<void> deleteDog(int id) async {
    await database.delete(
      'dogs',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadDogs();
  }

  Future<void> loadDogs() async {
    final List<Map<String, dynamic>> maps = await database.query('dogs');
    setState(() {
      dogList = List.generate(maps.length, (i) {
        return Dog(
          id: maps[i]['id'],
          name: maps[i]['name'],
          age: maps[i]['age'],
        );
      });
    });
  }

  void showAddDogDialog(BuildContext context) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Dog'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Dog Name'),
              ),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final ageText = ageController.text.trim();

                if (name.isEmpty || ageText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                final age = int.tryParse(ageText);
                if (age == null || age < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Age must be a valid number')),
                  );
                  return;
                }

                final newDog = Dog(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: name,
                  age: age,
                );

                insertDog(newDog);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Database Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Dog Database Example')),
        body: dogList.isEmpty
            ? const Center(child: Text("No dogs found."))
            : ListView.builder(
                itemCount: dogList.length,
                itemBuilder: (context, index) {
                  final dog = dogList[index];
                  return ListTile(
                    title: Text('${dog.name} (Age ${dog.age})'),
                    subtitle: Text('ID: ${dog.id}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await deleteDog(dog.id);
                      },
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showAddDogDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
