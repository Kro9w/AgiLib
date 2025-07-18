import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'signup_page.dart';
import 'login_page.dart';

final database = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: "https://agilib-29cf3-default-rtdb.asia-southeast1.firebasedatabase.app",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AgiLib());
}

class AgiLib extends StatelessWidget {
  const AgiLib({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return snapshot.hasData ? const HomePage() : const AuthSelectionPage();
      },
    );
  }
}

class AuthSelectionPage extends StatelessWidget {
  const AuthSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text("Login"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPage()),
                );
              },
              child: const Text("Signup"),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Alignment _currentAlignment = Alignment.centerLeft;
  Alignment _lastAlignment = Alignment.centerLeft;

  final List<IconData> _icons = [
    Icons.home,
    Icons.search,
    Icons.library_books,
  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _lastAlignment = _currentAlignment;
      _currentAlignment = [
        Alignment.centerLeft,
        Alignment.center,
        Alignment.centerRight,
      ][index];
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFD73A33),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    TweenAnimationBuilder<Alignment>(
                      tween: AlignmentTween(
                        begin: _lastAlignment,
                        end: _currentAlignment,
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      builder: (context, alignment, child) {
                        return Align(
                          alignment: alignment,
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          width: 100,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFE0E2),
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_icons.length, (index) {
                        return SizedBox(
                          width: 100,
                          height: 70,
                          child: Center(
                            child: IconButton(
                              icon: Icon(
                                _icons[index],
                                color: _selectedIndex == index
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              onPressed: () => _onItemTapped(index),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String fullName = "User";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final ref = database.ref().child('users/$uid');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          fullName = "${data['name']} ${data['surname']}";
          loading = false;
        });
      } else {
        setState(() {
          fullName = "User";
          loading = false;
        });
      }
    } else {
      // UID is null, do nothing for nao
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  void showUserPopupMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Popup",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Transform.translate(
            offset: Offset(0, -100 + animation.value * 100),
            child: Opacity(
              opacity: animation.value,
              child: Center(
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        fullName,
                        style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.none),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "CICS",
                        style: TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.none),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "22-10055",
                        style: TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.none),
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1, color: Colors.grey),
                      const SizedBox(height: 20),
                      const Text(
                        "Profile",
                        style: TextStyle(fontSize: 15, color: Colors.black, decoration: TextDecoration.none),
                      ),
                      const SizedBox(height: 50),
                      const Text(
                        "Library Card",
                        style: TextStyle(fontSize: 15, color: Colors.black, decoration: TextDecoration.none),
                      ),
                      const SizedBox(height: 50),
                      GestureDetector(
                        onTap: () => FirebaseAuth.instance.signOut(),
                        child: const Text(
                          "Logout",
                          style: TextStyle(fontSize: 15, color: Colors.black, decoration: TextDecoration.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        '$fullName!',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => showUserPopupMenu(context),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDA941),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: ListView(
        scrollDirection: Axis.vertical,
        children: const [
          SizedBox(height: 100, child: Placeholder()),
          SizedBox(height: 100, child: Placeholder()),
          SizedBox(height: 100, child: Placeholder()),
        ],
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: ListView(
        scrollDirection: Axis.vertical,
        children: const [
          SizedBox(height: 100, child: Placeholder()),
          SizedBox(height: 100, child: Placeholder()),
          SizedBox(height: 100, child: Placeholder()),
        ],
      ),
    );
  }
}