#!/usr/bin/env bash
# ─────────────────────────────────────────────
#  Xpllc-Code Linux Developer Toolkit
#  Companion to ubuntu_setup.sh — invoked by the agent.
#  Each subcommand is safe-by-default (read-only unless noted).
# ─────────────────────────────────────────────

set -uo pipefail

R='\033[0m'; B='\033[1m'; DIM='\033[2m'
RED='\033[1;31m'; GRN='\033[1;32m'; YLW='\033[1;33m'; CYN='\033[1;36m'

VERSION="1.0.0"

_err()  { echo -e "${RED}x${R} $*" >&2; }
_ok()   { echo -e "${GRN}+${R} $*"; }
_info() { echo -e "${CYN}i${R} $*"; }

_require() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || { _err "Missing required command: $cmd"; exit 1; }
    done
}

case "${1:-}" in

    repo_overview)
        # Read-only summary: languages, LOC, largest files, git status.
        _require git
        echo -e "${B}--- Repo Overview ---${R}"
        git rev-parse --show-toplevel >/dev/null 2>&1 || { _err "Not inside a git repo."; exit 1; }
        local_root=$(git rev-parse --show-toplevel)
        cd "$local_root"

        echo -e "${CYN}Root:${R} $local_root"
        echo -e "${CYN}Branch:${R} $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
        echo -e "${CYN}Head:${R}   $(git log -1 --pretty=format:'%h %s' 2>/dev/null)"
        echo ""

        echo -e "${B}Language mix (by tracked file extension):${R}"
        git ls-files 2>/dev/null | awk -F. 'NF>1{ext[$NF]++} END{for (e in ext) printf "  .%-8s %d\n", e, ext[e]}' | sort -k2 -rn | head -15
        echo ""

        echo -e "${B}Top 10 largest tracked files:${R}"
        git ls-files 2>/dev/null | xargs -I{} du -b "{}" 2>/dev/null | sort -rn | head -10 | awk '{printf "  %8d  %s\n", $1, $2}'
        echo ""

        echo -e "${B}Uncommitted changes:${R}"
        git status --short 2>/dev/null | head -20
        ;;

    fresh_branch)
        # Create new branch from origin/main (or origin/master) without clobbering WIP.
        _require git
        name="${2:-}"
        [ -z "$name" ] && { _err "Usage: linux_tools.sh fresh_branch <branch-name>"; exit 2; }
        if ! git diff --quiet || ! git diff --cached --quiet; then
            _err "You have uncommitted changes. Commit or stash first."
            exit 3
        fi
        git fetch origin --prune
        base="main"
        git rev-parse --verify origin/main >/dev/null 2>&1 || base="master"
        git checkout -b "$name" "origin/$base"
        _ok "Created '$name' from 'origin/$base'."
        ;;

    run_tests)
        # Auto-detect the project's test runner and invoke it — no guessing.
        cwd="$(pwd)"
        if [ -f "$cwd/package.json" ]; then
            _info "Detected Node.js project."
            if command -v jq >/dev/null 2>&1 && jq -e '.scripts.test' "$cwd/package.json" >/dev/null 2>&1; then
                exec npm test
            fi
            _err "No 'test' script in package.json."
            exit 1
        fi
        if [ -f "$cwd/pyproject.toml" ] || [ -f "$cwd/setup.py" ] || [ -d "$cwd/tests" ]; then
            _info "Detected Python project."
            if [ -f "$cwd/pyproject.toml" ] && grep -q 'pytest' "$cwd/pyproject.toml" 2>/dev/null; then
                exec pytest -q
            fi
            exec python3 -m unittest discover -s tests -v
        fi
        if [ -f "$cwd/Cargo.toml" ]; then
            _info "Detected Rust project."
            exec cargo test --workspace
        fi
        if [ -f "$cwd/go.mod" ]; then
            _info "Detected Go project."
            exec go test ./...
        fi
        _err "Could not auto-detect a test runner."
        exit 1
        ;;

    quick_check)
        # Ultra-fast lint/typecheck without running full tests — pre-commit style.
        cwd="$(pwd)"
        rc=0
        if [ -f "$cwd/package.json" ]; then
            _info "JS/TS quick check..."
            if [ -f "$cwd/tsconfig.json" ]; then npx --no-install tsc --noEmit || rc=$?; fi
            if grep -q '"lint"' "$cwd/package.json" 2>/dev/null; then npm run -s lint || rc=$?; fi
        fi
        if [ -f "$cwd/pyproject.toml" ] || [ -f "$cwd/setup.py" ]; then
            _info "Python quick check..."
            command -v ruff >/dev/null 2>&1 && { ruff check . || rc=$?; }
            command -v mypy >/dev/null 2>&1 && { mypy . || rc=$?; }
        fi
        if [ -f "$cwd/Cargo.toml" ]; then
            _info "Rust quick check..."
            cargo check --workspace --all-targets || rc=$?
        fi
        [ $rc -eq 0 ] && _ok "Quick check passed." || { _err "Quick check failed (rc=$rc)."; exit $rc; }
        ;;

    ports)
        # Show listening TCP ports with owning process (no sudo required for ss).
        if command -v ss >/dev/null 2>&1; then
            ss -tlnp 2>/dev/null | awk 'NR==1 || /LISTEN/'
        elif command -v netstat >/dev/null 2>&1; then
            netstat -tlnp 2>/dev/null
        else
            _err "Neither ss nor netstat available."
            exit 1
        fi
        ;;

    systemd_status)
        # Safe service inspection — status only, never start/stop without explicit intent.
        svc="${2:-}"
        [ -z "$svc" ] && { _err "Usage: linux_tools.sh systemd_status <service>"; exit 2; }
        systemctl status "$svc" --no-pager --lines=20 || true
        ;;

    docker_overview)
        # Read-only docker state.
        command -v docker >/dev/null 2>&1 || { _err "docker not installed"; exit 1; }
        echo -e "${B}Running containers:${R}"
        docker ps --format "  {{.ID}}  {{.Image}}  {{.Status}}  {{.Names}}" 2>/dev/null
        echo ""
        echo -e "${B}Images:${R}"
        docker images --format "  {{.Repository}}:{{.Tag}}  {{.Size}}" 2>/dev/null | head -15
        ;;

    deps_audit)
        # Best-effort dependency vulnerability scan.
        cwd="$(pwd)"
        [ -f "$cwd/package.json" ] && { _info "npm audit..."; npm audit --omit=dev || true; }
        [ -f "$cwd/requirements.txt" ] && command -v pip-audit >/dev/null 2>&1 && { _info "pip-audit..."; pip-audit -r requirements.txt || true; }
        [ -f "$cwd/Cargo.lock" ] && command -v cargo-audit >/dev/null 2>&1 && { _info "cargo audit..."; cargo audit || true; }
        ;;

    git_clean_slate)
        # Safe helper: shows what would be cleaned before doing it.
        _require git
        echo -e "${B}The following files would be removed by 'git clean -fdx':${R}"
        git clean -fdxn
        echo ""
        read -rp "Proceed with actual cleanup? (y/N): " c
        [[ "$c" =~ ^[Yy]$ ]] && git clean -fdx || _info "Aborted."
        ;;

    verify_groq_model)
        # Standalone validator the agent can invoke when the user reports "Groq 404".
        model="${2:-llama-3.3-70b-versatile}"
        key="${OPENAI_API_KEY:-${GROQ_API_KEY:-}}"
        [ -z "$key" ] && { _err "Set OPENAI_API_KEY or GROQ_API_KEY first."; exit 2; }
        payload=$(printf '{"model":"%s","max_tokens":1,"messages":[{"role":"user","content":"ping"}]}' "$model")
        code=$(curl -sS --max-time 15 -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
            -X POST "https://api.groq.com/openai/v1/chat/completions" --data "$payload")
        case "$code" in
            200|201) _ok "Groq model '$model' is servable (HTTP $code)." ;;
            404)     _err "Groq model '$model' returned 404 — decommissioned or renamed." ; exit 4 ;;
            *)       _err "Unexpected HTTP $code." ; exit 5 ;;
        esac
        ;;

    version)
        echo "linux_tools.sh v$VERSION"
        ;;

    ""|help|-h|--help)
        # printf (not heredoc) so color escapes actually render.
        printf "%b\n" "${B}Xpllc-Code Linux Developer Toolkit v${VERSION}${R}"
        echo ""
        echo "Usage: bash linux_tools.sh <command> [args]"
        echo ""
        printf "%b\n" "${B}Repository:${R}"
        echo "  repo_overview               Summarize languages, LOC, top files, git status"
        echo "  fresh_branch <name>         Create clean branch from origin/main"
        echo "  run_tests                   Auto-detect and run the project's test runner"
        echo "  quick_check                 Fast lint + typecheck (no full test run)"
        echo "  git_clean_slate             Preview and run 'git clean -fdx' safely"
        echo ""
        printf "%b\n" "${B}System:${R}"
        echo "  ports                       Show listening TCP ports"
        echo "  systemd_status <svc>        Inspect a systemd service (read-only)"
        echo "  docker_overview             Read-only docker containers + images"
        echo ""
        printf "%b\n" "${B}Security:${R}"
        echo "  deps_audit                  npm audit / pip-audit / cargo audit"
        echo "  verify_groq_model <id>      Sanity-check a Groq model against /chat/completions"
        echo ""
        printf "%b\n" "${B}Meta:${R}"
        echo "  version | help"
        ;;

    *)
        _err "Unknown command: $1"
        echo "Run 'bash linux_tools.sh help' for the full list."
        exit 2
        ;;
esac
