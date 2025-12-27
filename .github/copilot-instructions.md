<!--
Guidance for AI-assisted coding on Open Source Point of Sale (OSPOS).
Keep this file concise — aim to make an AI immediately productive in this repo.
-->

# Copilot / AI agent instructions — Open Source Point of Sale

Short: This is a PHP web application built on CodeIgniter 4 with frontend assets built via `gulp`.

- **Big picture**
  - `app/` contains the application code (models, controllers, views) following CodeIgniter 4 conventions. See [app/Controllers/BaseController.php](app/Controllers/BaseController.php) for request lifecycle helpers.
  - `public/index.php` is the web entry point. Static assets live under `public/` (css, js, images).
  - Third-party libraries are in `vendor/` (installed via Composer). Autoload maps `App\` to `app/` as defined in `composer.json`.
  - Assets pipeline: `package.json` + `gulpfile.js` build frontend bundles; use `npm install` then `npm run build` (or `gulp`).
  - Database and persistence: MySQL/MariaDB. DB configuration is in [app/Config/Database.php](app/Config/Database.php) and can be overridden via `.env`.

- **Why things are structured this way**
  - App follows CodeIgniter 4 framework idioms for routing, controllers, and services to keep framework upgrades tractable.
  - `app/Database/Migrations` is intentionally excluded from classmap; migrations are handled as migration files, not autoloaded classes.
  - `writable/` contains runtime state (cache, logs, uploads) and must be writable with correct permissions on Unix systems.

- **Developer workflows (concrete commands)**
  - Install PHP deps: `composer install`
  - Install JS deps: `npm install`
  - Build assets (dev): `npm run build` or `gulp` (see `package.json` -> `build` script)
  - Run tests (Unix): `./phpunit` (project ships a phpunit wrapper). On Windows use: `vendor\bin\phpunit`.
  - CI/coverage: `phpunit.xml.dist` bootstraps `system/Test/bootstrap.php` and writes coverage into `build/logs/` by default.
  - Run app locally (CodeIgniter): `php spark serve` or use docker compose via `docker-compose.dev.yml`.

- **Project-specific conventions and gotchas**
  - PHP requirement: `>= 8.1` (see README and `composer.json`). Don't propose backporting language features below that.
  - The footer copyright string mentioned in README is legally required to remain unchanged in pages — avoid removing/modifying it.
  - `writable/` directory and subfolders must have proper permissions (Linux: owner and `750` seen in docs); tests and uploads depend on this.
  - Tests assume certain constants and paths are set by `phpunit.xml.dist` (HOMEPATH, CONFIGPATH, PUBLICPATH). Prefer running tests via the repo wrapper or vendor binary.
  - Database tests expect a `tests` DB group — see `tests/README.md` for configuring a test DB or using `.env`.

- **Files to consult for patterns/examples**
  - Routing and app boot: [app/Config/Routes.php](app/Config/Routes.php)
  - App bootstrap/services: [app/Config/App.php](app/Config/App.php) and [app/Config/Services.php](app/Config/Services.php)
  - Controllers usage patterns: [app/Controllers/](app/Controllers/)
  - Views and UI snippets: [app/Views/](app/Views/) and `public/js` for client-side patterns
  - Tests entry and examples: [tests/](tests/) and [phpunit.xml.dist](phpunit.xml.dist)
  - Asset build: `package.json` and `gulpfile.js`

- **Integration points & external systems**
  - Uses MySQL/MariaDB; optional Redis/Predis for caching (see `composer.json` require-dev/dev packages).
  - PDF rendering via `dompdf/dompdf` and sanitization via `ezyang/htmlpurifier`.
  - Optional integrations visible in code/comments: MailChimp, Google reCAPTCHA, SMS gateways.
  - Docker helpers exist: `docker/` and `docker-compose*.yml` for development/test stacks.

- **Style & tooling**
  - Code style and static checks present in `composer.json` (`codeigniter/coding-standard`, `friendsofphp/php-cs-fixer`) — mirror those conventions when changing code layout.
  - Prefer minimal, framework-consistent edits (follow CodeIgniter patterns for Controllers/Models/Services).

- **When editing code, be careful about**
  - Not breaking `public` entrypoint or routing; test manual pages after edits.
  - Preserving migrations and not assuming they will be autoloaded.
  - Keeping user-facing footer/license text intact.

If any of the above is unclear or you want more specifics (CI steps, Docker dev run examples, or test DB details), tell me which area to expand. I'll iterate the file.
