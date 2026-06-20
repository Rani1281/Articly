import 'package:articly/presentation/authentication/widgets/profile_page.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ProfilePage()));
            },
          ),
        ],
      ),
      body: Align(
        alignment: AlignmentGeometry.center,
        child: Text('Welcome to Articly!'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => SaveWebsiteScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
