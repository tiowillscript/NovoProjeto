# Arquitetura inicial

## Objetivo
Fornecer uma base para gerenciamento remoto de conteúdo em TVs institucionais, com foco em 5–20 players simultâneos, iniciando com 1 dispositivo e escala gradual.

## Componentes

### 1) API (backend)
Responsável por:
- Autenticação e níveis de acesso (Admin, Operador, Visualizador).
- Upload e catálogo de mídias (vídeos, imagens).
- Agendamento e playlists.
- Sincronização com players.
- Integrações com notícias e clima.

### 2) Player (app)
- Execução em modo tela cheia (Android TV/TV Box).
- Cache local de mídias para reprodução contínua.
- Atualização periódica da agenda.
- Suporte a streams (ex.: YouTube Live via URL).

### 3) Storage de mídia
- S3/MinIO para armazenar arquivos grandes.
- API salva metadados e URLs assinadas.

## Modelo de dados (rascunho)

- **User**: id, nome, email, role (admin/operador/visualizador).
- **Media**: id, tipo (video/imagem/stream), título, duração, url, metadata.
- **Playlist**: id, nome, lista de Media.
- **Schedule**: id, playlist_id, data_início, data_fim, horário_início, horário_fim.
- **Device**: id, nome, status, última_sincronização.

## Integrações externas

- **Clima**: OpenWeather ou alternativa gratuita (consulta por Palmital/PR ou por grupo/dispositivo).
- **Notícias**: RSS local/regional + agregadores públicos (G1, Agência Brasil, feeds locais).

## Regras iniciais

- Formatos: MP4 (H.264), JPG/PNG e WebP (opcional).
- Limite inicial por arquivo: 200MB (ajustável).

## Entregas por etapa

1. **MVP Backend**: healthcheck, auth básica, cadastro de mídia e playlist.
2. **MVP Player**: reprodução de playlist fixa e cache local.
3. **Agendamento**: regras de data/horário.
4. **Integrações**: clima + notícias com atualização automática.
5. **Admin UI**: painel web para gerenciamento.
