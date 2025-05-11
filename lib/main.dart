import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(UserPostApp());

class UserPostApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User & Post Manager',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: DashboardPage(),
    );
  }
}

// Data model for User
class AppUser {
  final int id;
  final String fullName;
  final String emailAddress;
  final String location;

  AppUser({required this.id, required this.fullName, required this.emailAddress, required this.location});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      fullName: json['name'],
      emailAddress: json['email'],
      location: json['address']['city'],
    );
  }
}

// Data model for Post
class BlogPost {
  final int id;
  final String heading;
  final String content;

  BlogPost({required this.id, required this.heading, required this.content});

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'],
      heading: json['title'],
      content: json['body'],
    );
  }

  BlogPost copyWith({required String heading, required String content}) {
    return BlogPost(id: id, heading: heading, content: content);
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<AppUser> userList = [];
  List<BlogPost> postList = [];

  final TextEditingController headingCtrl = TextEditingController();
  final TextEditingController contentCtrl = TextEditingController();
  int? postBeingEdited;

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadPosts();
  }

  Future<void> loadUsers() async {
    final res = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/users'));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      setState(() {
        userList = data.map((item) => AppUser.fromJson(item)).toList();
      });
    }
  }

  Future<void> loadPosts() async {
    final res = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts?_limit=5'));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      setState(() {
        postList = data.map((item) => BlogPost.fromJson(item)).toList();
      });
    }
  }

  Future<void> addPost(String heading, String content) async {
    final res = await http.post(
      Uri.parse('https://jsonplaceholder.typicode.com/posts'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': heading, 'body': content}),
    );
    if (res.statusCode == 201) {
      final newPost = BlogPost.fromJson(json.decode(res.body));
      setState(() {
        postList.insert(0, newPost);
        postBeingEdited = newPost.id;
      });
    }
  }

  Future<void> modifyPost(int id, String heading, String content) async {
    final res = await http.put(
      Uri.parse('https://jsonplaceholder.typicode.com/posts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': heading, 'body': content}),
    );
    if (res.statusCode == 200) {
      setState(() {
        final idx = postList.indexWhere((post) => post.id == id);
        if (idx != -1) {
          postList[idx] = postList[idx].copyWith(heading: heading, content: content);
        }
      });
    }
  }

  Future<void> removePost(int id) async {
    final res = await http.delete(Uri.parse('https://jsonplaceholder.typicode.com/posts/$id'));
    if (res.statusCode == 200) {
      setState(() {
        postList.removeWhere((post) => post.id == id);
        if (postBeingEdited == id) {
          clearForm();
        }
      });
    }
  }

  void submitForm() {
    final heading = headingCtrl.text.trim();
    final content = contentCtrl.text.trim();

    if (heading.isEmpty || content.isEmpty) return;

    if (postBeingEdited != null) {
      modifyPost(postBeingEdited!, heading, content);
    } else {
      addPost(heading, content);
    }

    clearForm();
  }

  void startEditing(BlogPost post) {
    setState(() {
      headingCtrl.text = post.heading;
      contentCtrl.text = post.content;
      postBeingEdited = post.id;
    });
  }

  void clearForm() {
    setState(() {
      headingCtrl.clear();
      contentCtrl.clear();
      postBeingEdited = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User & Post Manager'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Directory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            userList.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Column(
              children: userList.map((user) {
                return ListTile(
                  leading: CircleAvatar(child: Text(user.fullName[0])),
                  title: Text(user.fullName),
                  subtitle: Text('${user.emailAddress} • ${user.location}'),
                );
              }).toList(),
            ),
            Divider(height: 30),

            Text(postBeingEdited != null ? 'Edit Blog Post' : 'New Blog Post',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: headingCtrl,
              decoration: InputDecoration(labelText: 'Post Title'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Post Content'),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: submitForm,
                  child: Text(postBeingEdited != null ? 'Save Changes' : 'Publish'),
                ),
                SizedBox(width: 10),
                if (postBeingEdited != null)
                  ElevatedButton(
                    onPressed: clearForm,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: Text('Cancel'),
                  ),
              ],
            ),

            Divider(height: 30),
            Text('Recent Posts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            postList.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Column(
              children: postList.map((post) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(post.heading, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(post.content),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => startEditing(post),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removePost(post.id),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
