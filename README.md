# Тестовое приложение для дипломного проекта

Статическая страница на nginx. Собственный Dockerfile использует
`nginx:1.30.6-alpine`. Контейнер работает от пользователя nginx на порту 8080.
В Kubernetes внешний HTTP-доступ на порту 80 будет настроен через Ingress.

| Путь | Назначение |
| --- | --- |
| `/` | Страница дипломного проекта |
| `/healthz` | Проверка доступности для Kubernetes |
| `/version.json` | Версия, записанная при сборке |

## Сборка и проверка

```bash
docker build --build-arg APP_VERSION=dev -t diploma-app:dev .
docker run --rm diploma-app:dev nginx -t
docker run -d --name diploma-test -p 127.0.0.1:8080:8080 diploma-app:dev
bash scripts/smoke-test.sh http://127.0.0.1:8080 dev
docker rm -f diploma-test
```

## GitHub Actions

Workflow `.github/workflows/build.yml` собирает образ для linux/amd64,
проверяет конфигурацию nginx, главную страницу, health endpoint, версию и 404.
При push в любую ветку или создании тега проверенный образ отправляется
в Yandex Container Registry с тегом `sha-<полный SHA коммита>`.
Для Git-тегов (например `v1.0.0`) добавляется одноимённый тег образа;
Git-тег должен соответствовать формату Docker-тега.
Pull request запускает сборку и тестирование без публикации.
Можно также запустить workflow вручную.

Настройки репозитория: Settings → Secrets and variables → Actions.

| Вид | Имя | Значение |
| --- | --- | --- |
| Repository variable | `YC_REGISTRY_ID` | ID реестра из Terraform |
| Repository secret | `YC_SA_JSON_CREDENTIALS` | JSON авторизованного ключа аккаунта diploma-app-ci |

Сервисный аккаунт создаётся Terraform bootstrap-конфигурацией инфраструктурного
репозитория. Ему назначается роль `container-registry.images.pusher` на каталог.
Авторизованный ключ создаётся локально и хранится в Actions secret.

Автоматический деплой по тегу будет добавлен после настройки Kubernetes-манифестов
и отдельного доступа CI к namespace приложения. Текущий workflow выполняет CI
и публикацию образа; стадия CD ещё не настроена.
