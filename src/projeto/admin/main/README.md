# Painel administrativo Flutter

[Voltar ao README principal](../../../../README.md) | [Documentacao da API](../../backend/README.md)

Aplicacao administrativa Flutter (Web/Desktop) do Studio Cleusa. O painel oferece operacoes de gestao e consome a API FastAPI; nao acessa o banco de dados diretamente.

## Funcionalidades

- Autenticacao administrativa via `/auth/login`.
- Dashboard e visao geral.
- Consulta e gestao de agendamentos e status.
- Gestao de clientes, categorias e servicos.
- Gestao de usuarios administrativos.
- Configuracao de disponibilidades semanais e bloqueios pontuais.
- Consulta e manutencao de lembretes.

## Requisitos e execucao

Instale Flutter SDK e Dart compativeis com `pubspec.yaml`. Inicie o backend e instale as dependencias Flutter:

```powershell
cd src\projeto\admin\main
flutter pub get
flutter run -d chrome
```

Para executar em outro dispositivo, use o alvo apropriado suportado pelo SDK, mantendo o backend acessivel pela rede.

## Conexao e autenticacao

O endereco base esta definido como `http://127.0.0.1:8000` em `lib/services/api_client.dart`. Emuladores e dispositivos fisicos podem exigir o endereco IP acessivel da maquina que hospeda o backend; ajuste `baseUrl` antes de executar fora do host local. Em producao, configure um endpoint HTTPS apropriado.

O login envia e-mail e senha para a API e o cliente HTTP envia o token Bearer nas operacoes protegidas. O cliente remove o token e notifica a interface quando recebe `401`. As requisicoes JSON passam por `ApiClient`, que centraliza decodificacao e mensagens de erro.

## Organizacao do codigo

- `lib/services/api_client.dart`: autenticacao e transporte HTTP.
- `lib/models/`: modelos de agendamento, cliente, servico, categoria, usuario e disponibilidade.
- `lib/screens/`: login, dashboard e telas de gestao por recurso.
- `lib/widgets/`: componentes reutilizaveis do painel.

Consulte [a documentacao da API](../../backend/README.md) para lista completa de rotas, dados esperados e respostas.
