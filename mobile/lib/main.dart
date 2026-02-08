import 'package:flutter/material.dart';

import 'screens/login.dart';
import 'screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CadastroMunicipalApp());
}

class CadastroMunicipalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro Municipal Offline',
      theme: ThemeData(useMaterial3: true),

      // ✅ inicia sempre no login (compila e não dá tela cinza)
      initialRoute: '/login',

      routes: {
        "/": (_) => LoginScreen(),
        "/login": (_) => LoginScreen(),
        "/home": (_) => HomeScreen(),
      },

      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Erro")),
          body: Center(child: Text("Rota não encontrada: ${settings.name}")),
        ),
      ),
    );
  }
}
