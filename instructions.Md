# Nexoraa CleanSoft — Getting Started

This guide explains how to prepare and run the complete Nexoraa CleanSoft monorepo for local development. It is intended for new developers working on the NestJS API gateway, Flutter web application, Flutter mobile application, shared packages, and local Docker services.

All paths in this document are relative to the repository root unless an absolute path is explicitly required.

## Project Overview

Nexoraa CleanSoft is an enterprise multi-tenant ERP monorepo. The repository currently contains:

- A NestJS API gateway and backend service foundations.
- A Flutter web application.
- A Flutter Android/iOS mobile application.
- Shared TypeScript packages.
- MongoDB and Redis development containers.
- Terraform, Helm, deployment, logging, monitoring, and security foundations.
- ERP planning, architecture, security, testing, and implementation documents.

### Command location

No command is required for this section. When this guide says **Repository Root**, it means the folder containing:

```text
package.json
pnpm-workspace.yaml
turbo.json
docker-compose.yml
apps/
packages/
```

On the current Windows workspace, the repository root is:

```text
D:\flutter\nexoraa-cleansoft
```

### Expected result

After completing this guide, MongoDB and Redis should be running in Docker, the API gateway should answer at `http://localhost:3000/api/v1/health`, Flutter web should run in Chrome, and Flutter mobile should run on an Android emulator.

### Common errors

- **A command cannot find `package.json` or `pubspec.yaml`:** The command was run from the wrong folder. Use the command-location note provided for that command.
- **A port is already in use:** Stop the existing process or change the relevant development port in the appropriate `.env` file.
- **A tool is not recognized:** Install the prerequisite and restart the terminal so the updated `PATH` is loaded.

## Monorepo Structure

```text
nexoraa-cleansoft/
├── .github/                     GitHub Actions and repository automation
├── apps/                        Deployable backend and Flutter applications
│   ├── api-gateway/             NestJS HTTP API entry point
│   ├── auth-service/            Authentication service foundation
│   ├── tenant-service/          Tenant service foundation
│   ├── branch-service/          Branch service foundation
│   ├── user-service/            User and authorization service foundation
│   ├── customer-service/        Customer service foundation
│   ├── service-service/         Service-catalog foundation
│   ├── order-service/           Order service foundation
│   ├── payment-service/         Payment service foundation
│   ├── expense-service/         Expense service foundation
│   ├── notification-service/    Notification service foundation
│   ├── scheduler-service/       Background-job service foundation
│   ├── report-service/          Reporting service foundation
│   ├── audit-service/           Audit service foundation
│   ├── search-service/          Search service foundation
│   ├── web-frontend/            Flutter web application
│   └── mobile-app/              Flutter Android/iOS application
├── packages/                    Reusable TypeScript workspace packages
│   ├── common/                  Common infrastructure primitives
│   ├── config/                  Shared configuration primitives
│   ├── constants/               Shared constants
│   ├── database/                Shared database foundations
│   ├── logger/                  Shared logging foundations
│   ├── shared/                  Shared cross-application contracts
│   ├── types/                   Shared TypeScript types
│   ├── ui/                      Shared UI foundations
│   └── utils/                   Shared utilities
├── docker/                      Docker support files and templates
├── docs/                        Developer and operational documentation
├── ERP-PLANNING/                Product, architecture, and phase planning
├── infra/                       Terraform, Helm, deployment, and operations
├── scripts/                     Repository verification and utility scripts
├── docker-compose.yml           Local MongoDB and Redis services
├── package.json                 Root pnpm/Turbo commands
├── pnpm-workspace.yaml          Workspace package definitions
└── turbo.json                   Monorepo task orchestration
```

### Command location

Run directory-inspection commands from **Repository Root**:

```powershell
cd D:\flutter\nexoraa-cleansoft
Get-ChildItem
```

### Expected output

The output should include `apps`, `packages`, `docs`, `ERP-PLANNING`, `infra`, `package.json`, `pnpm-workspace.yaml`, and `docker-compose.yml`.

### Common errors

- **The path does not exist:** Clone the repository or replace the example absolute path with the location of your checkout.
- **Some hidden files are not shown:** Use `Get-ChildItem -Force` when `.github`, `.env`, or other hidden files must be inspected.
- **Generated folders appear:** Folders such as `node_modules`, `.dart_tool`, `dist`, and `build` are local build artifacts and are intentionally excluded from the conceptual tree.

## Prerequisites

Install the following tools before setting up the repository.

| Tool | Required or recommended version | Purpose |
|---|---|---|
| Git | Current supported release | Clone and manage the repository |
| Node.js | `22.13.0` or newer Node.js 22 release | NestJS, pnpm, Turbo, and scripts |
| pnpm | `10.13.1` recommended; `10.x` supported | Root workspace package manager |
| npm | Included with Node.js | Independent API-gateway commands requested by this repository |
| Flutter SDK | Stable release compatible with Flutter `3.38+` | Flutter web and mobile development |
| Dart SDK | Bundled with Flutter; Dart `3.10+` recommended | Flutter compilation and analysis |
| Android Studio | Current stable release | Android SDK, emulator, AVD, and mobile tooling |
| Android SDK | Installed through Android Studio | Android compilation and emulation |
| Java | JDK 17 compatible with the Android project | Android Gradle builds |
| Docker Desktop | Current supported release with Compose v2 | MongoDB and Redis containers |

### Command location

The following version commands may be run from **any folder**:

```powershell
git --version
node --version
npm --version
pnpm --version
flutter --version
dart --version
docker --version
docker compose version
java -version
```

Run the Flutter environment diagnostic from **any folder**:

```powershell
flutter doctor
```

### Expected output

- `node --version` reports Node.js `v22.13.0` or newer within the supported Node.js 22 range.
- `pnpm --version` reports pnpm `10.x`, preferably `10.13.1`.
- `flutter doctor` shows Flutter installed and reports the state of Android, Chrome, and IDE tooling.
- `docker compose version` reports Docker Compose v2.
- `java -version` reports a JDK compatible with Java 17.

### Common errors

- **`pnpm` is not recognized:** Enable Corepack with `corepack enable`, then activate the repository version with `corepack prepare pnpm@10.13.1 --activate`. Run these from any folder in an administrator terminal only if the local installation requires elevation.
- **Flutter is not recognized:** Add the Flutter SDK `bin` directory to `PATH`, close all terminals, and open a new terminal.
- **Android toolchain is missing:** Open Android Studio, install the Android SDK components described under Android Emulator Setup, then run `flutter doctor` again.
- **Android licenses are not accepted:** Run `flutter doctor --android-licenses` from any folder and review each license.
- **Docker cannot connect to its daemon:** Start Docker Desktop and wait until it reports that the engine is running.
- **Wrong Java version:** Configure Android Studio to use its bundled JDK or set `JAVA_HOME` to a compatible JDK 17 installation.

## Initial Project Setup

Use pnpm from the repository root to install all JavaScript workspace dependencies.

### Command location

Folder: **Repository Root**

```powershell
cd D:\flutter\nexoraa-cleansoft
pnpm install
```

Then fetch Flutter dependencies independently for each Flutter application.

Folder: `apps/web-frontend`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\web-frontend
flutter pub get
```

Folder: `apps/mobile-app`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\mobile-app
flutter pub get
```

### Expected output

- `pnpm install` discovers packages under `apps/*` and `packages/*`, resolves dependencies, and finishes without an error.
- Each `flutter pub get` resolves the application packages and prints a successful dependency-resolution message.
- Local generated folders such as `node_modules` and `.dart_tool` are created.

### Common errors

- **Unsupported Node.js version:** Install the supported Node.js 22 release and reopen the terminal.
- **pnpm store or lock conflict:** Confirm no other install is running. Retry `pnpm install`; do not delete lockfiles unless the team has approved dependency regeneration.
- **Package download or certificate failure:** Check the corporate proxy, VPN, registry configuration, and trusted certificates.
- **Flutter package resolution fails:** Run `flutter doctor`, confirm internet access to `pub.dev`, and verify that the Flutter/Dart versions satisfy `pubspec.yaml` and `pubspec.lock`.
- **Access denied on generated folders:** Close editors/processes holding the files and ensure the repository is in a user-writable location.

## Environment Configuration

The monorepo uses separate environment files for root Docker services, the API gateway, Flutter web, and Flutter mobile. Never commit credentials, tokens, private keys, or production values.

### Root Docker environment

Command location: **Repository Root**

```powershell
cd D:\flutter\nexoraa-cleansoft
Copy-Item .env.example .env
```

Recommended local values:

```dotenv
NODE_ENV=development
MONGODB_URI=mongodb://localhost:27017
MONGODB_DATABASE=nexoraa_cleansoft
MONGODB_PORT=27017
REDIS_URL=redis://localhost:6379
REDIS_PORT=6379
LOG_LEVEL=debug
```

### API gateway environment

Command location: `apps/api-gateway`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\api-gateway
Copy-Item .env.example .env
```

Expected local values:

```dotenv
APP_NAME=Nexoraa CleanSoft
NODE_ENV=development
HOST=0.0.0.0
PORT=3000
API_PREFIX=api
API_VERSION=v1
```

### Flutter web environment

Command location: `apps/web-frontend`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\web-frontend
Copy-Item .env.example .env
```

Recommended local values:

```dotenv
APP_NAME=Nexoraa CleanSoft
APP_ENV=development
API_BASE_URL=http://localhost:3000/api/v1
```

### Flutter mobile environment

The Android emulator reaches services on the Windows host through `10.0.2.2`, not `localhost`.

Command location: `apps/mobile-app`

Create `apps/mobile-app/.env` with:

```dotenv
APP_NAME=Nexoraa CleanSoft
APP_ENV=development
API_BASE_URL=http://10.0.2.2:3000/api/v1
```

### Expected output

Each application folder should contain an untracked `.env` file. The API gateway should start without a missing-environment-variable error. Docker Compose should resolve the MongoDB and Redis port variables.

### Common errors

- **`Copy-Item` says the destination exists:** Inspect the existing local `.env` and update only the required development values.
- **API gateway reports a required variable:** Compare `apps/api-gateway/.env` with `apps/api-gateway/.env.example`.
- **Flutter reports `.env` as a missing asset:** Confirm `.env` exists in the same folder as that application's `pubspec.yaml`, then run `flutter pub get`.
- **Mobile app cannot reach `localhost:3000`:** Use `http://10.0.2.2:3000` for the standard Android emulator. A physical device requires a reachable host LAN address and appropriate firewall configuration.
- **A secret was committed:** Stop using it, rotate it through the approved secret-management process, and remove it from Git history using the team's security procedure.

## Backend Setup

The currently runnable NestJS backend application is the API gateway.

### Command location

Folder: `apps/api-gateway`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\api-gateway
```

Install the API gateway dependencies independently when required:

```powershell
npm install
```

Start development mode:

```powershell
npm run start:dev
```

Build production output:

```powershell
npm run build
```

Run tests:

```powershell
npm test
```

Verify the health endpoint from a second terminal. This verification command may be run from **any folder**:

```powershell
Invoke-RestMethod http://localhost:3000/api/v1/health
```

Expected health response:

```json
{
  "status": "ok",
  "service": "api-gateway",
  "environment": "development",
  "message": "NestJS Foundation Ready"
}
```

### Expected output

- `npm install` finishes without changing declared dependency versions and prepares local `node_modules`.
- `npm run start:dev` starts NestJS in watch mode and logs that the API gateway is listening on port `3000`.
- `npm run build` creates or refreshes `apps/api-gateway/dist`.
- `npm test` exits successfully; while no tests exist, the configured command may report that no tests were found and exit with code `0`.
- The health request returns HTTP `200` and the JSON shown above.

### Common errors

- **`EADDRINUSE` on port 3000:** Stop the process using port `3000` or choose another unused `PORT` in `apps/api-gateway/.env`.
- **Missing environment variable:** Recreate `apps/api-gateway/.env` from `.env.example`.
- **`npm` cannot resolve packages:** Confirm Node.js 22 and network/registry settings, then retry from `apps/api-gateway`.
- **Health endpoint returns 404:** Confirm the URL includes both `/api` and `/v1`, and verify `API_PREFIX=api` and `API_VERSION=v1`.
- **TypeScript compilation fails:** Run `npm run typecheck` from `apps/api-gateway`, review the first error, and do not bypass strict compiler rules.
- **Formatting or lint failures:** Run `npm run format` and `npm run lint` from `apps/api-gateway`, then review the resulting changes.
- **Mixed package-manager state:** The monorepo uses pnpm at root while the API gateway also has an npm lockfile. Do not alternate package managers in the same folder unless the team intends to update dependency state.

## Flutter Web Setup

The Flutter web application is located at `apps/web-frontend`.

### Command location

Folder: `apps/web-frontend`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\web-frontend
```

Fetch dependencies:

```powershell
flutter pub get
```

Start the application in Chrome:

```powershell
flutter run -d chrome
```

Build production web assets:

```powershell
flutter build web
```

### Expected output

- `flutter pub get` reports that dependencies were resolved.
- `flutter run -d chrome` starts a Flutter development session and opens Chrome.
- `flutter build web` creates production assets under `apps/web-frontend/build/web`.
- The browser displays the Nexoraa CleanSoft Flutter web foundation.

### Common errors

- **Chrome is not available:** Install Google Chrome and run `flutter devices` from `apps/web-frontend` to confirm the `chrome` device appears.
- **Web support is disabled:** Run `flutter config --enable-web` from any folder, then restart the terminal and check `flutter devices`.
- **`.env` cannot be loaded:** Create `apps/web-frontend/.env` from `.env.example` and rerun `flutter pub get`.
- **Backend requests fail:** Start the API gateway, verify its health endpoint, and ensure `API_BASE_URL=http://localhost:3000/api/v1`.
- **CORS error in the browser:** Confirm the API gateway is running with CORS enabled and that the browser is calling the expected local URL.
- **Port conflict:** Use `flutter run -d chrome --web-port 8081` from `apps/web-frontend`, substituting an available port.

## Flutter Mobile Setup

Android Studio is required for the supported beginner workflow because it installs and manages the Android SDK, platform tools, emulator, and Android Virtual Devices.

### Android Studio installation requirement

1. Install the current stable Android Studio.
2. During installation, enable the Android SDK, Android SDK Platform, Android Virtual Device, and Android Emulator options.
3. Start Android Studio once so it can complete component installation.
4. Install the Flutter plugin from **Settings > Plugins** if Flutter editing support is required.

Command location for diagnostics: **any folder**

```powershell
flutter doctor
```

Expected output: Flutter detects Android Studio and reports the Android toolchain. Resolve any item marked with an error before building the mobile application.

### Android SDK setup

In Android Studio:

1. Open **More Actions > SDK Manager**, or **Settings > Languages & Frameworks > Android SDK**.
2. Under **SDK Platforms**, install a current Android platform compatible with the project.
3. Under **SDK Tools**, install:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools
4. Apply the changes and wait for downloads to finish.

Typical Windows Android SDK location:

```text
%LOCALAPPDATA%\Android\Sdk
```

If Flutter cannot locate the SDK, run from **any folder**:

```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
flutter doctor
```

### Mobile application commands

Command location: `apps/mobile-app`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\mobile-app
flutter pub get
flutter analyze
flutter test
```

Run on the currently selected device:

```powershell
flutter run
```

Run on the standard first Android emulator device ID:

```powershell
flutter run -d emulator-5554
```

Clean generated Flutter/Android build output when troubleshooting:

```powershell
flutter clean
flutter pub get
```

### Expected output

- `flutter doctor` recognizes Flutter, Android Studio, Android SDK, and an accepted Android license state.
- `flutter pub get` resolves the mobile dependencies.
- `flutter analyze` completes without analyzer errors.
- `flutter test` completes successfully; an empty test directory may report that no tests were found until tests are added.
- `flutter run` builds, installs, and starts the application on the selected emulator or device.
- The emulator displays the Nexoraa CleanSoft Flutter mobile foundation.

### Common errors

- **Android toolchain missing:** Complete Android SDK setup in Android Studio and rerun `flutter doctor`.
- **Licenses not accepted:** Run `flutter doctor --android-licenses` from any folder.
- **No device is available:** Create and start an AVD, then run `flutter devices`.
- **Device ID is not `emulator-5554`:** Use the actual ID printed by `flutter devices`.
- **Gradle or SDK download fails:** Confirm network/proxy access, Android SDK paths, and available disk space.
- **`.env` asset is missing:** Create `apps/mobile-app/.env` and rerun `flutter pub get`.
- **The emulator cannot reach the backend:** Use `10.0.2.2` instead of `localhost` in the mobile API URL and allow the backend through the host firewall.
- **Stale Android build failure:** From `apps/mobile-app`, run `flutter clean`, then `flutter pub get`, and try again.

## Android Emulator Setup

### Create an Android Virtual Device

In Android Studio:

1. Open **More Actions > Virtual Device Manager**, or **Tools > Device Manager**.
2. Select **Create Device**.
3. Choose a supported phone profile, such as a recent Pixel device.
4. Select and download a current stable system image appropriate for the host CPU.
5. Name the AVD clearly, for example `Nexoraa_API_35`.
6. Finish creation and leave graphics settings on a hardware-accelerated option when supported.

### Start the emulator using Android Studio

1. Open **Tools > Device Manager**.
2. Find the created AVD.
3. Select the **Run** button.
4. Wait until the Android home screen is fully loaded.

Command location for verification: `apps/mobile-app`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\mobile-app
flutter devices
```

Expected output: A device similar to `emulator-5554` appears as an Android device.

### Start the emulator using Flutter commands

Command location: `apps/mobile-app`

List configured emulators:

```powershell
flutter emulators
```

Launch an emulator using the ID displayed by the previous command:

```powershell
flutter emulators --launch <emulator-id>
```

Example:

```powershell
flutter emulators --launch Nexoraa_API_35
```

Confirm the running device:

```powershell
flutter devices
```

### Start the emulator using Android SDK command-line tools

The Android SDK emulator directory must be available in `PATH`. Its typical Windows location is:

```text
%LOCALAPPDATA%\Android\Sdk\emulator
```

The platform-tools directory should also be available:

```text
%LOCALAPPDATA%\Android\Sdk\platform-tools
```

Command location: **any folder**

List Android AVD names:

```powershell
emulator -list-avds
```

Launch the example AVD:

```powershell
emulator -avd Nexoraa_API_35
```

After the emulator starts, run from `apps/mobile-app`:

```powershell
flutter devices
flutter run -d emulator-5554
```

### Expected output

- `flutter emulators` lists at least one configured AVD.
- The launch command opens an emulator window.
- `flutter devices` lists the running emulator with an ID such as `emulator-5554`.
- `flutter run -d emulator-5554` builds and launches the mobile application.

### Common errors

- **No emulators are listed:** Create an AVD in Android Studio Device Manager.
- **`emulator` is not recognized:** Add `%LOCALAPPDATA%\Android\Sdk\emulator` to the user `PATH` and reopen the terminal.
- **AVD immediately closes:** Enable CPU virtualization in BIOS/UEFI, install the recommended emulator hypervisor support, and check Android Studio's emulator logs.
- **Insufficient disk space:** Remove unused AVDs/system images from Device Manager and retry.
- **Device stays offline:** Close the emulator, use Device Manager **Cold Boot Now**, or use **Wipe Data** only when local emulator data may be discarded.
- **`emulator-5554` does not exist:** Run `flutter devices` and substitute the actual running device ID.

## Docker Setup

Docker Compose provides local MongoDB 8 and Redis 8 services.

### Command location

Folder: **Repository Root**

```powershell
cd D:\flutter\nexoraa-cleansoft
```

Start containers:

```powershell
docker compose up -d
```

Inspect container state:

```powershell
docker compose ps
```

Inspect service logs:

```powershell
docker compose logs mongodb
docker compose logs redis
```

Stop and remove the running containers while preserving named volumes:

```powershell
docker compose down
```

### Expected output

- `docker compose up -d` creates or starts `mongodb` and `redis`.
- `docker compose ps` shows both services running.
- MongoDB is available on the configured `MONGODB_PORT`, normally `27017`.
- Redis is available on the configured `REDIS_PORT`, normally `6379`.
- `docker compose down` stops and removes the containers and network while retaining named data volumes.

### Common errors

- **Docker daemon is unavailable:** Start Docker Desktop and wait for the engine to become ready.
- **Port 27017 or 6379 is already in use:** Stop the conflicting local service/container or change the corresponding root `.env` port.
- **Compose reports an empty port variable:** Create the root `.env` from `.env.example`.
- **Container repeatedly restarts:** Run `docker compose logs mongodb` or `docker compose logs redis` from Repository Root and inspect the first startup error.
- **Old data causes local development problems:** Do not delete volumes automatically. Confirm that local data may be discarded before using `docker compose down -v`.
- **Image download fails:** Check registry access, VPN/proxy settings, Docker authentication, and available disk space.

## Common Development Commands

### Repository root commands

Command location: **Repository Root**

```powershell
cd D:\flutter\nexoraa-cleansoft
pnpm install
pnpm dev
pnpm lint
pnpm test
pnpm build
pnpm verify
docker compose up -d
docker compose down
```

Expected results:

- `pnpm install` installs workspace dependencies.
- `pnpm dev` asks Turbo to start workspace packages that currently expose a `dev` script. The API gateway uses `npm run start:dev` separately.
- `pnpm lint`, `pnpm test`, and `pnpm build` execute matching Turbo tasks in participating workspaces.
- `docker compose up -d` starts MongoDB and Redis.
- `docker compose down` stops them.

Common errors:

- **Turbo says no task exists for a package:** That workspace does not yet expose the requested script.
- **Multiple Flutter applications start unexpectedly with `pnpm dev`:** Root development mode is parallel. For controlled startup, use each application's folder-specific command.
- **`pnpm verify` fails after documentation or implementation work:** The original verifier may enforce scaffold-era expectations. Review its reported rule and current project phase before changing files.

### API gateway commands

Command location: `apps/api-gateway`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\api-gateway
npm run start:dev
npm run typecheck
npm run lint
npm run format:check
npm test
npm run build
npm run start:prod
```

Expected results: development watch mode starts, static checks pass, tests exit successfully, `dist` is generated, and production mode runs the compiled application.

Common errors: verify `.env`, Node.js version, installed dependencies, port availability, and the first reported TypeScript/ESLint error.

### Flutter web commands

Command location: `apps/web-frontend`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\web-frontend
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter build web
```

Expected results: dependencies resolve, analysis/tests pass, Chrome opens in development mode, and `build/web` is created.

Common errors: verify Flutter web support, Chrome detection, `.env`, and API gateway/CORS availability.

### Flutter mobile commands

Command location: `apps/mobile-app`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\mobile-app
flutter doctor
flutter devices
flutter emulators
flutter emulators --launch <emulator-id>
flutter pub get
flutter clean
flutter analyze
flutter test
flutter run
flutter run -d emulator-5554
```

Expected results: Flutter reports a valid toolchain/device, dependencies resolve, static checks/tests pass, and the application launches on the selected device.

Common errors: verify Android SDK components/licenses, AVD state, actual device ID, Java version, `.env`, and the emulator-to-host API address.

## Development Workflow

Use the following startup order so dependencies are available before clients attempt to connect.

### 1. Start Docker

Command location: **Repository Root**

```powershell
cd D:\flutter\nexoraa-cleansoft
docker compose up -d
docker compose ps
```

Expected output: MongoDB and Redis are running.

Common error: if a port is occupied, resolve the conflict before starting the backend.

### 2. Start Backend

Open a second terminal.

Command location: `apps/api-gateway`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\api-gateway
npm run start:dev
```

Expected output: NestJS listens on `0.0.0.0:3000`, and `/api/v1/health` returns HTTP `200`.

Common error: if configuration validation fails, repair `apps/api-gateway/.env`.

### 3. Start Flutter Web

Open a third terminal.

Command location: `apps/web-frontend`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\web-frontend
flutter run -d chrome
```

Expected output: Chrome opens the Flutter web application.

Common error: if Chrome is not listed, check `flutter devices` and enable Flutter web support.

### 4. Start Flutter Mobile

Start the AVD in Android Studio Device Manager or from the command line, then open a fourth terminal.

Command location: `apps/mobile-app`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\mobile-app
flutter devices
flutter run -d emulator-5554
```

Expected output: Flutter installs and opens the application on the Android emulator.

Common error: if the listed ID differs, replace `emulator-5554` with the ID from `flutter devices`.

### Shutdown order

Stop each foreground development process with `Ctrl+C`. Then stop Docker from **Repository Root**:

```powershell
cd D:\flutter\nexoraa-cleansoft
docker compose down
```

Expected output: Docker stops the MongoDB and Redis containers without deleting their named volumes.

## Troubleshooting

### Confirm the current folder

Command location: **the terminal where the failing command was run**

```powershell
Get-Location
Get-ChildItem
```

Expected output: the folder contains the required `package.json`, `pubspec.yaml`, or `docker-compose.yml`.

### Check required toolchains

Command location: **any folder**

```powershell
node --version
pnpm --version
npm --version
flutter doctor
docker compose version
java -version
```

Expected output: all commands are recognized and versions match the prerequisites.

### Check backend health

Command location: **any folder**

```powershell
Invoke-RestMethod http://localhost:3000/api/v1/health
```

Expected output: the API gateway health object with status `ok`.

Solutions:

- If connection is refused, start the API gateway.
- If the route is not found, verify the prefix/version environment values.
- If port `3000` is occupied, stop the existing process or change the backend port and client URLs consistently.

### Check Docker services

Command location: **Repository Root**

```powershell
docker compose ps
docker compose logs mongodb
docker compose logs redis
```

Expected output: MongoDB and Redis are running without recurring fatal errors.

Solutions:

- Start Docker Desktop.
- Verify root `.env` ports.
- Resolve port conflicts.
- Check Docker disk allocation and registry access.

### Check Flutter devices

Command location: `apps/mobile-app`

```powershell
flutter doctor
flutter emulators
flutter devices
```

Expected output: the Android toolchain is valid and at least one running emulator/device is listed.

Solutions:

- Install missing Android SDK components.
- Accept licenses with `flutter doctor --android-licenses`.
- Create/start an AVD.
- Cold boot the AVD if it is offline.

### Reset Flutter generated output

Use this only for the affected Flutter application.

Command location: `apps/web-frontend` or `apps/mobile-app`

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
```

Expected output: generated build state is recreated and checks run against a clean Flutter build cache.

### Avoid destructive troubleshooting

- Do not delete MongoDB/Redis volumes unless local data loss has been explicitly accepted.
- Do not delete lockfiles to solve ordinary installation failures.
- Do not commit `.env`, signing keys, certificates, tokens, or credentials.
- Do not disable TypeScript, ESLint, Flutter analyzer, test, or security checks to hide an error.
- Do not run production deployment commands as part of local setup.

## Folder Locations

| Activity | Command folder | Repository-relative path |
|---|---|---|
| Root pnpm/Turbo commands | Repository Root | `.` |
| Docker Compose | Repository Root | `.` |
| NestJS API gateway | API gateway folder | `apps/api-gateway` |
| Flutter web | Web application folder | `apps/web-frontend` |
| Flutter mobile | Mobile application folder | `apps/mobile-app` |
| Backend service foundations | Individual service folder | `apps/*-service` |
| Shared TypeScript packages | Individual package folder | `packages/*` |
| General documentation | Documentation folder | `docs` |
| ERP planning and phase prompts | Planning folder | `ERP-PLANNING` |
| Terraform | Terraform folder | `infra/terraform` |
| Helm | Helm folder | `infra/helm` |
| Repository scripts | Scripts folder | `scripts` |

### Command location

Run this from **Repository Root** to confirm the major locations:

```powershell
cd D:\flutter\nexoraa-cleansoft
Get-ChildItem apps
Get-ChildItem packages
Get-ChildItem infra
```

### Expected output

The commands list the application, shared-package, and infrastructure folders shown in the monorepo tree.

### Common errors

- **A documented folder is missing:** Confirm the correct branch and repository checkout.
- **A service has no runnable script:** Many service directories are foundations and will become runnable in their implementation phase.
- **A generated directory is mistaken for source:** Treat `dist`, `build`, `.dart_tool`, `.gradle`, and `node_modules` as generated local state.

## Quick Start

Complete environment setup before using this sequence.

### Terminal 1 — local infrastructure

Command location: **Repository Root**

```powershell
cd D:\flutter\nexoraa-cleansoft
pnpm install
docker compose up -d
docker compose ps
```

Expected output: workspace dependencies are installed and MongoDB/Redis are running.

Common error: create the root `.env` when Compose cannot resolve port variables.

### Terminal 2 — API gateway

Command location: `apps/api-gateway`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\api-gateway
npm install
npm run start:dev
```

Expected output: the API gateway listens on port `3000`.

Common error: copy `.env.example` to `.env` and resolve port `3000` conflicts.

### Terminal 3 — Flutter web

Command location: `apps/web-frontend`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\web-frontend
flutter pub get
flutter run -d chrome
```

Expected output: Chrome opens the Flutter web application.

Common error: install/detect Chrome and create `apps/web-frontend/.env`.

### Terminal 4 — Flutter mobile

Start an AVD in Android Studio first.

Command location: `apps/mobile-app`

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\mobile-app
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Expected output: the application launches on the running Android emulator.

Common error: use the actual device ID from `flutter devices` and use `10.0.2.2` for the emulator's API base URL.

### Final health check

Command location: **any folder**

```powershell
Invoke-RestMethod http://localhost:3000/api/v1/health
```

Expected output:

```text
status      : ok
service     : api-gateway
environment : development
message     : NestJS Foundation Ready
```

The recommended development order is always:

1. Start Docker.
2. Start Backend.
3. Start Flutter Web.
4. Start Flutter Mobile.
