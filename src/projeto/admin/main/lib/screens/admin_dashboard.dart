
import 'package:flutter/material.dart';

import 'package:main/screens/admin_login.dart';
import 'package:main/screens/usuario_page.dart';
import 'package:main/services/api_client.dart';
import 'package:main/screens/categoria_page.dart';
import 'package:main/screens/servico_page.dart';

class _ItemMenu {
  final IconData icone;
  final String titulo;

  const _ItemMenu(this.icone, this.titulo);
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const Color vinho = Color(0xFF8E2348);
  static const Color rosaClaro = Color(0xFFFFEEF3);
  static const Color fundo = Color(0xFFFFF8FA);
  static const Color texto = Color(0xFF4A1026);

  static const double larguraMinimaMenuFixo = 800;

  static const List<_ItemMenu> _itens = [
    _ItemMenu(Icons.room_service, 'Gerenciar Serviços'),
    _ItemMenu(Icons.people, 'Gerenciar Usuários'),
    _ItemMenu(Icons.calendar_month, 'Gerenciar Agendamentos'),
    _ItemMenu(Icons.badge, 'Gerenciar Clientes'),
    _ItemMenu(Icons.category, 'Gerenciar Categorias'),
    _ItemMenu(Icons.notifications, 'Gerenciar Lembretes'),
    _ItemMenu(Icons.access_time, 'Gerenciar Disponibilidades'),
  ];

  @override
  void initState() {
    super.initState();

    ApiClient.instancia.aoExpirarSessao =
        () => _voltarParaLogin(sessaoExpirou: true);
  }

  @override
  void dispose() {
    ApiClient.instancia.aoExpirarSessao = null;
    super.dispose();
  }

  void _voltarParaLogin({bool sessaoExpirou = false}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    ApiClient.instancia.sair();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const Adminlogin(),
      ),
    );

    if (sessaoExpirou) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sua sessão expirou. Entre novamente.'),
          backgroundColor: vinho,
        ),
      );
    }
  }

  Widget _construirConteudo() {
    switch (_selectedIndex) {

      case 0:
        return const ServicosPage();
      case 1:
        return const UsuarioPage();

      case 4:
        return const CategoriasPage();

      default:
        return Center(
          child: Text(
            ''
            '"${_itens[_selectedIndex].titulo}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool menuFixo =
        MediaQuery.of(context).size.width >= larguraMinimaMenuFixo;

    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: vinho,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Painel Administrativo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _voltarParaLogin,
          ),
        ],
      ),

      drawer: menuFixo
          ? null
          : Drawer(
              backgroundColor: rosaClaro,
              child: _menu(fecharAoSelecionar: true),
            ),

      body: Row(
        children: [
          if (menuFixo) ...[
            Material(
              color: rosaClaro,
              child: SizedBox(
                width: 280,
                child: _menu(),
              ),
            ),

            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFF1DDE5),
            ),
          ],

          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _itens[_selectedIndex].titulo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: texto,
                    ),
                  ),

                  const Divider(
                    height: 30,
                    color: Color(0xFFF1DDE5),
                  ),

                  Expanded(
                    child: _construirConteudo(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu({bool fecharAoSelecionar = false}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Text(
            'Menu Principal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: vinho,
            ),
          ),
        ),

        for (int i = 0; i < _itens.length; i++)
          _buildNavItem(
            i,
            _itens[i],
            fecharAoSelecionar,
          ),
      ],
    );
  }

  Widget _buildNavItem(
    int index,
    _ItemMenu item,
    bool fecharAoSelecionar,
  ) {
    final bool isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        item.icone,
        color: isSelected ? vinho : Colors.black87,
      ),

      title: Text(
        item.titulo,
        style: TextStyle(
          fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? vinho : Colors.black87,
        ),
      ),

      selected: isSelected,
      selectedTileColor: vinho.withOpacity(0.12),

      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        if (fecharAoSelecionar) {
          Navigator.pop(context);
        }
      },
    );
  }
}
