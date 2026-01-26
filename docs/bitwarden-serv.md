# Vaultwarden + Cloudflare Tunnel (Docker Compose) — Setup Guide

## Target outcome

- Vaultwarden доступен из интернета по **статичному URL** через Cloudflare Tunnel.
- Нет публичного IPv4 и не нужно открывать входящие порты.
- Запуск и управление — через `docker compose`.
- Минимальная архитектура: всего 2 контейнера (Vaultwarden + cloudflared).

---

## Архитектура

```
Internet → Cloudflare Edge → cloudflared tunnel → vaultwarden:80
```

### Почему Cloudflare Tunnel вместо ngrok?

| Критерий             | ngrok (Hobbyist $8)    | Cloudflare Tunnel |
| -------------------- | ---------------------- | ----------------- |
| Interstitial warning | Да (на free subdomain) | Нет               |
| Стоимость            | $8/месяц               | Бесплатно         |
| Свой домен           | Доп. настройка         | Встроено          |
| Контейнеров          | 3 (+ Caddy для WS)     | 2                 |

### Почему не нужен Caddy?

Vaultwarden 1.29+ обслуживает WebSocket на том же порту (80), что и HTTP API. Отдельная маршрутизация больше не требуется.

---

## Task 01 — Подготовить prerequisites ✅

### Steps

1. Убедиться, что на хосте установлен Docker + Compose.
2. Иметь (или купить) собственный домен.
3. Создать бесплатный аккаунт Cloudflare: https://dash.cloudflare.com/sign-up

### Manual test

- `docker --version` и `docker compose version` должны отработать без ошибок.
- Есть доступ к Cloudflare dashboard.

---

## Task 02 — Добавить домен в Cloudflare ✅

### Steps

1. В Cloudflare dashboard: **Add a site** → ввести свой домен.
2. Выбрать план **Free**.
3. Cloudflare покажет два nameserver'а (например, `anna.ns.cloudflare.com`, `bob.ns.cloudflare.com`).
4. У регистратора домена (где покупал домен) заменить NS-записи на указанные Cloudflare.
5. Подождать от 5 минут до 24 часов (обычно ~10-30 минут).

### Manual test

- В Cloudflare dashboard статус домена должен стать **Active**.
- `dig NS yourdomain.com` должен показывать cloudflare nameservers.

> **Важно:** После смены NS установить SSL/TLS режим в **Full** (SSL/TLS → Overview), чтобы избежать проблем с существующими сайтами на домене.

---

## Task 03 — Создать Cloudflare Tunnel ✅

### Steps

1. Перейти в **Cloudflare Zero Trust**: https://one.dash.cloudflare.com/
2. В боковом меню: **Networks** → **Tunnels**.
3. Нажать **Create a tunnel**.
4. Тип: **Cloudflared** (рекомендуется).
5. Дать имя туннелю, например: `vaultwarden`.
6. На шаге "Install and run a connector" выбрать **Docker**.
7. **Скопировать токен** (длинная строка `eyJhIjoi...`) — он понадобится для `.env`.
8. Пока **не закрывать** мастер — публичный hostname настроим в Task 04.

### Manual test

- Токен скопирован и сохранён в безопасное место.

---

## Task 04 — Настроить публичный hostname в туннеле

### Steps

1. В мастере создания туннеля (или позже в настройках туннеля):
   - **Public Hostnames** → **Add a public hostname**.
2. Заполнить:
   - **Subdomain**: `vault` (или другой, например `bw`, `passwords`)
   - **Domain**: выбрать свой домен из списка
   - **Service Type**: `HTTP`
   - **URL**: `vaultwarden:80`
3. Сохранить.

### Manual test

- В списке Public Hostnames появилась запись `vault.yourdomain.com → http://vaultwarden:80`.

> **Примечание:** Cloudflare автоматически создаёт CNAME-запись для hostname. Если у тебя уже есть wildcard (`*`) A-запись для Coolify — она продолжит работать. Конкретные записи (CNAME для туннеля) имеют приоритет над wildcard.

---

## Task 05 — Создать структуру проекта

### Steps

1. Структура проекта — всё в директории `vaultwarden/`:

```bash
mkdir -p vaultwarden
cd vaultwarden
```

2. Создать директорию для данных **вне проекта** (например, на отдельном диске или в `/var/lib`):

```bash
sudo mkdir -p /var/lib/vaultwarden
sudo chown $USER:$USER /var/lib/vaultwarden
```

3. Создать файлы в `vaultwarden/`:

- `docker-compose.yml`

> **Примечание:** Переменные окружения хранятся в корневом `.env` (секция VAULTWARDEN). Шаблон — в корневом `.env.example`.

### Manual test

- `ls -la vaultwarden/` показывает `docker-compose.yml`.
- Директория данных существует и доступна для записи: `test -w /var/lib/vaultwarden && echo OK`

---

## Task 06 — Заполнить `.env`

### Steps

Переменные Vaultwarden хранятся в **корневом** `.env.example` (с префиксом `VW_`).

Если `.env` ещё не создан:

```bash
cp .env.example .env
```

Заполнить секцию Vaultwarden в `.env`:

```dotenv
# =============================================================================
# VAULTWARDEN
# =============================================================================

# Path to Vaultwarden data directory (outside the repo!)
VW_DATA_DIR=/var/lib/vaultwarden

# Public URL (your domain via Cloudflare Tunnel)
VW_PUBLIC_URL=https://vault.yourdomain.com

# Allow new user registrations (set to false after creating first user)
VW_SIGNUPS_ALLOWED=true

# Admin panel token (generate with: openssl rand -base64 48)
VW_ADMIN_TOKEN=

# Cloudflare Tunnel token
VW_CF_TUNNEL_TOKEN=eyJhIjoiY2U...
```

**Генерация VW_ADMIN_TOKEN:**

```bash
openssl rand -base64 48
```

### Manual test

- Проверить, что переменные читаются:

```bash
set -a; source ./.env; set +a
echo "$VW_PUBLIC_URL"
echo "$VW_DATA_DIR"
```

Должно вывести URL и путь к данным.

- Проверить, что директория данных существует:

```bash
test -d "$VW_DATA_DIR" && echo "OK" || echo "FAIL: create directory first"
```

---

## Task 07 — Создать `docker-compose.yml`

### Steps

Создать `vaultwarden/docker-compose.yml`:

**docker-compose.yml**

```yaml
services:
  vaultwarden:
    image: vaultwarden/server:1.32.5
    container_name: vaultwarden
    restart: unless-stopped
    env_file:
      - ../.env
    environment:
      DOMAIN: ${VW_PUBLIC_URL}
      SIGNUPS_ALLOWED: ${VW_SIGNUPS_ALLOWED:-false}
      ADMIN_TOKEN: ${VW_ADMIN_TOKEN}
      TZ: ${TZ:-UTC}
    volumes:
      - ${VW_DATA_DIR}:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/alive"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  cloudflared:
    image: cloudflare/cloudflared:2024.1.5
    container_name: cloudflared
    restart: unless-stopped
    env_file:
      - ../.env
    depends_on:
      vaultwarden:
        condition: service_healthy
    command: tunnel --no-autoupdate run
    environment:
      TUNNEL_TOKEN: ${VW_CF_TUNNEL_TOKEN}

  # Утилитарный контейнер для диагностики
  tester:
    image: curlimages/curl:8.5.0
    container_name: vw-tester
    profiles: ["debug"]
    entrypoint: ["sleep", "infinity"]
```

### Manual test

- Проверить, что compose файл валиден:

```bash
docker compose config
```

Команда должна вывести итоговую конфигурацию без ошибок.

---

## Task 08 — Запустить стек и проверить базовую доступность

### Steps

1. Перейти в директорию проекта и запустить:

```bash
cd vaultwarden
docker compose up -d
```

2. Посмотреть статусы:

```bash
docker compose ps
```

3. Посмотреть логи cloudflared:

```bash
docker compose logs --no-log-prefix --tail=50 cloudflared
```

Должно быть сообщение о подключении к туннелю.

### Manual test

1. Локальный healthcheck (только с хоста, если порт проброшен для отладки):

```bash
docker compose exec vaultwarden curl -s http://localhost/alive
```

2. Внешняя проверка через Cloudflare URL:

```bash
curl -i https://vault.yourdomain.com/alive
```

Ожидается `200`.

3. Открыть `https://vault.yourdomain.com` в браузере — должна быть страница Vaultwarden (login).

---

## Task 09 — Создать первого пользователя и закрыть регистрации

### Steps

1. Сейчас `SIGNUPS_ALLOWED=true` — это только для первого входа.
2. Открыть `https://vault.yourdomain.com` и создать аккаунт.
3. После создания аккаунта отключить регистрации:
   - в `.env` поставить `SIGNUPS_ALLOWED=false`
   - перезапустить сервис:

```bash
docker compose up -d vaultwarden
```

### Manual test

- В браузере «Create account» больше не должен работать.
- Убедиться, что текущий пользователь продолжает логиниться.

---

## Task 10 — Проверить WebSocket синхронизацию

### Steps

1. Зайти в web vault в одном браузере.
2. Открыть в другом браузере/устройстве.
3. Добавить/изменить запись в одном.

### Manual test

- Изменение должно появляться почти сразу без ручного refresh.
- Проверить endpoint:

```bash
curl -i https://vault.yourdomain.com/notifications/hub
```

Ожидаемо `400` или `426` (WebSocket upgrade required), но **не** `404`.

---

## Task 11 — Подключить Bitwarden клиенты

### Steps

1. В Bitwarden клиенте (desktop/mobile/browser extension) выбрать **Self-hosted**.
2. Указать:
   - Server URL: `https://vault.yourdomain.com`
3. Логин.

### Manual test

- Создать item на одном устройстве → sync на другом → item появился.
- Проверить, что вложения загружаются/скачиваются (если используешь).

---

## Task 12 — Настроить безопасность

### Steps

1. Убедиться, что `ADMIN_TOKEN` — длинная случайная строка.
2. **После завершения настройки** отключить админку:
   - Убрать или закомментировать `ADMIN_TOKEN` в `.env`
   - Перезапустить:

```bash
docker compose up -d vaultwarden
```

3. (Опционально) В Cloudflare Zero Trust можно добавить дополнительную защиту:
   - **Access → Applications** → добавить приложение для `vault.yourdomain.com/admin`
   - Настроить политику (например, только определённые email).

### Manual test

- `https://vault.yourdomain.com/admin` не должен открываться (404 или redirect).

---

## Task 13 — Настроить бэкапы

### Steps

Минимальный бэкап — регулярное копирование данных из `${VW_DATA_DIR}`:

1. Создать скрипт `backup.sh` в директории `vaultwarden/`:

```bash
#!/bin/bash
set -e

# Загрузить переменные из корневого .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a; source "${SCRIPT_DIR}/../.env"; set +a

BACKUP_DIR="/path/to/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Проверить что VW_DATA_DIR задан
if [ -z "${VW_DATA_DIR}" ]; then
  echo "Error: VW_DATA_DIR not set in .env"
  exit 1
fi

# Создать архив с датой
tar -czf "${BACKUP_DIR}/vaultwarden_${DATE}.tar.gz" -C "$(dirname "${VW_DATA_DIR}")" "$(basename "${VW_DATA_DIR}")"

# Удалить бэкапы старше 30 дней
find "${BACKUP_DIR}" -name "vaultwarden_*.tar.gz" -mtime +30 -delete

echo "Backup completed: vaultwarden_${DATE}.tar.gz"
```

2. Сделать скрипт исполняемым:

```bash
chmod +x backup.sh
```

3. Добавить в crontab (ежедневно в 3:00):

```bash
crontab -e
# Добавить строку:
0 3 * * * /path/to/bedroom-server/vaultwarden/backup.sh >> /var/log/vaultwarden-backup.log 2>&1
```

4. (Рекомендуется) Настроить копирование в облако через rclone:

```bash
# После создания локального бэкапа
rclone copy "${BACKUP_DIR}/vaultwarden_${DATE}.tar.gz" remote:vaultwarden-backups/
```

### Manual test

- Запустить `./backup.sh` вручную — должен создаться `.tar.gz` в папке бэкапов.
- Проверить восстановление:
  1. `docker compose down`
  2. Переименовать `${VW_DATA_DIR}` в `${VW_DATA_DIR}.old`
  3. Создать новую директорию и распаковать бэкап
  4. `docker compose up -d`
  5. Данные на месте.

---

## Task 14 — Экстренный доступ (emergency access)

### Steps

1. Регулярно экспортировать vault:
   - Web vault → Tools → Export vault
   - Формат: **Encrypted JSON** (защищён паролем)
   - Сохранить в безопасное место (offline USB, encrypted cloud).

2. Создать «emergency sheet» с критичными credentials:
   - Пароль от email
   - Master password hint
   - 2FA recovery codes

3. Хранить отдельно от основного бэкапа.

### Manual test

- Попробовать импортировать encrypted export в чистый Bitwarden/Vaultwarden.

---

## Task 15 — Диагностика (troubleshooting)

### Логи сервисов

```bash
docker compose logs --tail=100 vaultwarden
docker compose logs --tail=100 cloudflared
```

### Проверка сети внутри compose

```bash
docker compose --profile debug up -d tester

docker compose exec tester curl -i http://vaultwarden/alive
docker compose exec tester curl -i http://vaultwarden:80/
```

### Статус туннеля в Cloudflare

- Zero Trust dashboard → Tunnels → выбрать туннель → статус **Healthy**.

### Частые проблемы

| Симптом               | Возможная причина    | Решение                                 |
| --------------------- | -------------------- | --------------------------------------- |
| 502 Bad Gateway       | Vaultwarden не готов | Проверить healthcheck, дождаться старта |
| Tunnel disconnected   | Неверный токен       | Проверить `CF_TUNNEL_TOKEN` в `.env`    |
| WebSocket не работает | Старая версия VW     | Убедиться что версия ≥1.29              |
| DNS не резолвится     | NS ещё не обновились | Подождать, проверить `dig NS domain`    |

---

## Обновление Vaultwarden

При выходе новой версии:

1. Проверить release notes: https://github.com/dani-garcia/vaultwarden/releases
2. Сделать бэкап данных (`./backup.sh`).
3. Обновить версию в `docker-compose.yml`:

```yaml
image: vaultwarden/server:1.33.0 # новая версия
```

4. Применить:

```bash
docker compose pull vaultwarden
docker compose up -d vaultwarden
```

5. Проверить логи и доступность.

---

## Итоговая структура проекта

```
bedroom-server/
├── .env.example             # шаблон для всех сервисов (в репозитории)
├── .env                     # секреты (не коммитить!)
└── vaultwarden/
    ├── docker-compose.yml
    └── backup.sh

# Данные хранятся отдельно (путь из VW_DATA_DIR):
/var/lib/vaultwarden/        # или другой путь
├── db.sqlite3
├── rsa_key.pem
├── attachments/
└── ...
```

### Почему данные вне проекта?

- **Безопасность** — случайно не закоммитишь базу паролей
- **Гибкость** — данные можно разместить на отдельном диске/разделе
- **Бэкапы** — проще настроить отдельный backup policy для данных
