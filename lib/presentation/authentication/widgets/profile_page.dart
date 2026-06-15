import 'package:articly/presentation/authentication/view_models/profile_view_model.dart';
import 'package:articly/presentation/authentication/widgets/auth_page.dart';
import 'package:articly/presentation/authentication/widgets/input_dialog.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
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
                        // TODO: switch to a predefined theme
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
                    Divider(color: Colors.grey.shade300, thickness: 1),
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
                    Divider(),

                    const SizedBox(height: 60),

                    // Log Out Button
                    // TODO: Switch this with a custom button
                    ElevatedButton.icon(
                      onPressed: () {
                        widget._viewModel.logOut();
                        Navigator.of(context).pop();
                        // ! Note: this only pops the current route, matching the current homepage -> profile page structure, so if nesting more pages, deleting all navigation stack beforehand is necessary.
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

                    // OutlinedButton.icon(
                    //   onPressed: widget._viewModel.logOut,
                    //   icon: const Icon(
                    //     Icons.logout,
                    //     size: 20,
                    //     color: Color(
                    //       0xFF002244,
                    //     ), // Dark navy/black to match the image
                    //   ),
                    //   label: const Text(
                    //     'Log out',
                    //     style: TextStyle(
                    //       color: Color(0xFF002244),
                    //       fontSize: 14,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    //   style: OutlinedButton.styleFrom(
                    //     side: BorderSide(color: Colors.grey.shade400, width: 1),
                    //     // The image shows completely sharp, square corners
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 36,
                    //       vertical: 16,
                    //     ),
                    //   ),
                    // ),
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
