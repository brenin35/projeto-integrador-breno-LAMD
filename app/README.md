# Caronascar — App do Cliente (Flutter)

App móvel do **passageiro** (Sprint 3). Flutter + Provider, consome o backend REST e recebe
atualizações de estado em **tempo real via WebSocket** (ponte MOM → WS).

> 📐 Arquitetura (diagrama de camadas): [../docs/sprint3-arquitetura-app.md](../docs/sprint3-arquitetura-app.md)

## 1. Suba o backend

Na raiz do projeto:

```bash
docker compose up -d          # RabbitMQ
   cd backend
npm run dev                    # API REST + gateway WebSocket (porta 3000)
npm run worker                 # (opcional) consumidor que simula notificações
```

> Se ainda não rodou as migrações: `npm run db:migrate`.

## 2. Rode o app no emulador Android `Pixel_9_Pro`

```bash
cd app
flutter pub get

# inicia o emulador (AVD chamado Pixel_9_Pro)
flutter emulators --launch Pixel_9_Pro

# aguarde o Android abrir e rode apontando para o backend da máquina host.
# No emulador Android, o "localhost" da sua máquina é 10.0.2.2:
flutter run --dart-define=HOST=10.0.2.2
```

Dicas:
- Listar AVDs disponíveis: `flutter emulators` · dispositivos prontos: `flutter devices`.
- Se houver mais de um device conectado, fixe o alvo: `flutter run -d emulator-5554 --dart-define=HOST=10.0.2.2`.
- Em **Linux desktop** (sem emulador) use o padrão: `flutter run -d linux` (host `localhost`, sem `--dart-define`).
- O `usesCleartextTraffic` já está habilitado no `AndroidManifest.xml` para permitir `http://10.0.2.2`.

## 3. Fluxo para demonstrar a atualização em tempo real

1. No app: **cadastre/login** como passageiro → **Viagens** → abra uma viagem → **Solicitar vaga**.
2. A solicitação aparece em **Minhas solicitações** como **Pendente**.
3. No backend (Swagger `http://localhost:3000/docs`, autenticado como o **motorista** dono da
   viagem): `PUT /seat-requests/{id}` com `{"status":"accepted"}`.
4. ➡️ Sem tocar no app, o status muda para **Aceita** e aparece um aviso — empurrado por WebSocket.

## Estrutura (`lib/`)

```
config.dart            # endereço do backend (REST + WS)
models/                # User, Trip, SeatRequest (fromJson)
services/              # ApiClient (REST), Auth/Trip/SeatRequest services, RealtimeService (WS)
state/                 # AuthProvider, TripsProvider, MyRequestsProvider (ChangeNotifier)
screens/               # login, home_shell, trips, trip_details, my_requests
widgets/               # TripCard, SeatRequestCard, StatusChip
utils/                 # formatação de data
```
