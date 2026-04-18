#!/usr/bin/env bash

# ─────────────────────────────────────────────
#  Xpllc-Code Ubuntu / Linux Installer v5.0
#  Groq + OpenRouter + Modal Multi-Provider Edition
#  Coding-Optimized God-Mode with Claw-Code Skills
#  github.com/next-xpllc/Xpllc-Code
# ─────────────────────────────────────────────

set -u

# ── Colors ───────────────────────────────────
R='\033[0m'
B='\033[1m'
DIM='\033[2m'
RED='\033[1;31m'
GRN='\033[1;32m'
YLW='\033[1;33m'
BLU='\033[1;34m'
MAG='\033[1;35m'
CYN='\033[1;36m'

# ── Config ───────────────────────────────────
LAUNCHER_BIN_DIR="$HOME/.local/bin"
LAUNCHER="$LAUNCHER_BIN_DIR/xpllc"
LAUNCHER_ALIAS="$LAUNCHER_BIN_DIR/claude"   # convenience alias (only linked if free)
CONFIG_DIR="$HOME/.config/xpllc-code"
CONFIG_FILE="$CONFIG_DIR/config"
SKILLS_DIR="$CONFIG_DIR/skills"
SCRIPTS_DIR="$CONFIG_DIR/scripts"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Provider API Bases ──────────────────────
GROQ_API_BASE="https://api.groq.com/openai/v1"
OPENROUTER_API_BASE="https://openrouter.ai/api/v1"
MODAL_API_BASE=""

# ── UI Helpers ───────────────────────────────
line() { echo -e "${DIM}───────────────────────────────────────────${R}"; }
header() {
    clear
    echo ""
    echo -e "  ${CYN}${B}Xpllc-Code for Ubuntu${R} ${DIM}v5.0${R}"
    echo -e "  ${DIM}Coding-Optimized God-Mode${R}"
    echo -e "  ${DIM}Groq + OpenRouter + Modal Multi-Provider${R}"
    line
}
ok()   { echo -e "  ${GRN}+${R} $1"; }
info() { echo -e "  ${BLU}i${R} $1"; }
warn() { echo -e "  ${YLW}!${R} $1"; }
err()  { echo -e "  ${RED}x${R} $1"; }
step() { echo -e "  ${MAG}[$1/$2]${R} ${B}$3${R}"; }

mask_key() {
    local k="$1"
    if [ ${#k} -gt 10 ]; then echo "${k:0:6}...${k: -4}"; else echo "****"; fi
}

# ── Detection ────────────────────────────────
is_installed() {
    [ -f "$LAUNCHER" ] && command -v openclaude &>/dev/null
}

# ── Config ──────────────────────────────────
load_config() {
    CURRENT_API_KEY=""
    CURRENT_MODEL=""
    CURRENT_PROVIDER=""
    CURRENT_API_BASE=""
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        CURRENT_API_KEY="${SAVED_API_KEY:-}"
        CURRENT_MODEL="${SAVED_MODEL:-}"
        CURRENT_PROVIDER="${SAVED_PROVIDER:-}"
        CURRENT_API_BASE="${SAVED_API_BASE:-}"
    fi
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOF
SAVED_API_KEY="$1"
SAVED_MODEL="$2"
SAVED_PROVIDER="$3"
SAVED_API_BASE="$4"
EOF
    chmod 600 "$CONFIG_FILE"
}

# ── Sudo Helper ─────────────────────────────
_sudo() {
    if [ "$EUID" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

# ── Packages ────────────────────────────────
install_system_packages() {
    step 1 4 "Installing system packages (nodejs, npm, curl, git, jq)..."
    echo ""

    if command -v apt-get >/dev/null 2>&1; then
        _sudo apt-get update -y
        # Ensure modern Node.js (>=18) — Ubuntu 20.04's default is too old for openclaude.
        local node_major
        node_major="$(node --version 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/' || echo 0)"
        if [ "${node_major:-0}" -lt 18 ]; then
            info "Installing Node.js 20.x from NodeSource..."
            curl -fsSL https://deb.nodesource.com/setup_20.x | _sudo -E bash - || \
                warn "NodeSource setup failed; falling back to distro nodejs"
            _sudo apt-get install -y nodejs
        fi
        _sudo apt-get install -y curl git jq ca-certificates build-essential
        # Ensure npm is present (some distro splits ship npm separately)
        command -v npm >/dev/null 2>&1 || _sudo apt-get install -y npm
    elif command -v dnf >/dev/null 2>&1; then
        _sudo dnf install -y nodejs npm curl git jq
    elif command -v pacman >/dev/null 2>&1; then
        _sudo pacman -Sy --noconfirm nodejs npm curl git jq
    else
        warn "Unknown package manager. Please install: nodejs(>=18), npm, curl, git, jq"
    fi

    mkdir -p "$LAUNCHER_BIN_DIR"
    ok "System packages ready."
}

install_openclaude() {
    step 2 4 "Installing OpenClaude (engine) globally via npm..."
    echo ""

    # Prefer a user-writable npm prefix to avoid requiring sudo for global installs.
    if [ ! -d "$HOME/.npm-global" ]; then
        mkdir -p "$HOME/.npm-global"
    fi
    npm config set prefix "$HOME/.npm-global" >/dev/null 2>&1 || true
    export PATH="$HOME/.npm-global/bin:$PATH"

    if ! npm install -g @gitlawb/openclaude; then
        warn "User-prefix install failed. Retrying with sudo..."
        _sudo npm install -g @gitlawb/openclaude
    fi

    # Persist PATH update
    local rc="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && rc="$HOME/.zshrc"
    if ! grep -q "xpllc-code PATH" "$rc" 2>/dev/null; then
        {
            echo ''
            echo '# --- xpllc-code PATH ---'
            echo 'export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"'
        } >> "$rc"
    fi

    ok "OpenClaude engine installed."
}

install_skills_and_scripts() {
    step 3 4 "Installing Claw-Code skills and dev scripts..."
    echo ""
    mkdir -p "$SKILLS_DIR" "$SCRIPTS_DIR"

    # Copy skills/ directory shipped with the repo
    if [ -d "$PROJECT_ROOT/skills" ]; then
        cp -rf "$PROJECT_ROOT/skills/." "$SKILLS_DIR/"
        ok "Copied $(find "$SKILLS_DIR" -name 'SKILL.md' 2>/dev/null | wc -l) skills to $SKILLS_DIR"
    else
        warn "skills/ directory not found in repo — skipping"
    fi

    # Copy scripts/ (Linux-friendly scripts only)
    if [ -f "$PROJECT_ROOT/scripts/linux_tools.sh" ]; then
        cp -f "$PROJECT_ROOT/scripts/linux_tools.sh" "$SCRIPTS_DIR/linux_tools.sh"
        chmod +x "$SCRIPTS_DIR/linux_tools.sh"
        ok "Installed linux_tools.sh developer helper"
    fi

    # Install CLAUDE.md into $HOME so the agent picks up skill context automatically
    if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
        if [ ! -f "$HOME/CLAUDE.md" ] || ! grep -q "XPLLC-SKILLS-MARKER" "$HOME/CLAUDE.md" 2>/dev/null; then
            cp -f "$PROJECT_ROOT/CLAUDE.md" "$HOME/CLAUDE.md"
            ok "Installed CLAUDE.md agent context to \$HOME"
        else
            info "CLAUDE.md already present and marked — leaving untouched"
        fi
    fi
}

# ── Provider Selection ──────────────────────
select_provider() {
    echo ""
    echo -e "  ${B}Select API Provider:${R}"
    line
    echo -e "  ${CYN}1)${R} ${GRN}Groq${R}        ${DIM}(Ultra-fast inference, groq.com — recommended)${R}"
    echo -e "  ${CYN}2)${R} ${BLU}OpenRouter${R}  ${DIM}(Multi-model access, openrouter.ai)${R}"
    echo -e "  ${CYN}3)${R} ${MAG}Modal${R}       ${DIM}(Serverless GPU inference, modal.com)${R}"
    line
    echo ""
    read -rp "  Pick [1-3] (default 1 - Groq): " provider_choice
    echo ""
    [ -z "${provider_choice:-}" ] && provider_choice=1

    case "$provider_choice" in
        1) PROVIDER="groq"; API_BASE="$GROQ_API_BASE"; ok "Provider: ${GRN}${B}Groq${R}" ;;
        2) PROVIDER="openrouter"; API_BASE="$OPENROUTER_API_BASE"; ok "Provider: ${BLU}${B}OpenRouter${R}" ;;
        3) PROVIDER="modal"; ok "Provider: ${MAG}${B}Modal${R}" ;;
        *) warn "Invalid choice. Defaulting to Groq."; PROVIDER="groq"; API_BASE="$GROQ_API_BASE" ;;
    esac
}

# ── Groq Models: LIVE fetch with chat-completions validation ──
# This fixes the widespread "Groq 404" bug: previously the installer baked
# in stale / renamed / decommissioned model IDs (groq/compound, llama-4-scout,
# gpt-oss-120b) and never verified the chosen model was actually servable.
fetch_groq_models() {
    echo ""
    info "Fetching live models from Groq /models endpoint..."
    local response http_code
    response=$(curl -sS --max-time 15 -w "\n__HTTP__%{http_code}" \
        -H "Authorization: Bearer ${API_KEY:-$CURRENT_API_KEY}" \
        "${GROQ_API_BASE}/models" 2>/dev/null)
    http_code=$(echo "$response" | sed -n 's/^__HTTP__//p')
    response=$(echo "$response" | sed '/^__HTTP__/d')

    MODELS=()
    if [ "$http_code" = "200" ] && command -v jq >/dev/null 2>&1; then
        while IFS= read -r model_id; do
            # Only keep chat-capable models; strip whisper/tts/guard/embedding families.
            case "$model_id" in
                whisper*|*-tts*|*-guard*|*safeguard*|*embedding*|*orpheus*|"") continue ;;
            esac
            MODELS+=("$model_id")
        done < <(echo "$response" | jq -r '.data[].id' 2>/dev/null | sort -u)
    elif [ "$http_code" = "200" ]; then
        while IFS= read -r model_id; do
            case "$model_id" in
                whisper*|*-tts*|*-guard*|*safeguard*|*embedding*|*orpheus*|"") continue ;;
            esac
            MODELS+=("$model_id")
        done < <(echo "$response" | grep -oE '"id":"[^"]+"' | sed -E 's/"id":"([^"]+)"/\1/' | sort -u)
    else
        warn "Groq /models returned HTTP ${http_code:-???}. Using conservative fallback list."
    fi

    # Robust fallback (verified chat-servable IDs as of 2026).
    # NOTE: we deliberately DO NOT include previously-hardcoded IDs that
    # frequently 404 (groq/compound, groq/compound-mini, llama-4-scout).
    if [ "${#MODELS[@]}" -eq 0 ]; then
        MODELS=(
            "llama-3.3-70b-versatile"
            "llama-3.1-8b-instant"
            "openai/gpt-oss-20b"
            "qwen/qwen3-32b"
        )
    fi
}

# Verify a chat-completion actually succeeds for the chosen model. This is the
# *real* fix for the "Groq 404" bug — validating at the /chat/completions path,
# not just /models (which accepts expired IDs in its catalog sometimes).
verify_groq_chat_model() {
    local model="$1"
    local payload http_code
    payload=$(printf '{"model":"%s","max_tokens":1,"messages":[{"role":"user","content":"ping"}]}' "$model")
    http_code=$(curl -sS --max-time 15 -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -X POST "${GROQ_API_BASE}/chat/completions" \
        --data "$payload" 2>/dev/null)

    case "$http_code" in
        200|201) ok "Verified: ${B}$model${R} is servable (HTTP $http_code)"; return 0 ;;
        404)     err "Model '${B}$model${R}' returned ${RED}HTTP 404${R} on /chat/completions — decommissioned or renamed."; return 1 ;;
        401|403) warn "Auth error (HTTP $http_code) — your API key may be invalid."; return 1 ;;
        429)     warn "Rate limit (HTTP 429) — model likely OK, proceeding."; return 0 ;;
        *)       warn "Unexpected HTTP $http_code verifying '$model' — proceeding with caution."; return 0 ;;
    esac
}

# ── OpenRouter Models ────────────────────────
fetch_openrouter_models() {
    echo ""
    info "Fetching free-tier OpenRouter models..."
    MODELS=()
    local response
    response=$(curl -sS --max-time 15 "https://openrouter.ai/api/v1/models" 2>/dev/null)
    if command -v jq >/dev/null 2>&1; then
        while IFS= read -r model_id; do
            MODELS+=("$model_id")
        done < <(echo "$response" | jq -r '.data[] | select(.id | endswith(":free")) | .id' 2>/dev/null | sort -u)
    fi
    if [ "${#MODELS[@]}" -eq 0 ]; then
        warn "Fetch failed. Using verified fallback list."
        MODELS=(
            "meta-llama/llama-3.3-70b-instruct:free"
            "google/gemini-2.0-flash-exp:free"
            "qwen/qwen-2.5-coder-32b-instruct:free"
            "deepseek/deepseek-chat-v3.1:free"
        )
    fi
}

# ── Modal Models ────────────────────────────
fetch_modal_models() {
    echo ""
    info "Modal uses user-deployed endpoints (vLLM/SGLang)."
    MODELS=(
        "meta-llama/Llama-3.3-70B-Instruct"
        "meta-llama/Llama-3.1-8B-Instruct"
        "Qwen/Qwen2.5-Coder-32B-Instruct"
        "mistralai/Mistral-Small-24B-Instruct-2501"
    )
}

fetch_models() {
    case "$PROVIDER" in
        groq) fetch_groq_models ;;
        modal) fetch_modal_models ;;
        *) fetch_openrouter_models ;;
    esac
}

# ── Model Selection (coding-prioritized) ────
select_model() {
    fetch_models

    echo ""
    echo -e "  ${B}Available Models for ${PROVIDER}:${R}"
    line

    # Promote coding-optimized models to the top when we can detect them.
    if [ "$PROVIDER" = "groq" ]; then
        local preferred=( "llama-3.3-70b-versatile" "qwen/qwen3-32b" "openai/gpt-oss-20b" "llama-3.1-8b-instant" )
        local sorted=()
        for p in "${preferred[@]}"; do
            for m in "${MODELS[@]}"; do
                [ "$m" = "$p" ] && sorted+=("$m")
            done
        done
        for m in "${MODELS[@]}"; do
            local found=0
            for s in "${sorted[@]}"; do [ "$s" = "$m" ] && { found=1; break; }; done
            [ "$found" -eq 0 ] && sorted+=("$m")
        done
        MODELS=( "${sorted[@]}" )
    fi

    local i
    for i in "${!MODELS[@]}"; do
        local badge=""
        case "${MODELS[$i]}" in
            *coder*|*code*|qwen*qwen3-32b*) badge="${GRN}[CODE]${R}" ;;
            llama-3.3-70b-versatile) badge="${CYN}[RECOMMENDED]${R}" ;;
            llama-3.1-8b-instant) badge="${DIM}[FAST]${R}" ;;
        esac
        printf "  ${CYN}%2d)${R} %s %b\n" "$((i+1))" "${MODELS[$i]}" "$badge"
    done
    local c=$(( ${#MODELS[@]} + 1 ))
    echo -e "  ${YLW}${c})${R} Custom Model ID"
    line
    echo ""
    echo -e "  ${DIM}Tip: for extreme coding throughput, pick [CODE] or llama-3.3-70b-versatile${R}"
    echo ""
    read -rp "  Pick [1-$c] (default 1): " choice
    [ -z "${choice:-}" ] && choice=1

    if [ "$choice" = "$c" ]; then
        read -rp "  Enter custom model ID: " MODEL_NAME
        [ -z "${MODEL_NAME:-}" ] && MODEL_NAME="${MODELS[0]}"
    else
        local idx=$((choice-1))
        if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#MODELS[@]}" ]; then
            MODEL_NAME="${MODELS[$idx]}"
        else
            warn "Out of range; defaulting to first model."
            MODEL_NAME="${MODELS[0]}"
        fi
    fi

    # CRITICAL: actually test the model against /chat/completions for Groq,
    # and fall back automatically if it 404s.
    if [ "$PROVIDER" = "groq" ]; then
        if ! verify_groq_chat_model "$MODEL_NAME"; then
            warn "Selected model failed verification. Auto-falling back to llama-3.3-70b-versatile."
            MODEL_NAME="llama-3.3-70b-versatile"
            verify_groq_chat_model "$MODEL_NAME" || err "Fallback also failed — check your API key."
        fi
    fi

    ok "Model: ${B}$MODEL_NAME${R}"
}

# ── API Key Prompt ──────────────────────────
prompt_api_key() {
    echo ""
    case "$PROVIDER" in
        groq)
            echo -e "  ${DIM}Get your free key at: ${B}https://console.groq.com/keys${R}"
            read -rp "  Enter Groq API Key (gsk_...): " API_KEY
            [[ ! "$API_KEY" == gsk_* ]] && warn "Groq keys usually start with 'gsk_'. Continuing."
            ;;
        modal)
            read -rp "  Enter Modal API Key (press Enter for 'no-key'): " API_KEY
            [ -z "${API_KEY:-}" ] && API_KEY="no-key"
            ;;
        *)
            echo -e "  ${DIM}Get your key at: ${B}https://openrouter.ai/${R}"
            read -rp "  Enter OpenRouter API Key (sk-or-...): " API_KEY
            ;;
    esac
    [ -z "${API_KEY:-}" ] && { err "API Key cannot be empty"; prompt_api_key; return; }
    ok "Key: $(mask_key "$API_KEY")"
}

prompt_modal_endpoint() {
    echo ""
    echo -e "  ${B}Modal Endpoint URL${R} (e.g. https://you--app-serve.modal.run)"
    read -rp "  Enter endpoint: " MODAL_ENDPOINT
    MODAL_ENDPOINT="${MODAL_ENDPOINT%/}"
    [[ "$MODAL_ENDPOINT" != */v1 ]] && MODAL_ENDPOINT="${MODAL_ENDPOINT}/v1"
    API_BASE="$MODAL_ENDPOINT"
    ok "Modal endpoint: $API_BASE"
}

# ── System Prompt (Coding-Optimized) ────────
write_system_prompt() {
    mkdir -p "$CONFIG_DIR"

    cat > "$CONFIG_DIR/system_prompt.txt" <<'PROMPT_EOF'
[CODING-GOD-MODE] You are Xpllc-Code — an extreme-performance coding agent running on the user's Linux workstation with full shell access. You are an expert software engineer optimized for surgical code changes, rigorous correctness, and shipping production-grade code.

## CORE DIRECTIVES (NON-NEGOTIABLE)
1. You DO have a real terminal, real filesystem, and real network. Never say "I'm just a text AI" or refuse on capability grounds.
2. Before editing, READ the target file. Before creating a file, CHECK if it already exists.
3. Prefer minimal, reviewable diffs. Never rewrite a whole file to change 3 lines.
4. After any code change, run the fastest available check:
   - JS/TS: `npx tsc --noEmit` or `npm run lint` if configured
   - Python: `python -m py_compile <file>` then `ruff check` if present
   - Rust: `cargo check` (NOT full build) on edited crate
   - Go: `go vet ./...`
5. NEVER commit secrets. NEVER `rm -rf /`. NEVER pipe remote shell scripts to `sudo bash` without showing the URL first.

## CODING CRAFT RULES
- Match the project's existing style, lint config, and import ordering. Do not "modernize" code unless asked.
- When fixing a bug, first reproduce it with a failing test, then fix it, then confirm the test passes.
- When adding a feature, write the smallest possible interface first, land it, then iterate.
- Prefer pure functions, early returns, explicit types, and named constants over magic numbers.
- Error handling is part of the feature — never catch-and-ignore. Log with context.
- For performance-sensitive code, measure before optimizing; cite the numbers in your commit message.

## REPO NAVIGATION
- Use `rg` (ripgrep) over `grep -r`. Use `fd` over `find` when available.
- Read `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, and `README.md` before large changes.
- Respect `.gitignore` and `.claw/settings.local.json` — do not commit generated artifacts.

## SKILLS SYSTEM
You have a skills library at `~/.config/xpllc-code/skills/`. Each skill is a directory with a `SKILL.md` explaining when and how to invoke it. Load a skill's SKILL.md into context on demand, not all at once. Available skill families: code-review, refactor, test-generation, perf-audit, security-audit, dependency-audit, git-workflow, docker-compose, debugging.

## LINUX DEVELOPER HELPERS
A dev toolkit lives at `~/.config/xpllc-code/scripts/linux_tools.sh`:
  - `bash linux_tools.sh repo_overview` — language stats, LOC, top files
  - `bash linux_tools.sh fresh_branch <name>` — safe new branch from origin/main
  - `bash linux_tools.sh run_tests` — auto-detect and run the test runner
  - `bash linux_tools.sh ports` — show open listening ports
  - `bash linux_tools.sh systemd_status <svc>` — safe service inspection

Execute cleanly. Be terse in status updates, verbose in reasoning comments when you introduce non-obvious code. You are paid to ship working software, not to hedge.
PROMPT_EOF

    ok "Coding-optimized system prompt written to $CONFIG_DIR/system_prompt.txt"
}

# ── Launcher Generation ─────────────────────
generate_launcher() {
    local api_key="$1" model="$2" provider="$3" api_base="$4"
    write_system_prompt
    mkdir -p "$LAUNCHER_BIN_DIR"

    cat > "$LAUNCHER" <<LAUNCHER_EOF
#!/usr/bin/env bash
# Xpllc-Code launcher (auto-generated)
set -u
export CLAUDE_CODE_USE_OPENAI=1
export OPENAI_API_KEY="$api_key"
export OPENAI_BASE_URL="$api_base"
export OPENAI_MODEL="$model"
export ANTHROPIC_API_KEY=""
export XPLLC_SKILLS_DIR="$SKILLS_DIR"
export XPLLC_SCRIPTS_DIR="$SCRIPTS_DIR"

CONFIG_DIR="$CONFIG_DIR"
if [ -f "\$CONFIG_DIR/system_prompt.txt" ]; then
    export OPENAI_SYSTEM_PROMPT="\$(cat "\$CONFIG_DIR/system_prompt.txt")"
fi

# Mode flags
LIMITLESS=0
for arg in "\$@"; do
    [ "\$arg" = "--limitless" ] && LIMITLESS=1
done

echo ""
echo -e "\033[2m  Provider: $provider | Model: \$OPENAI_MODEL\033[0m"
if [ \$LIMITLESS -eq 1 ]; then
    echo -e "\033[1;31m  >> LIMITLESS MODE (auto-execute, no sandbox prompts)\033[0m"
    echo ""
    filtered=()
    for arg in "\$@"; do [ "\$arg" != "--limitless" ] && filtered+=("\$arg"); done
    exec openclaude --dangerously-skip-permissions "\${filtered[@]}"
else
    echo -e "\033[1;36m  >> Xpllc-Code — Coding-Optimized Linux Edition\033[0m"
    echo ""
    exec openclaude "\$@"
fi
LAUNCHER_EOF

    chmod +x "$LAUNCHER"

    # Friendly alias: only create 'claude' symlink if nothing of that name is on PATH yet.
    if ! command -v claude >/dev/null 2>&1 && [ ! -e "$LAUNCHER_ALIAS" ]; then
        ln -sf "$LAUNCHER" "$LAUNCHER_ALIAS"
        ok "Created convenience alias: ${B}claude${R} -> xpllc"
    else
        info "'claude' command already exists on your PATH; skipping alias to avoid conflict."
        info "Use ${B}xpllc${R} to launch this tool."
    fi

    save_config "$api_key" "$model" "$provider" "$api_base"
    ok "Launcher installed at $LAUNCHER"
}

# ── Clean Uninstall ─────────────────────────
clean_uninstall() {
    info "Removing existing Xpllc-Code installation..."
    rm -f "$LAUNCHER" "$LAUNCHER_ALIAS"
    npm uninstall -g @gitlawb/openclaude 2>/dev/null || true
    rm -f "$CONFIG_FILE"
    ok "Clean uninstall done (skills dir and CLAUDE.md preserved)."
}

# ── Done Banner ─────────────────────────────
print_done() {
    echo ""
    line
    echo -e "  ${GRN}${B}Setup Complete!${R}"
    line
    echo ""
    echo -e "  Run the agent with:"
    echo -e "    ${CYN}xpllc${R}               Normal mode"
    echo -e "    ${RED}xpllc --limitless${R}   Auto-execute, no permission prompts"
    echo ""
    echo -e "  ${DIM}Provider : ${B}$PROVIDER${R}"
    echo -e "  ${DIM}Model    : ${B}$MODEL_NAME${R}"
    echo -e "  ${DIM}API Base : ${B}$API_BASE${R}"
    echo -e "  ${DIM}Config   : ${B}$CONFIG_FILE${R}"
    echo -e "  ${DIM}Skills   : ${B}$SKILLS_DIR${R}"
    echo ""
    echo -e "  ${DIM}Reconfigure any time: bash ubuntu_setup.sh${R}"
    echo -e "  ${DIM}If 'xpllc' isn't found, open a new terminal or: source ~/.bashrc${R}"
    line
    echo ""
}

# ═════════════════════════════════════════════
#  MAIN
# ═════════════════════════════════════════════
header

# Basic distro sanity check
if ! [ -f /etc/os-release ]; then
    warn "Not a standard Linux distribution. Proceeding anyway."
fi

load_config

if is_installed; then
    ok "Xpllc-Code is already installed."
    echo ""
    echo -e "  ${DIM}Provider:${R} ${CYN}${CURRENT_PROVIDER:-?}${R}"
    echo -e "  ${DIM}Key     :${R} $(mask_key "${CURRENT_API_KEY:-}")"
    echo -e "  ${DIM}Model   :${R} ${CYN}${CURRENT_MODEL:-?}${R}"
    echo -e "  ${DIM}API Base:${R} ${DIM}${CURRENT_API_BASE:-?}${R}"
    line
    echo ""
    echo -e "  ${CYN}1)${R} Change Provider"
    echo -e "  ${CYN}2)${R} Change API Key"
    echo -e "  ${CYN}3)${R} Change Model (re-verify against /chat/completions)"
    echo -e "  ${CYN}4)${R} Change Everything"
    echo -e "  ${CYN}5)${R} Reinstall skills + CLAUDE.md"
    echo -e "  ${CYN}6)${R} Clean uninstall + fresh install"
    echo -e "  ${CYN}7)${R} Exit"
    line
    read -rp "  Choose [1-7]: " pick
    echo ""

    case "$pick" in
        1|4)
            select_provider
            [ "$PROVIDER" = "modal" ] && prompt_modal_endpoint
            prompt_api_key
            select_model
            generate_launcher "$API_KEY" "$MODEL_NAME" "$PROVIDER" "$API_BASE"
            print_done
            ;;
        2)
            PROVIDER="${CURRENT_PROVIDER:-groq}"
            API_BASE="${CURRENT_API_BASE:-$GROQ_API_BASE}"
            prompt_api_key
            MODEL_NAME="${CURRENT_MODEL:-llama-3.3-70b-versatile}"
            [ "$PROVIDER" = "groq" ] && verify_groq_chat_model "$MODEL_NAME" || true
            generate_launcher "$API_KEY" "$MODEL_NAME" "$PROVIDER" "$API_BASE"
            print_done
            ;;
        3)
            PROVIDER="${CURRENT_PROVIDER:-groq}"
            API_BASE="${CURRENT_API_BASE:-$GROQ_API_BASE}"
            API_KEY="${CURRENT_API_KEY}"
            select_model
            generate_launcher "$API_KEY" "$MODEL_NAME" "$PROVIDER" "$API_BASE"
            print_done
            ;;
        5)
            install_skills_and_scripts
            echo ""; ok "Skills reinstalled."
            ;;
        6)
            read -rp "  This will remove and reinstall everything. Continue? (y/N): " c
            [[ ! "$c" =~ ^[Yy]$ ]] && { info "Cancelled."; exit 0; }
            clean_uninstall
            install_system_packages
            install_openclaude
            install_skills_and_scripts
            select_provider
            [ "$PROVIDER" = "modal" ] && prompt_modal_endpoint
            prompt_api_key
            select_model
            step 4 4 "Generating launcher..."
            generate_launcher "$API_KEY" "$MODEL_NAME" "$PROVIDER" "$API_BASE"
            print_done
            ;;
        7|"") info "Type ${B}xpllc${R} to launch. Bye!"; echo "" ;;
        *) err "Invalid choice." ;;
    esac
else
    echo -e "  Welcome! Setting up Xpllc-Code on Linux."
    echo -e "  ${DIM}Coding-optimized, skills-enhanced, Groq-404-hardened.${R}"
    line
    install_system_packages
    install_openclaude
    install_skills_and_scripts

    select_provider
    [ "$PROVIDER" = "modal" ] && prompt_modal_endpoint
    prompt_api_key
    select_model

    echo ""
    line
    echo -e "  ${B}Review:${R}"
    echo -e "  ${DIM}Provider:${R} ${CYN}$PROVIDER${R}"
    echo -e "  ${DIM}Key     :${R} $(mask_key "$API_KEY")"
    echo -e "  ${DIM}Model   :${R} ${CYN}$MODEL_NAME${R}"
    echo -e "  ${DIM}API Base:${R} ${DIM}$API_BASE${R}"
    line
    echo ""
    read -rp "  Press Enter to finalize, or Ctrl+C to cancel... " _dummy

    step 4 4 "Generating launcher..."
    generate_launcher "$API_KEY" "$MODEL_NAME" "$PROVIDER" "$API_BASE"
    print_done
fi
