# groq-404-doctor

when_to_use: |
  User reports HTTP 404 or "model not found" from Groq, or any OpenAI-compatible
  endpoint. Also invoke this when chat completions suddenly stop working but
  the API key still "looks valid".

## Why this skill exists

Groq regularly **decommissions, renames, or gates** models. A model ID that
works today (`llama-3.3-70b-versatile`) can return `HTTP 404` next month with
no warning beyond a changelog entry. The old Xpllc-Code installer shipped a
hardcoded list that included models with known issues
(`groq/compound`, `groq/compound-mini`,
`meta-llama/llama-4-scout-17b-16e-instruct`, `openai/gpt-oss-120b`). That's
the **root cause** of the historical "Groq 404" complaint.

## Diagnostic procedure

1. **Confirm the failure surface**
   Ask the user (or check logs) for the exact failing HTTP call:
   - Status code (`404` vs `400` vs `401` vs `429` — each means a different bug).
   - Full URL (is it hitting `/chat/completions` or accidentally `/completions`?).
   - Request body's `"model"` field.

2. **Verify the model is live** — use the shipped helper:
   ```bash
   bash ~/.config/xpllc-code/scripts/linux_tools.sh verify_groq_model <model-id>
   ```
   That script hits `/chat/completions` with a 1-token ping. Possible outcomes:

   | Exit | HTTP     | Meaning                                 | Fix                                                    |
   | ---- | -------- | --------------------------------------- | ------------------------------------------------------ |
   | 0    | 200/201  | Model is servable                       | Bug is elsewhere (body shape, wrong base URL).         |
   | 4    | 404      | Model decommissioned / renamed          | Switch model (see step 3).                             |
   | 5    | 400      | Request body malformed                  | Check JSON schema; common: bad `messages[].role`.      |
   | 5    | 401/403  | Invalid or expired API key              | Re-create key at console.groq.com/keys.                |
   | 5    | 429      | Rate-limited                            | Back off; model itself is fine.                        |

3. **Pick a replacement model** — fetch the live catalog:
   ```bash
   curl -s -H "Authorization: Bearer $OPENAI_API_KEY" \
     https://api.groq.com/openai/v1/models | jq -r '.data[].id' | sort
   ```
   As of late 2026 the safe-default for chat is:
   - **General coding:** `llama-3.3-70b-versatile`
   - **Fast iteration:** `llama-3.1-8b-instant`
   - **Long context coding:** `qwen/qwen3-32b`
   - **Budget OSS:** `openai/gpt-oss-20b`

4. **Rewrite the config**
   ```bash
   bash ubuntu_setup.sh    # pick option "3) Change Model"
   # or on Termux:
   bash termux_setup.sh    # pick option "3) Change Model"
   ```
   The v5+ installer **validates the chosen model against /chat/completions**
   before writing it to disk — a verified fix for the root cause.

5. **Verify the fix end-to-end** — not just the probe:
   ```bash
   xpllc --no-interactive <<< "print hello"
   ```

## Known-bad model IDs (auto-suggest replacement)

| Bad ID                                          | Replacement                            | Reason                             |
| ----------------------------------------------- | -------------------------------------- | ---------------------------------- |
| `groq/compound`                                 | `llama-3.3-70b-versatile`              | Historically 404s; tool-call mode only. |
| `groq/compound-mini`                            | `llama-3.1-8b-instant`                 | Same.                              |
| `meta-llama/llama-4-scout-17b-16e-instruct`     | `llama-3.3-70b-versatile`              | Frequently reported 404.           |
| `openai/gpt-oss-120b`                           | `openai/gpt-oss-20b` or `llama-3.3-70b-versatile` | Gated / not always servable. |
| `qwen/qwen3.6-plus:free`                        | `qwen/qwen3-32b` (Groq) or an OpenRouter `:free` | Was never a real model ID. |

## If the user insists on a decommissioned model

Explain honestly: "That model ID doesn't exist on Groq anymore. Here's the
live catalog; pick a replacement." Do NOT fabricate endpoints or suggest
hitting Anthropic / OpenAI with a Groq key.

## Never

- Silently swap the user's chosen model without telling them.
- Blame "temporary API issues" when the model is permanently gone.
- Commit a config file with an unvalidated model ID to the user's repo.
