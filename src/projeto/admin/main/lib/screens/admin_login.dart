import 'package:flutter/material.dart';
import 'package:main/models/usuario_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Adminlogin extends StatefulWidget {
  const Adminlogin({super.key});

  @override
  State<Adminlogin> createState() => _AdminloginState();
}

class _AdminloginState extends State<Adminlogin> {

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  void dispose(){
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (_emailController.text.isEmpty ||
        _senhaController.text.isEmpty) {
      _mostrarMensagem('Preencha todos os campos', Colors.orange);
      return;
    }

  setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://127.0.0.1:8000/auth/login');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': _emailController.text.trim(),
          'password': _senhaController.text,
        },
      );

      print('Status: ${response.statusCode}');
      print('Resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'];

        _mostrarMensagem(
          'Login realizado com sucesso!',
          Colors.green,
        );

        print('Token recebido: $token');
      } else {
        _mostrarMensagem(
          'Erro no login: ${response.body}',
          Colors.red,
        );
      }
    } catch (e) {
      print('Erro de conexão: $e');

      _mostrarMensagem(
        'Erro de conexão com o servidor.',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  void _mostrarMensagem(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        duration: const Duration(seconds: 3),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Admin'),),
      body: Padding(padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'E-mail',
            border: OutlineInputBorder()
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        
        SizedBox(height: 16),

        TextField(
          controller: _senhaController,
          decoration: InputDecoration(
            labelText: 'Senha',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),

        SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : ElevatedButton(
              onPressed: _fazerLogin,
              child: Text(
                'Entrar',
                style: TextStyle(fontSize: 16),
              ),
            )
        )

        ],
      ),)
    );
  }
}
