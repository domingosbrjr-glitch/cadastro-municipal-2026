import 'package:flutter/material.dart';

import 'auth_store.dart';
import 'screens/login.dart';
import 'screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CadastroMunicipalApp());
}

class CadastroMunicipalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final token = AuthStore.getTokenSync(); // pode ser vazio

    return MaterialApp(
      title: 'Cadastro Municipal Offline',
      theme: ThemeData(useMaterial3: true),

      // ✅ rota inicial sempre existe
      home: (token != null && token.isNotEmpty) ? HomeScreen() : LoginScreen(),

      // ✅ rotas nomeadas (sem const)
      routes: {
        "/": (_) => (token != null && token.isNotEmpty) ? HomeScreen() : LoginScreen(),
        "/login": (_) => LoginScreen(),
        "/home": (_) => HomeScreen(),
      },

      // ✅ não deixa travar se chamar uma rota errada
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Erro")),
          body: Center(child: Text("Rota não encontrada: ${settings.name}")),
        ),
      ),
    );
  }
}
