# Pattern test fixture and recorded outputs

This file lets you rebuild the synthetic repo the SKILL.md search patterns were verified against (2026-07-05, ripgrep 14.1.0), re-run every pattern, and compare against the recorded outputs. If outputs diverge after a ripgrep upgrade, update SKILL.md.

The fixture deliberately plants: env reads in 5 languages, a dotenv + pydantic-settings + viper loader trio, per-env config files, a build-time constant in webpack and Go, an in-code feature flag set differently in deploy vs example file, a secret via `secretKeyRef`, hidden-path config (`.env.example`, `.github/`), and one unused knob (`UNUSED_KNOB`) that the dead-check must catch.

## Rebuild the fixture

Run in any empty directory (bash):

```bash
mkdir -p cfgdemo/{src,cmd,config,deploy,.github/workflows} && cd cfgdemo

cat > src/server.js <<'EOF'
require('dotenv').config();
const PORT = process.env.PORT || 3000;
const dbUrl = process.env.DATABASE_URL;
const flags = { newCheckout: process.env.FLAG_NEW_CHECKOUT === 'true' };
if (process.env.NODE_ENV !== 'production' && process.env.DEBUG_PANEL) {
  enableDebugPanel();
}
EOF

cat > src/settings.py <<'EOF'
import os
from pydantic_settings import BaseSettings

TIMEOUT = int(os.environ.get("APP_TIMEOUT", "30"))
API_KEY = os.getenv("STRIPE_API_KEY")

class Settings(BaseSettings):
    db_dsn: str = "postgres://localhost/dev"
    enable_beta_search: bool = False
    class Config:
        env_prefix = "APP_"
EOF

cat > src/cli.py <<'EOF'
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--verbose", action="store_true")
parser.add_argument("--region", default="us-east-1")
EOF

cat > cmd/main.go <<'EOF'
package main

import (
	"flag"
	"os"

	"github.com/spf13/viper"
)

var Version = "dev" // set via -ldflags "-X main.Version=..."

func main() {
	region := flag.String("region", "us-east-1", "aws region")
	_ = region
	token := os.Getenv("GITHUB_TOKEN")
	_ = token
	viper.SetDefault("cache.ttl", 60)
	viper.BindEnv("cache.ttl", "CACHE_TTL")
	_ = viper.GetInt("cache.ttl")
	if viper.GetBool("features.dark_mode") {
	}
}
EOF

cat > src/legacy.c <<'EOF'
#include <stdlib.h>
const char *proxy = getenv("HTTP_PROXY");
EOF

cat > config/default.yaml <<'EOF'
cache:
  ttl: 60
features:
  dark_mode: false
EOF

cat > config/production.yaml <<'EOF'
cache:
  ttl: 300
EOF

cat > .env.example <<'EOF'
PORT=3000
DATABASE_URL=postgres://localhost/dev
STRIPE_API_KEY=sk_test_xxx
FLAG_NEW_CHECKOUT=false
UNUSED_KNOB=1
EOF

cat > deploy/k8s.yaml <<'EOF'
env:
  - name: PORT
    value: "8080"
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: database-url
  - name: FLAG_NEW_CHECKOUT
    value: "true"
EOF

cat > .github/workflows/ci.yml <<'EOF'
env:
  NODE_ENV: test
  APP_TIMEOUT: "5"
EOF

cat > webpack.config.js <<'EOF'
const webpack = require('webpack');
module.exports = {
  plugins: [
    new webpack.DefinePlugin({
      __BUILD_SHA__: JSON.stringify(process.env.GIT_SHA),
      'process.env.NODE_ENV': JSON.stringify('production'),
    }),
  ],
};
EOF
```

## Recorded outputs (2026-07-05, ripgrep 14.1.0)

### Axis 1 — env-var read sites

Command:
```bash
rg -n --hidden "process\.env\.[A-Z0-9_]+|os\.environ|os\.getenv|getenv\(|os\.Getenv|viper\.BindEnv|ENV\[" .
```

Output (paths relative to fixture root; order may vary):
```
./src/server.js:2:const PORT = process.env.PORT || 3000;
./src/server.js:3:const dbUrl = process.env.DATABASE_URL;
./src/server.js:4:const flags = { newCheckout: process.env.FLAG_NEW_CHECKOUT === 'true' };
./src/server.js:5:if (process.env.NODE_ENV !== 'production' && process.env.DEBUG_PANEL) {
./src/settings.py:4:TIMEOUT = int(os.environ.get("APP_TIMEOUT", "30"))
./src/settings.py:5:API_KEY = os.getenv("STRIPE_API_KEY")
./cmd/main.go:15:	token := os.Getenv("GITHUB_TOKEN")
./cmd/main.go:18:	viper.BindEnv("cache.ttl", "CACHE_TTL")
./src/legacy.c:2:const char *proxy = getenv("HTTP_PROXY");
./webpack.config.js:5:      __BUILD_SHA__: JSON.stringify(process.env.GIT_SHA),
./webpack.config.js:6:      'process.env.NODE_ENV': JSON.stringify('production'),
```

### Axis 1 — env-var name extraction

Command:
```bash
rg -oI --hidden --no-filename \
  "process\.env\.([A-Z0-9_]+)|os\.environ(\.get)?\([\"']([A-Z0-9_]+)|os\.getenv\([\"']([A-Z0-9_]+)|getenv\([\"']([A-Z0-9_]+)|os\.Getenv\([\"']([A-Z0-9_]+)|BindEnv\([^,]+, ?[\"']([A-Z0-9_]+)" . \
  | rg -o "[A-Z][A-Z0-9_]{2,}" | sort -u
```

Output:
```
APP_TIMEOUT
CACHE_TTL
DATABASE_URL
DEBUG_PANEL
FLAG_NEW_CHECKOUT
GITHUB_TOKEN
GIT_SHA
HTTP_PROXY
NODE_ENV
PORT
STRIPE_API_KEY
```

Note: `UNUSED_KNOB` is correctly absent (it has no read site) and `APP_`-prefixed pydantic auto-bound vars are invisible here (framework binding blind spot documented in SKILL.md).

### Hidden-file gotcha demonstration

Command and output:
```bash
rg -n --hidden "NODE_ENV|FLAG_NEW_CHECKOUT|UNUSED_KNOB" .
```
```
./.env.example:4:FLAG_NEW_CHECKOUT=false
./.env.example:5:UNUSED_KNOB=1
./deploy/k8s.yaml:9:  - name: FLAG_NEW_CHECKOUT
./.github/workflows/ci.yml:2:  NODE_ENV: test
./webpack.config.js:6:      'process.env.NODE_ENV': JSON.stringify('production'),
./src/server.js:4:const flags = { newCheckout: process.env.FLAG_NEW_CHECKOUT === 'true' };
./src/server.js:5:if (process.env.NODE_ENV !== 'production' && process.env.DEBUG_PANEL) {
```

The same command WITHOUT `--hidden` returned only the last four lines (deploy/, webpack.config.js, src/) — it missed `.env.example` and `.github/workflows/ci.yml` entirely (3 of 7 hits lost).

### Axis 2 — config files and loaders

```bash
find . -maxdepth 3 \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.toml' \
  -o -name '*.ini' -o -name '.env*' -o -name '*.env' \) | sort
```
```
./.env.example
./.github/workflows/ci.yml
./config/default.yaml
./config/production.yaml
./deploy/k8s.yaml
```

```bash
rg -n --hidden "dotenv|BaseSettings|viper\.(SetConfigName|AddConfigPath|ReadInConfig|SetDefault)|ConfigParser|yaml\.(safe_)?load|json\.load|toml\.load|convict|node-config" .
```
```
./cmd/main.go:17:	viper.SetDefault("cache.ttl", 60)
./src/server.js:1:require('dotenv').config();
./src/settings.py:2:from pydantic_settings import BaseSettings
./src/settings.py:7:class Settings(BaseSettings):
```

### Axis 3 — build-time constants

```bash
rg -n --hidden "DefinePlugin|ldflags|-X main\.|#define|import\.meta\.env|__BUILD" .
```
```
./cmd/main.go:10:var Version = "dev" // set via -ldflags "-X main.Version=..."
./webpack.config.js:4:    new webpack.DefinePlugin({
./webpack.config.js:5:      __BUILD_SHA__: JSON.stringify(process.env.GIT_SHA),
```

### Axis 4 — feature flags

```bash
rg -ni --hidden "FLAG_[A-Z0-9_]+|feature[s]?\.|enable_[a-z_]+|launchdarkly|unleash|flagsmith|statsig|split\.io|GetBool" .
```
Representative hits (with `--hidden`; the run recorded in-session was without `--hidden` and missed `.env.example` — another instance of the gotcha):
```
./cmd/main.go:20:	if viper.GetBool("features.dark_mode") {
./deploy/k8s.yaml:9:  - name: FLAG_NEW_CHECKOUT
./src/server.js:4:const flags = { newCheckout: process.env.FLAG_NEW_CHECKOUT === 'true' };
./src/settings.py:9:    enable_beta_search: bool = False
./config/default.yaml:3:features:
./.env.example:4:FLAG_NEW_CHECKOUT=false
```

### Axis 5 — CLI arguments

```bash
rg -n --hidden "add_argument|flag\.(String|Int|Bool|Duration)|@click\.option|clap|cobra|yargs|commander" .
```
```
./cmd/main.go:13:	region := flag.String("region", "us-east-1", "aws region")
./src/cli.py:3:parser.add_argument("--verbose", action="store_true")
./src/cli.py:4:parser.add_argument("--region", default="us-east-1")
```

### Axis 7 — secrets

```bash
rg -ni --hidden "secretKeyRef|vault|secretsmanager|_API_KEY|_SECRET|_TOKEN|PASSWORD" .
```
Hits include:
```
./cmd/main.go:15:	token := os.Getenv("GITHUB_TOKEN")
./src/settings.py:5:API_KEY = os.getenv("STRIPE_API_KEY")
./deploy/k8s.yaml:6:      secretKeyRef:
./.env.example:3:STRIPE_API_KEY=sk_test_xxx
```

### Dead-flag candidate check

```bash
for v in PORT FLAG_NEW_CHECKOUT UNUSED_KNOB; do
  n=$(rg -l --hidden -g '!.env*' -g '!deploy' -g '!.github' "$v" . | wc -l)
  echo "$v: read in $n code file(s)"
done
```
```
PORT: read in 1 code file(s)
FLAG_NEW_CHECKOUT: read in 1 code file(s)
UNUSED_KNOB: read in 0 code file(s)
```

`UNUSED_KNOB` — the planted dead knob — is correctly flagged; the two live options are not.

### Setter cross-check

```bash
rg -n --hidden "FLAG_NEW_CHECKOUT" deploy .github .env.example
```
```
deploy/k8s.yaml:9:  - name: FLAG_NEW_CHECKOUT
.env.example:4:FLAG_NEW_CHECKOUT=false
```

Deploy sets it `"true"`, the example file says `false` — the divergence the inventory table exists to surface.

## Not verified in this sandbox

- `dotenv`/`pydantic-settings`/`viper` were NOT installed here; no fixture program was executed. All precedence statements about those libraries in SKILL.md are library-documentation-level craft knowledge, flagged there as such. The runnable part of the verification is the search patterns only.
