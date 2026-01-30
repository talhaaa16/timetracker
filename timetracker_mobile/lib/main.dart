import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginPage()
          : const DashboardPage(),
    );
  }
}

/* ---------------- LOGIN PAGE ---------------- */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String error = '';

  Future<void> login() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      setState(() => error = "Invalid email or password");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Timetracker Login",
                style: TextStyle(fontSize: 24)),
            const SizedBox(height: 30),

            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),

            ElevatedButton(
              onPressed: loading ? null : login,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- DASHBOARD ---------------- */

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Activity"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          /* -------- PROFILE -------- */
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final data =
                  snapshot.data!.data() as Map<String, dynamic>?;

              final firstName = data?['firstName'] ?? 'User';
              final lastName = data?['lastName'] ?? '';
              final email = data?['email'] ?? '';

              return ListTile(
                title: Text(
                  '$firstName $lastName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(email),
              );
            },
          ),

          const Divider(),

          /* -------- LOGS -------- */
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('logs')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No activity found"),
                  );
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final event = data['event_name'] ?? 'Event';
                    final details = data['details'] ?? '';
                    final timestamp = data['timestamp'];

                    String time = '';
                    if (timestamp != null) {
                      time = timestamp.toString().length >= 16
                          ? timestamp.toString().substring(11, 16)
                          : '';
                    }

                    return ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(event),
                      subtitle: Text(details),
                      trailing: Text(
                        time,
                        style:
                            const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
