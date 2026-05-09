import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/api_client.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiClient();
  api.initialize();
  await api.loadToken();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}