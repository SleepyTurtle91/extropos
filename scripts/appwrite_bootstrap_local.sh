#!/usr/bin/env bash
set -euo pipefail

# Bootstraps a local/self-hosted Appwrite instance for ExtroPOS.
# - Starts docker compose (docker/appwrite-compose.yml)
# - Waits for health
# - Creates project, server key, database extropos_db, and 6 collections with attributes/indexes
# Requirements: docker, docker compose, curl

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
COMPOSE_FILE="$ROOT_DIR/docker/appwrite-compose.yml"
DATA_DIR="$ROOT_DIR/appwrite-data"
ENDPOINT=${APPWRITE_ENDPOINT:-"http://localhost/v1"}
PROJECT_ID=${APPWRITE_PROJECT_ID:-"extropos"}
PROJECT_NAME=${APPWRITE_PROJECT_NAME:-"ExtroPOS"}
DB_ID=${APPWRITE_DB_ID:-"extropos_db"}

log() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }

req() {
  local method="$1" url="$2" key="$3" body="$4"
  local http
  http=$(curl -s -o /tmp/appwrite_res.json -w "%{http_code}" -X "$method" "$url" \
    -H "X-Appwrite-Project: ${PROJECT_ID}" \
    -H "X-Appwrite-Key: ${key}" \
    -H "Content-Type: application/json" \
    -d "$body") || http=000
  printf "%s" "$http"
}

req_console() {
  local method="$1" url="$2" body="$3"
  local http
  http=$(curl -s -o /tmp/appwrite_res.json -w "%{http_code}" -X "$method" "$url" \
    -H "X-Appwrite-Project: console" \
    -H "X-Appwrite-Key: ${CONSOLE_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body") || http=000
  printf "%s" "$http"
}

ensure_dirs() {
  mkdir -p "$DATA_DIR"/{mysql,redis,storage,config}
}

start_compose() {
  log "Starting docker compose ($COMPOSE_FILE)"
  (cd "$ROOT_DIR" && docker compose -f "$COMPOSE_FILE" up -d)
}

wait_health() {
  log "Waiting for Appwrite health at $ENDPOINT/health/version"
  for i in {1..40}; do
    if curl -sf "$ENDPOINT/health/version" >/dev/null; then
      log "Appwrite is reachable"
      return 0
    fi
    sleep 3
  done
  log "Appwrite health check failed" && exit 1
}

fetch_console_key() {
  local cid
  cid=$(cd "$ROOT_DIR" && docker compose -f "$COMPOSE_FILE" ps -q appwrite)
  if [ -z "$cid" ]; then
    log "Cannot find appwrite container" && exit 1
  fi
  CONSOLE_KEY=$(docker exec "$cid" printenv _APP_CONSOLE_API_KEY)
  if [ -z "${CONSOLE_KEY:-}" ]; then
    log "Console API key not found" && exit 1
  fi
  log "Console key retrieved"
}

create_project() {
  local http
  http=$(req_console POST "$ENDPOINT/projects" "{\"projectId\":\"$PROJECT_ID\",\"name\":\"$PROJECT_NAME\"}")
  if [ "$http" = "201" ] || [ "$http" = "409" ]; then
    log "Project ensured (http $http)"
  else
    log "Project create failed (http $http)" && cat /tmp/appwrite_res.json && exit 1
  fi
}

create_server_key() {
  local http
  http=$(req_console POST "$ENDPOINT/projects/$PROJECT_ID/keys" "{\"name\":\"extropos-server\",\"scopes\":[\"databases.read\",\"databases.write\",\"collections.read\",\"collections.write\",\"documents.read\",\"documents.write\"]}")
  if [ "$http" = "201" ]; then
    SERVER_KEY=$(python3 - <<'PY'
import json
import sys
data=json.load(open('/tmp/appwrite_res.json'))
print(data.get('secret',''))
PY
)
    log "Server key created"
  elif [ "$http" = "409" ]; then
    SERVER_KEY=${APPWRITE_API_KEY:-}
    if [ -z "$SERVER_KEY" ]; then
      log "Server key exists; set APPWRITE_API_KEY env to reuse it" && exit 1
    fi
    log "Server key reused from env"
  else
    log "Server key create failed (http $http)" && cat /tmp/appwrite_res.json && exit 1
  fi
}

create_db() {
  local http
  http=$(req POST "$ENDPOINT/databases" "$SERVER_KEY" "{\"databaseId\":\"$DB_ID\",\"name\":\"ExtroPOS DB\"}")
  if [ "$http" = "201" ] || [ "$http" = "409" ]; then
    log "Database ensured (http $http)"
  else
    log "Database create failed (http $http)" && cat /tmp/appwrite_res.json && exit 1
  fi
}

create_collection() {
  local cid="$1" name="$2"
  local http
  http=$(req POST "$ENDPOINT/databases/$DB_ID/collections" "$SERVER_KEY" "{\"collectionId\":\"$cid\",\"name\":\"$name\",\"permissions\":{\"read\":[\"role:any\"],\"create\":[\"role:users\"],\"update\":[\"role:users\"],\"delete\":[\"role:users\"]}}");
  if [ "$http" = "201" ] || [ "$http" = "409" ]; then
    log "Collection $cid ensured (http $http)"
  else
    log "Collection $cid failed (http $http)" && cat /tmp/appwrite_res.json && exit 1
  fi
}

attr_string() { req POST "$ENDPOINT/databases/$DB_ID/collections/$1/attributes/string" "$SERVER_KEY" "$2" >/dev/null; }
attr_bool()   { req POST "$ENDPOINT/databases/$DB_ID/collections/$1/attributes/boolean" "$SERVER_KEY" "$2" >/dev/null; }
attr_double() { req POST "$ENDPOINT/databases/$DB_ID/collections/$1/attributes/float" "$SERVER_KEY" "$2" >/dev/null; }
attr_int()    { req POST "$ENDPOINT/databases/$DB_ID/collections/$1/attributes/integer" "$SERVER_KEY" "$2" >/dev/null; }
attr_dt()     { req POST "$ENDPOINT/databases/$DB_ID/collections/$1/attributes/datetime" "$SERVER_KEY" "$2" >/dev/null; }

index_key() {
  req POST "$ENDPOINT/databases/$DB_ID/collections/$1/indexes" "$SERVER_KEY" "$2" >/dev/null
}

seed_collections() {
  # business_info
  create_collection business_info business_info
  attr_string business_info '{"key":"business_id","size":255,"required":true}'
  attr_string business_info '{"key":"user_id","size":255,"required":true}'
  attr_string business_info '{"key":"name","size":255,"required":true}'
  attr_string business_info '{"key":"address","size":500,"required":false}'
  attr_string business_info '{"key":"phone","size":50,"required":false}'
  attr_string business_info '{"key":"email","size":255,"required":false}'
  attr_string business_info '{"key":"tax_number","size":100,"required":false}'
  attr_string business_info '{"key":"currency_symbol","size":10,"required":false}'
  attr_bool   business_info '{"key":"is_tax_enabled","required":true}'
  attr_double business_info '{"key":"tax_rate","required":true}'
  attr_bool   business_info '{"key":"is_service_charge_enabled","required":true}'
  attr_double business_info '{"key":"service_charge_rate","required":true}'
  attr_string business_info '{"key":"receipt_header","size":1000,"required":false}'
  attr_string business_info '{"key":"receipt_footer","size":1000,"required":false}'
  attr_string business_info '{"key":"logo_path","size":500,"required":false}'
  attr_dt     business_info '{"key":"updated_at","required":true}'
  index_key   business_info '{"key":"business_id_idx","type":"key","attributes":["business_id"],"orders":["asc"]}'

  # categories
  create_collection categories categories
  attr_string categories '{"key":"business_id","size":255,"required":true}'
  attr_string categories '{"key":"category_id","size":255,"required":true}'
  attr_string categories '{"key":"name","size":255,"required":true}'
  attr_string categories '{"key":"icon","size":100,"required":false}'
  attr_string categories '{"key":"color","size":50,"required":false}'
  attr_dt     categories '{"key":"updated_at","required":true}'
  index_key   categories '{"key":"business_id_idx","type":"key","attributes":["business_id"],"orders":["asc"]}'
  index_key   categories '{"key":"category_id_idx","type":"key","attributes":["category_id"],"orders":["asc"]}'

  # products
  create_collection products products
  attr_string products '{"key":"business_id","size":255,"required":true}'
  attr_string products '{"key":"product_id","size":255,"required":true}'
  attr_string products '{"key":"store_id","size":255,"required":false}'
  attr_string products '{"key":"name","size":255,"required":true}'
  attr_double products '{"key":"price","required":true}'
  attr_string products '{"key":"category","size":255,"required":false}'
  attr_string products '{"key":"icon","size":100,"required":false}'
  attr_dt     products '{"key":"updated_at","required":true}'
  index_key   products '{"key":"business_id_idx","type":"key","attributes":["business_id"],"orders":["asc"]}'
  index_key   products '{"key":"product_id_idx","type":"key","attributes":["product_id"],"orders":["asc"]}'
  index_key   products '{"key":"store_id_idx","type":"key","attributes":["store_id"],"orders":["asc"]}'

  # modifiers
  create_collection modifiers modifiers
  attr_string modifiers '{"key":"business_id","size":255,"required":true}'
  attr_string modifiers '{"key":"modifier_id","size":255,"required":true}'
  attr_string modifiers '{"key":"name","size":255,"required":true}'
  attr_dt     modifiers '{"key":"updated_at","required":true}'
  index_key   modifiers '{"key":"business_id_idx","type":"key","attributes":["business_id"],"orders":["asc"]}'
  index_key   modifiers '{"key":"modifier_id_idx","type":"key","attributes":["modifier_id"],"orders":["asc"]}'

  # tables
  create_collection tables tables
  attr_string tables '{"key":"business_id","size":255,"required":true}'
  attr_string tables '{"key":"table_id","size":255,"required":true}'
  attr_string tables '{"key":"name","size":255,"required":true}'
  attr_int    tables '{"key":"capacity","required":true,"min":0,"max":5000}'
  attr_dt     tables '{"key":"updated_at","required":true}'
  index_key   tables '{"key":"business_id_idx","type":"key","attributes":["business_id"],"orders":["asc"]}'
  index_key   tables '{"key":"table_id_idx","type":"key","attributes":["table_id"],"orders":["asc"]}'

  # users
  create_collection users users
  attr_string users '{"key":"business_id","size":255,"required":true}'
  attr_string users '{"key":"user_id","size":255,"required":true}'
  attr_string users '{"key":"username","size":255,"required":true}'
  attr_string users '{"key":"full_name","size":255,"required":true}'
  attr_string users '{"key":"role","size":50,"required":true}'
  attr_dt     users '{"key":"updated_at","required":true}'
  index_key   users '{"key":"business_id_idx","type":"key","attributes":["business_id"],"orders":["asc"]}'
  index_key   users '{"key":"user_id_idx","type":"key","attributes":["user_id"],"orders":["asc"]}'
}

main() {
  log "Using endpoint: $ENDPOINT"
  ensure_dirs
  start_compose
  wait_health
  fetch_console_key
  create_project
  create_server_key
  create_db
  seed_collections
  log "Done. Endpoint: $ENDPOINT | Project: $PROJECT_ID | DB: $DB_ID"
  log "Server API key: ${SERVER_KEY:-set APPWRITE_API_KEY env if reused}"
}

main "$@"
