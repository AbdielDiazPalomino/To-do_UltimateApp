import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Task{
  int id;
  String title;
  String description;
  bool completed;

  Task(this.id, this.title, this.description, this.completed);

  Map<String, dynamic> toMap(){
    return{
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
    };
  }
}

void main() {
  runApp(const MyApp());
}

Color appbarColorLight = Color(0xFF345EA8);
Color backgroundColorLight = Color(0xFFFFFFFF);
Color cardColorLight = Color(0xFFE3E1E6); // color del card y del input
// donde se colocan las tareas

Color appbarColorDark = Color(0xFF34374B);
Color backgroundColorDark = Color(0xFF191B28);

Color buttomDarkActive = Color(0xFF5b618a);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-do App',
      theme: ThemeData(


        appBarTheme: AppBarTheme(
          color: appbarColorLight,
        )
      ),
      home: ToDoScreen(),
      debugShowCheckedModeBanner: false,

    );
  }
}
// stateful vs stateless
class ToDoScreen extends StatefulWidget {
  @override
  _ToDoScreenState createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {

  TextEditingController _taskController = TextEditingController();
  TextEditingController _editTaskController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  List<Task> tasks = [];
  int editingIndex = -1;
  int _currentPage = 0;

  bool isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();

  }

  // (0,1,2,3)

  void _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tasks = (prefs.getStringList('tasks') ?? []).map((taskString) {
      Map<String, dynamic> taskMap = json.decode(taskString);
        return Task(
          taskMap['id'] ?? DateTime.now().millisecondsSinceEpoch,
          taskMap['title'],
          taskMap['description'] ?? '',
          taskMap['completed'] ?? false,

        );
      }).toList();
    });
  }

  void _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskStrings = tasks.map((task) => json.encode(task.toMap())).toList();
    prefs.setStringList('tasks', taskStrings);
  }

  void _addTask(String task, String description) {
    setState(() {
      int newId = DateTime.now().millisecondsSinceEpoch;
      tasks.add(Task(newId, task, description, false));
      _saveTasks();
    });
  }

  void _editTask(int index, String task, String description){
    setState(() {
      tasks[index].title = task;
      if(description.isNotEmpty){
        tasks[index].description = description;
      }

      editingIndex = -1;
      _saveTasks();

    });
  }

  void _removeTask(int index) {
    setState(() {
      tasks.removeAt(index);
      _saveTasks();
    });
  }

  void _toggleTask(int index){
    setState(() {
      tasks[index].completed = !tasks[index].completed;
      _saveTasks();
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _showFloatingWindow(int index){
    _descriptionController.text = tasks[index].description ?? '';

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Descripción"),
            backgroundColor: Colors.white,
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.25,
                        ),
                        child: TextField(
                          cursorColor: Colors.blue,
                          maxLines: null,
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText: 'Ingrese una descripción',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[400],
                          ),
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ),
                    SizedBox(height: 10,)
                  ],
                );
              }
            ),
            actions: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: isDarkMode?
                              MaterialStateProperty.all<Color>(appbarColorDark)
                              : MaterialStateProperty.all<Color>(appbarColorLight),
                ),
                  onPressed: (){
                    _editTask(index, tasks[index].title, _descriptionController.text);
                    Navigator.pop(context);
                    _descriptionController.clear();
                  },
                  child: Text("Guardar", style: TextStyle(color: Colors.white))
              ),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: isDarkMode?
                    MaterialStateProperty.all<Color>(appbarColorDark)
                        : MaterialStateProperty.all<Color>(appbarColorLight),
                  ),
                  onPressed: (){

                    Navigator.pop(context);

                  },
                  child: Text("Cerrar", style: TextStyle(color: Colors.white))
              ),
            ],
          );
        }
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode? backgroundColorDark : backgroundColorLight,
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Center(
          child: Text(
            'To-Do App',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,

            ),

          ),
        ),
        backgroundColor: isDarkMode ? appbarColorDark : appbarColorLight,
        actions: [
          editingIndex == -1
          ? Container()
          : IconButton(

              icon: Icon(Icons.check, color: Colors.white,),
              onPressed: (){
                _editTask(editingIndex, _editTaskController.text, '');
              },
          ),

          editingIndex == -1
          ? Container()
          : IconButton(

            icon: Icon(Icons.cancel, color: Colors.white,),
            onPressed: (){
              setState(() {
                editingIndex = -1;
              });

            },
          ),

        ],
      ),

      body: _currentPage == 0? _buildTasksPage() : _buildConfigPage(),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode? appbarColorDark :appbarColorLight,
        currentIndex: _currentPage,
        selectedItemColor: Colors.white,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: "To-do's",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Config",
          ),

        ],
      ),

    );
  }
  Widget _buildTasksPage(){
    return Container(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 15,
              bottom: 10,
              left: 13,
              right: 13,

            ),

            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFE3E1E6),
                borderRadius: BorderRadius.circular(10.0)
              ),

              padding: EdgeInsets.only(top: 16, left: 16, right: 16),
              child: TextField(
                cursorColor: Colors.blue,
                maxLength: 20,
                controller: _taskController,
                decoration: InputDecoration(
                  hintText: 'Ingrese una tarea',
                  border: InputBorder.none,
                ),
                onSubmitted: (value){
                  _addTask(value, '');
                  _taskController.clear();
                },
              ),
            ),
          ),

          Expanded(

            child: Card(

              elevation: 0,
              color: isDarkMode? backgroundColorDark : Colors.grey[300],

              child: ReorderableListView.builder(
                  padding: EdgeInsets.only(top:6), // top es la franjita
                  // gris superior antes de las tareas
                  itemCount: tasks.length,
                  onReorder: (oldIndex, newIndex){
                    setState(() {
                      if(newIndex > oldIndex){
                        newIndex -=1;
                      }
                      final task = tasks.removeAt(oldIndex);
                      tasks.insert(newIndex, task);
                      _saveTasks();
                    });
                  },
                  itemBuilder: (context, index) {
                    return ListTile(
                      minVerticalPadding: 0,
                      key: Key('${tasks[index].id}'),
                      contentPadding: EdgeInsets.only(top:8, left: 10,right: 10, bottom: 8), // top:8

                      title: editingIndex == index
                        ? Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: TextField(
                              cursorColor: Colors.blue,
                              maxLength: 20,
                              decoration: InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                )
                              ),
                              controller: _editTaskController,
                              onSubmitted: (value) {
                                _editTask(index, value, '');
                              },

                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              _showFloatingWindow(index);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)
                              ),
                              padding: EdgeInsets.only(top: 10, bottom: 10, left: 6, right: 6),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            activeColor: isDarkMode? appbarColorDark : appbarColorLight,
                                            value: tasks[index].completed,
                                            onChanged: (_) => _toggleTask(index),
                                          ),
                                          Text(
                                            tasks[index].title,
                                            style: TextStyle(
                                              decoration: tasks[index].completed
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),

                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            child: Icon(Icons.edit),
                                            onTap: () {
                                              setState(() {
                                                editingIndex = index;
                                                _editTaskController.text = tasks[index].title;
                                              });

                                            },
                                          ),

                                          IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: () {
                                              _removeTask(index);
                                            },
                                          ),

                                        ],
                                      ),

                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                    );
                  }
              ),
            ))

        ],
      ),
    );
  }

  Widget _buildConfigPage(){
    return Container(
      color: isDarkMode? backgroundColorDark : Colors.white,
      child: Center(
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                "Astro HelloWorld",
                style: TextStyle(fontSize: 24, color: isDarkMode? Colors.white : Colors.black),
            ),

            Switch(
                value: isDarkMode,
                activeColor: buttomDarkActive,

                onChanged: (value){
                  setState(() {
                    isDarkMode = !isDarkMode;
                  });
                }
            ),



          ],
        )

        ),
    );
  }

}