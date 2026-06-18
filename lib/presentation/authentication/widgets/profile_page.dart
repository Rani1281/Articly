import 'package:articly/presentation/authentication/view_models/profile_view_model.dart';
import 'package:articly/presentation/authentication/widgets/input_dialog.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key, ProfileViewModel? viewModel})
    : _viewModel = viewModel ?? ProfileViewModel();

  final ProfileViewModel _viewModel;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    widget._viewModel.loadData(); // sets email and username fields
    widget._viewModel.addListener(_checkError); // listen to errors
  }

  void _checkError() {
    final error = widget._viewModel.errorMessage;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _editUsername() async {
    // show a dialog
    final newName = await showDialog<String>(
      context: context,
      builder: (context) =>
          EditUsernameDialog(initialUsername: widget._viewModel.username ?? ''),
    );

    // update the username
    await widget._viewModel.editName(newName);
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeModel>();
    widget._viewModel.loadData();

    return ListenableBuilder(
      listenable: widget._viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            title: const Text('Profile'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Profile Name & Edit Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget._viewModel.username ?? 'User',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _editUsername,
                          icon: Icon(Icons.edit),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50),

                    // Email Section
                    Divider(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget._viewModel.email ?? 'Empty',
                            // style: TextStyle(
                            //   fontSize: 15,
                            //   color: Colors.black87,
                            // ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      title: const Text('Theme'),
                      trailing: DropdownButton<ThemeMode>(
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(10),
                        elevation: 8,
                        value: themeModel.themeMode,
                        onChanged: (value) {
                          if (value != null) {
                            context.read<ThemeModel>().setThemeMode(value);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                      ),
                    ),

                    Divider(),

                    const SizedBox(height: 60),

                    // Log Out Button
                    // TODO: Switch this with a custom button
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await _showLogoutDialog();
                        if (confirmed == true) {
                          widget._viewModel.logOut();
                          Navigator.of(context).pop();
                          // ! Note: this only pops the current route, matching the current homepage -> profile page structure, so if nesting more pages, deleting all navigation stack beforehand is necessary.
                        }
                      },
                      label: const Text('Log out'),
                      icon: Icon(Icons.logout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
