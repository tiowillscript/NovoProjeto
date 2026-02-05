# Sistema de Gerenciamento de Propagandas de TV Institucional

Este repositório inicia o desenvolvimento de um sistema para gerenciar propagandas, playlists e conteúdo institucional exibido em TVs com player dedicado. O foco inicial é criar uma base modular que permita evoluir rapidamente para:

- Upload e catálogo de vídeos/imagens.
- Agendamento com horários e durações.
- Player dedicado em aplicativo (mobile/TV).
- Integrações automáticas de notícias e previsão do tempo.
- Monitoramento e auditoria de exibição.

## Stack proposta (inicial)

- **Backend**: Python + FastAPI (API leve, fácil de escalar e integrar).
- **Banco**: PostgreSQL.
- **Storage**: S3/MinIO (mídias grandes).
- **App**: React Native (Expo) para player dedicado (Android TV/TV Box).
- **Infra**: Docker Compose para desenvolvimento local e VPS para produção.

Sugestão de VPS inicial: Hostinger, Vultr ou DigitalOcean com **2 vCPU / 4GB RAM**.

## Perfis de acesso (planejado)

- **Admin**: controle total (usuários, mídia, agenda, dispositivos).
- **Operador**: criar/editar playlists e agendamentos.
- **Visualizador**: somente leitura/monitoramento.

## Estrutura do repositório

```
.
├── backend/          # API e serviços
├── mobile/           # Aplicativo player (a definir)
└── docs/             # Documentação de arquitetura e plano
```

## Próximos passos

1. Definir modelo de dados (mídias, playlists, agenda, dispositivos, usuários).
2. Criar endpoints de autenticação e upload com limite inicial de 200MB por mídia.
3. Implementar player dedicado com cache offline e atualização automática.
4. Integrar APIs públicas (notícias via RSS e clima via OpenWeather ou similar).

Consulte `docs/architecture.md` para o plano detalhado (incluindo escala inicial de 5–20 TVs e formatos suportados) e `docs/deployment.md` para a sugestão de deploy em VPS com Docker Compose.
