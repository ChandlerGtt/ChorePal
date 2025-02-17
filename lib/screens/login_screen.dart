import 'package:flutter/material.dart';
import 'parent/parent_dashboard.dart';
import 'child/child_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isParent = true;
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChorePal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Parent'),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Child'),
                  ),
                ],
                selected: {_isParent},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isParent = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_isParent) ...[
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ] else ...[
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Family Code',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your family code';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => _isParent
                            ? const ParentDashboard()
                            : const ChildDashboard(),
                      ),
                    );
                  }
                },
                child: Text(_isParent ? 'Login as Parent' : 'Login as Child'),
              ),
              if (_isParent) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Implement parent registration
                  },
                  child: const Text('Register as Parent'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}