# Deploy em VPS com Docker Compose

## VPS sugerida (inicial)

- Hostinger, Vultr ou DigitalOcean
- **2 vCPU / 4GB RAM** para começar (escala conforme a quantidade de TVs e volume de mídia)

## Estrutura simples de deploy

1. Instalar Docker e Docker Compose na VPS.
2. Fazer checkout do repositório.
3. Ajustar variáveis de ambiente (quando existirem).
4. Subir os serviços com `docker compose up -d`.

## Exemplo de fluxo de atualização

```bash
ssh usuario@seu-servidor
cd /opt/tv-signage

git pull

docker compose up -d --build
```

## Observações

- O armazenamento de mídias pode ser um bucket (S3/MinIO) para evitar saturar o disco da VPS.
- Para o player dedicado, a comunicação será via HTTPS, com cache offline no dispositivo.
