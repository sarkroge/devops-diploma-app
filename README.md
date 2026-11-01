# Тестовое приложение для дипломного проекта

Статическая страница на nginx. Собственный Dockerfile использует
`nginx:1.30.6-alpine`. Контейнер работает от пользователя nginx на порту 8080.
В Kubernetes внешний HTTP-доступ на порту 80 настроен через Traefik Ingress.

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
| Repository variable | `APP_URL` | Публичный HTTP URL приложения из Terraform output web_ip |
| Repository secret | `KUBE_CONFIG` | Содержимое .secrets/kubeconfig-github-deployer из инфраструктурного проекта |

Сервисный аккаунт создаётся Terraform bootstrap-конфигурацией инфраструктурного
репозитория. Ему назначается роль `container-registry.images.pusher` на каталог.
Авторизованный ключ создаётся локально и хранится в Actions secret.

При push Git-тега после успешной сборки и публикации выполняется job deploy.
В Deployment diploma/diploma-app подставляется проверенный образ по digest,
затем workflow ожидает завершения rollout и проверяет публичную страницу,
health endpoint и версию приложения. Например, тег v1.0.1 должен привести
к значению v1.0.1 в /version.json. Деплои выполняются без одновременного
изменения Deployment несколькими job.

Kubernetes ServiceAccount github-deployer имеет права get/list/watch/patch
только на Deployment diploma-app в namespace diploma. Ему не выданы права API
на чтение Secrets или Nodes. RBAC и отдельный kubeconfig создаются скриптом
scripts/create-cd-kubeconfig.py в инфраструктурном проекте. Административный
kubeconfig в GitHub не передаётся.

Перед первым релизом настройте KUBE_CONFIG и APP_URL в GitHub Actions.
Затем создайте новый тег на коммите с обновлённым workflow:

```bash
git switch main
git pull --ff-only
git tag v1.0.1
git push origin v1.0.1
```

Сохраните скриншот workflow с успешными build и deploy, а также страницу
приложения с новой версией. Kubernetes-манифесты и мониторинг хранятся
в инфраструктурном репозитории и устанавливаются отдельно.
