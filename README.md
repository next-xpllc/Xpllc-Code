# Xpllc-Code v5.0

**Coding-Optimized, Multi-Provider, Multi-Platform AI Coding Agent**
Groq + OpenRouter + Modal | Ubuntu + Termux + Windows | Claw-Code Skills Library

---

## What changed in v5.0 (this release)

### 🔥 Critical bug fixes

1. **Groq `HTTP 404` bug — ROOT CAUSE FIXED.**
   The previous installers shipped a hardcoded list of model IDs that
   frequently return `HTTP 404` on `/chat/completions` (even though
   `/models` still lists them):
   - `groq/compound`, `groq/compound-mini`
   - `meta-llama/llama-4-scout-17b-16e-instruct`
   - `openai/gpt-oss-120b`

   **Fix:** the installer now performs an actual `/chat/completions` ping
   with the chosen model *before* writing it to the launcher config, and
   auto-falls-back to `llama-3.3-70b-versatile` if the chosen model is
   decommissioned. See the new `skills/groq-404-doctor/SKILL.md` for the
   full diagnostic tree.

2. **OpenRouter fallback list referenced a non-existent model**
   (`qwen/qwen3.6-plus:free`). Replaced with verified live IDs.

3. **Windows installer now verifies the model post-install** via
   a PowerShell `/chat/completions` probe, so Windows users get the same
   safety net as Linux users.

### ✨ New features

- **🐧 Full Ubuntu / Debian / Fedora / Arch support** via
  `ubuntu_setup.sh` — no Termux required.
- **📚 Claw-Code-style skills library** — 10 coding-focused skills
  (`code-review`, `refactor`, `test-generation`, `debugging`, `perf-audit`,
  `security-audit`, `dependency-audit`, `git-workflow`, `docker-compose`,
  `groq-404-doctor`) that the agent loads *on demand* via progressive
  disclosure.
- **🛠 `linux_tools.sh`** — developer helper toolkit
  (`repo_overview`, `run_tests`, `quick_check`, `ports`, `deps_audit`,
  `verify_groq_model`, …).
- **🧠 Coding-optimized system prompt** (`CODING-GOD-MODE`) replacing the
  generic god-mode prompt. Emphasizes minimal diffs, verification, and
  house-style conformance.
- **📝 Comprehensive `CLAUDE.md`** installed to `$HOME` so the agent
  picks up identity, skills, and verification rules automatically.

---

## 🚀 Quickstart by platform

### Ubuntu / Debian / Fedora / Arch / WSL2

```bash
git clone https://github.com/next-xpllc/Xpllc-Code.git
cd Xpllc-Code
bash ubuntu_setup.sh
```

The installer will:

1. Install `nodejs` (≥18), `npm`, `curl`, `git`, `jq`.
2. Install `@gitlawb/openclaude` (the agent engine) into `~/.npm-global/`.
3. Install the skills library into `~/.config/xpllc-code/skills/`.
4. Install `linux_tools.sh` into `~/.config/xpllc-code/scripts/`.
5. Install `CLAUDE.md` into `$HOME` (only if not already present).
6. Ask you to pick a provider (Groq / OpenRouter / Modal) and model.
7. **Verify the chosen Groq model against `/chat/completions` before saving.**
8. Generate a launcher at `~/.local/bin/xpllc` (plus a `claude` alias
   if that name isn't already taken on your PATH).

Then:

```bash
# Open a new terminal (or: source ~/.bashrc) then:
xpllc                    # normal coding mode
xpllc --limitless        # auto-execute, no permission prompts
```

### Termux / Android

```bash
pkg install git
git clone https://github.com/next-xpllc/Xpllc-Code.git
cd Xpllc-Code
bash termux_setup.sh
```

The Termux installer retains **all** existing Android superpowers
(`mobile_tools.sh` — screenshots, UI automation, Shizuku, camera, SMS,
notifications) and additionally installs the skills library.

### Windows

```powershell
git clone https://github.com/next-xpllc/Xpllc-Code.git
cd Xpllc-Code
.\windows_setup.bat
```

After install, the `.bat` will automatically probe the chosen Groq model
with a PowerShell `Invoke-RestMethod` call so you know immediately if the
ID 404s.

### Windows → Phone (ADB push)

```powershell
.\pc_push_install.ps1
```

Unchanged from v4.0 except it now also pushes `CLAUDE.md` and the
`skills/` directory to the phone so the Termux installer can pick them up.

---

## 🧰 How the skills library works

Skills live at `~/.config/xpllc-code/skills/` (Linux) or
`~/.openclaude/skills/` (Termux), one per directory:

```
skills/
├── code-review/       SKILL.md
├── refactor/          SKILL.md
├── test-generation/   SKILL.md
├── debugging/         SKILL.md
├── perf-audit/        SKILL.md
├── security-audit/    SKILL.md
├── dependency-audit/  SKILL.md
├── git-workflow/      SKILL.md
├── docker-compose/    SKILL.md
├── groq-404-doctor/   SKILL.md
└── README.md
```

**Progressive disclosure** (the Claw-Code pattern):
the agent does **not** load every skill into context on startup. It scans
the directory listing, reads each `SKILL.md`'s `when_to_use:` frontmatter,
and pulls the full skill body only when the user's request matches.

### Adding your own skill

```bash
mkdir -p ~/.config/xpllc-code/skills/my-skill
cat > ~/.config/xpllc-code/skills/my-skill/SKILL.md <<'EOF'
# my-skill

when_to_use: |
  User asks about <topic>.

## Procedure
1. Step one
2. Step two
EOF
```

No restart required. The agent picks it up on next scan.

---

## 🩺 Diagnosing a "Groq 404" yourself

Any time Groq returns an unexpected 404, run:

```bash
bash ~/.config/xpllc-code/scripts/linux_tools.sh verify_groq_model <model-id>
```

The exit codes are:

| Exit | Meaning                                           |
| ---- | ------------------------------------------------- |
| 0    | Model is servable.                                |
| 4    | Model decommissioned / renamed → pick a new one.  |
| 5    | Other HTTP error (check API key, rate limits).    |

To list every model that's actually live on your Groq account:

```bash
curl -s -H "Authorization: Bearer $OPENAI_API_KEY" \
  https://api.groq.com/openai/v1/models | jq -r '.data[].id' | sort
```

Then re-run `bash ubuntu_setup.sh` and pick option **3) Change Model**.

---

## 🧑‍💻 Developer helper toolkit

`~/.config/xpllc-code/scripts/linux_tools.sh` bundles safe-by-default
developer helpers the agent can invoke on your behalf:

```bash
bash linux_tools.sh repo_overview       # language stats, LOC, top files, git status
bash linux_tools.sh fresh_branch feat/x # clean branch from origin/main
bash linux_tools.sh run_tests           # auto-detect and run the test runner
bash linux_tools.sh quick_check         # fast lint + typecheck
bash linux_tools.sh ports               # show listening TCP ports
bash linux_tools.sh deps_audit          # npm/pip/cargo vulnerability scan
bash linux_tools.sh verify_groq_model llama-3.3-70b-versatile
bash linux_tools.sh help                # full list
```

All commands are **read-only by default**; only `fresh_branch` and
`git_clean_slate` mutate state, and the latter prompts before acting.

---

## 🗂 Project layout

```
Xpllc-Code/
├── ubuntu_setup.sh          # NEW — Linux installer (v5.0 flagship)
├── termux_setup.sh          # Android/Termux installer (v5.0 bug-fixed)
├── windows_setup.bat        # Windows installer (v5.0 bug-fixed + model probe)
├── pc_push_install.ps1      # Windows → phone ADB push installer
├── scripts/
│   ├── linux_tools.sh       # NEW — Linux developer toolkit
│   ├── mobile_tools.sh      # Termux hardware / UI toolkit (unchanged)
│   └── setup_shizuku.sh     # Shizuku integration (unchanged)
├── skills/                  # NEW — Claw-Code-ported skills library
│   ├── README.md
│   ├── code-review/SKILL.md
│   ├── refactor/SKILL.md
│   ├── test-generation/SKILL.md
│   ├── debugging/SKILL.md
│   ├── perf-audit/SKILL.md
│   ├── security-audit/SKILL.md
│   ├── dependency-audit/SKILL.md
│   ├── git-workflow/SKILL.md
│   ├── docker-compose/SKILL.md
│   └── groq-404-doctor/SKILL.md
├── CLAUDE.md                # NEW — agent context (installed to $HOME)
├── LICENSE
└── README.md                # this file
```

---

## 🔐 Provider quick-reference

### Groq (recommended)

- Sign up: https://console.groq.com/keys (free tier available).
- Best default model: `llama-3.3-70b-versatile`.
- For coding with long context: `qwen/qwen3-32b`.
- Fastest / cheapest: `llama-3.1-8b-instant`.
- **Do not use** `groq/compound*` or `llama-4-scout*` unless you've
  verified them with `verify_groq_model` first.

### OpenRouter

- Sign up: https://openrouter.ai/.
- Free tier models end with `:free`.
- Good coding picks: `qwen/qwen-2.5-coder-32b-instruct:free`,
  `deepseek/deepseek-chat-v3.1:free`.

### Modal

- Requires you to deploy a vLLM/SGLang endpoint first.
- Docs: https://modal.com/docs/examples/vllm_inference.
- Endpoint URL format: `https://<workspace>--<app>-serve.modal.run/v1`.

---

## 🙏 Credits

- **`@gitlawb/openclaude`** — the underlying OpenAI-compatible agent
  engine this project wraps.
- **[instructkr/claw-code](https://github.com/instructkr/claw-code)** —
  the skills architecture (`SKILL.md` + progressive disclosure) is
  adapted from their Python port of the leaked Claw Code harness.
  All skill content in this repo is written from scratch for
  coding-first workflows; no Claw Code proprietary material is copied.

---

## 📜 License

MIT — see [LICENSE](./LICENSE).

## 🆘 Troubleshooting

| Symptom                                    | Fix                                                                 |
| ------------------------------------------ | ------------------------------------------------------------------- |
| `xpllc: command not found` after install   | Open a new terminal, or `source ~/.bashrc`. The installer appends `~/.npm-global/bin` + `~/.local/bin` to your PATH. |
| `HTTP 404` from Groq                       | Run `bash linux_tools.sh verify_groq_model <id>`, then re-run `ubuntu_setup.sh` and pick option 3 to switch models. |
| `HTTP 401` from Groq                       | Your API key is wrong or revoked. Generate a new one at https://console.groq.com/keys. |
| `npm ERR! EACCES` on Linux install         | The installer sets `npm config prefix ~/.npm-global` — but if you previously installed globally as root, `sudo chown -R $USER ~/.npm-global`. |
| Termux `mobile_tools.sh` commands fail     | You need Termux:API app installed + Shizuku running. See `scripts/setup_shizuku.sh`. |
| `claude` command conflicts with Anthropic's official CLI | The Ubuntu installer detects this and skips the alias — use `xpllc` directly. |
