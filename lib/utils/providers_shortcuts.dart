import 'package:articly/data/services/shared_preferences_service.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyProviders {
  const MyProviders(this.context);

  final BuildContext context;

  UserProvider savedItemsProvider() =>
      Provider.of<UserProvider>(context, listen: false);

  SharedPreferencesService sharedPreferencesService() =>
      Provider.of<SharedPreferencesService>(context, listen: false);

  ThemeModel themeModel() => Provider.of<ThemeModel>(context, listen: false);
}
