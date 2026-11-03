
import 'package:flutter/material.dart';

import 'package:main/screens/admin_login.dart';
import 'package:main/screens/visao_geral_page.dart';
import 'package:main/screens/agendamento_page.dart';
import 'package:main/screens/cliente_page.dart';
import 'package:main/screens/disponibilidade_page.dart';
import 'package:main/screens/lembrete_page.dart';
import 'package:main/screens/usuario_page.dart';
import 'package:main/screens/categoria_page.dart';
import 'package:main/screens/servico_page.dart';

import 'package:main/services/api_client.dart';

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
  // Começa na Visão Geral
  int _selectedIndex = 0;

  static const Color vinho = Color(0xFF8E2348);
  static const Color rosaClaro = Color(0xFFFFEEF3);
  static const Color fundo = Color(0xFFFFF8FA);
  static const Color texto = Color(0xFF4A1026);

  static const double larguraMinimaMenuFixo = 800;
  static const double larguraCompacta = 600;
  static const double larguraMenuAmplo = 1100;

  static const double tamanhoMinimoValido = 1;

  // Itens do menu
  static const List<_ItemMenu> _itens = [
    _ItemMenu(Icons.dashboard, 'Visão Geral'),
    _ItemMenu(Icons.room_service, 'Serviços'),
    _ItemMenu(Icons.people, 'Usuários'),
    _ItemMenu(Icons.calendar_month, 'Agendamentos'),
    _ItemMenu(Icons.badge, 'Clientes'),
    _ItemMenu(Icons.category, 'Categorias'),
    _ItemMenu(Icons.notifications, 'Lembretes'),
    _ItemMenu(Icons.access_time, 'Disponibilidades'),
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

  // Volta para a tela de login
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
          content: Text(
            'Sua sessão expirou. Entre novamente.',
          ),
          backgroundColor: vinho,
        ),
      );
    }
  }

  // Controla qual página será exibida
  Widget _construirConteudo() {
    switch (_selectedIndex) {
      case 0:
        return const VisaoGeralPage();

      case 1:
        return const ServicosPage();

      case 2:
        return const UsuarioPage();

      case 3:
        return const AgendamentoPage();

      case 4:
        return const ClientePage();

      case 5:
        return const CategoriasPage();

      case 6:
        return const LembretePage();

      case 7:
        return const DisponibilidadePage();

      default:
        return const Center(
          child: Text('Página não encontrada'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Verifica se as dimensões são válidas
        if (!constraints.hasBoundedWidth ||
            !constraints.hasBoundedHeight ||
            constraints.maxWidth <= tamanhoMinimoValido ||
            constraints.maxHeight <= tamanhoMinimoValido) {
          return const ColoredBox(
            color: fundo,
            child: SizedBox.expand(),
          );
        }

        return _estrutura(constraints.maxWidth);
      },
    );
  }

  // Estrutura principal
  Widget _estrutura(double largura) {
    final bool menuFixo = largura >= larguraMinimaMenuFixo;
    final bool compacto = largura < larguraCompacta;

    final double larguraMenu =
        largura >= larguraMenuAmplo ? 280 : 240;

    return Scaffold(
      backgroundColor: fundo,

      // Barra superior
      appBar: AppBar(
        backgroundColor: vinho,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        toolbarHeight: 56,
        title: Text(
          'Painel Administrativo',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: compacto ? 16 : 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            onPressed: _voltarParaLogin,
          ),
        ],
      ),

      // Menu lateral responsivo
      drawer: menuFixo
          ? null
          : Drawer(
              backgroundColor: rosaClaro,
              child: _menu(fecharAoSelecionar: true),
            ),

      // Corpo principal
      body: Row(
        children: [
          if (menuFixo) ...[
            Material(
              color: rosaClaro,
              child: SizedBox(
                width: larguraMenu,
                child: _menu(),
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFF1DDE5),
            ),
          ],

          // Conteúdo da página
          Expanded(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(compacto ? 12 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _itens[_selectedIndex].titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compacto ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: texto,
                    ),
                  ),

                  Divider(
                    height: compacto ? 20 : 30,
                    color: const Color(0xFFF1DDE5),
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

  // Menu principal
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

  // Itens de navegação
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
