# Aplicativo do cliente Flutter

[Voltar ao README principal](../../../../README.md) | [Documentacao da API](../../backend/README.md)

Aplicativo Flutter para consulta de servicos e agendamento de atendimentos, com acesso da cliente a seus agendamentos por codigo enviado por e-mail. A comunicacao de dados e feita pela API FastAPI.

## Fluxos principais

- Consulta categorias, servicos ativos, feriados e horarios livres.
- Cria agendamento com identificacao, telefone, e-mail, consentimento e preferencia de lembretes.
- Solicita codigo por e-mail e consulta agendamentos da cliente.
- Permite cancelar quando o status e a antecedencia atendem as regras do backend.
- Permite atualizar telefone e ativar/desativar lembretes por e-mail.

## Requisitos e execucao

Instale Flutter SDK e Dart compativeis com `pubspec.yaml`, tenha a API em execucao e instale as dependencias:

```powershell
cd src\projeto\flutter\flutter-app
flutter pub get
flutter run
```

Para navegador:

```powershell
flutter run -d chrome
```

## Conexao com a API

O endereco base esta definido como `http://127.0.0.1:8000` em `lib/data/api_service.dart`. Para desenvolvimento em emulador ou dispositivo fisico, `127.0.0.1` pode apontar para o proprio dispositivo; substitua o endereco base pelo host acessivel da API antes de executar nesse ambiente. Para implantacao, use o endereco HTTPS da API publicada.

O app usa principalmente `GET /categorias`, `GET /servicos/ativos`, `GET /agendamentos/horarios-livres`, `POST /agendamentos` e as rotas publicas `/agendamentos/acesso/*` e `/agendamentos/minhas*`. O token de cliente e guardado localmente pelo servico de sessao para permitir novo acesso sem pedir codigo a cada abertura.

## Codigo-fonte

- `lib/data/api_service.dart`: cliente HTTP e tratamento de erros.
- `lib/data/agendamento_repository.dart`: chamadas da API e conversao dos dados.
- `lib/data/sessao_cliente.dart`: persistencia da sessao no dispositivo.
- `lib/ui/screens/`: telas de inicio, servicos, identificacao, revisao, status e agendamentos da cliente.
- `lib/models/`: modelos de resposta e dados usados na interface.

Consulte [a documentacao da API](../../backend/README.md) para exemplos dos payloads, autenticacao de cliente, limites e codigos de resposta.
