import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import 'student_home_screen.dart';

class StudentAuthScreen extends StatefulWidget {
  const StudentAuthScreen({super.key});

  @override
  State<StudentAuthScreen> createState() => _StudentAuthScreenState();
}

class _StudentAuthScreenState extends State<StudentAuthScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Área do aluno')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                const CircleAvatar(radius: 34, child: Icon(Icons.school_outlined, size: 36)),
                const SizedBox(height: 16),
                Text('Acompanhe suas aulas', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Entre com sua conta ou faça seu primeiro cadastro.'),
                const SizedBox(height: 24),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Seu nome', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 10),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline))),
                const SizedBox(height: 10),
                TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy || !app.auth.firebaseReady ? null : _signIn,
                    child: Padding(padding: const EdgeInsets.all(14), child: Text(busy ? 'Entrando...' : 'ENTRAR')),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: busy || !app.auth.firebaseReady ? null : _register,
                    child: const Padding(padding: EdgeInsets.all(14), child: Text('CRIAR CONTA DE ALUNO')),
                  ),
                ),
                if (!app.auth.firebaseReady) ...[
                  const SizedBox(height: 18),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('A área do aluno será ativada assim que este APK estiver conectado ao projeto Firebase da turma.'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => busy = true);
    final app = context.read<AppController>();
    final error = await app.auth.signIn(email.text.trim(), password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final role = await app.auth.currentRole();
    if (!mounted) return;
    setState(() => busy = false);
    if (role != 'student') {
      await app.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta conta está cadastrada como professor.')));
      return;
    }
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()), (_) => false);
  }

  Future<void> _register() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe seu nome.')));
      return;
    }
    setState(() => busy = true);
    final app = context.read<AppController>();
    final error = await app.auth.register(
      email.text.trim(),
      password.text,
      name: name.text.trim(),
      role: 'student',
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()), (_) => false);
  }
}
