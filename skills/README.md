# Xpllc-Code Skills Library

> Ported and adapted from the [Claw-Code](https://github.com/instructkr/claw-code)
> skills architecture. Each skill is a **self-contained directory** with a
> `SKILL.md` that tells the agent *when* to use the skill, *what* it does,
> and *how* to execute it.

## Design principles (from claw-code, preserved verbatim)

1. **Progressive disclosure** — skills are NOT loaded all at once. The agent
   reads the skill index (this file + top-level `SKILL.md` frontmatter) and
   pulls a skill's full body into context only when needed.
2. **Filesystem-native** — each skill is just a directory of Markdown + scripts.
   No registry, no YAML config, no plugin manager. `ls skills/` *is* the index.
3. **Coding-first** — every skill has a concrete success criterion (tests pass,
   lint clean, PR approved, etc.).

## Skill catalog

| Skill                   | When to invoke                                                      |
| ----------------------- | ------------------------------------------------------------------- |
| `code-review`           | User asks "review this PR / diff / file" or asks for a second pair of eyes. |
| `refactor`              | User asks to clean up, simplify, or restructure existing code.     |
| `test-generation`       | User asks for unit/integration/e2e tests for existing code.        |
| `debugging`             | User reports a bug, stack trace, or "it's broken".                 |
| `perf-audit`            | User mentions slowness, latency, memory, throughput.               |
| `security-audit`        | User asks about vulnerabilities, CVEs, secrets, auth, or crypto.   |
| `dependency-audit`      | User asks about outdated deps, licenses, or supply chain.          |
| `git-workflow`          | User asks about branches, rebases, cherry-picks, or PR hygiene.    |
| `docker-compose`        | User asks about containerization, compose files, or image builds.  |
| `groq-404-doctor`       | User reports HTTP 404 or 400 from a Groq / OpenAI-compatible API.  |

## Invocation protocol

The agent should, on request:

1. Scan `~/.config/xpllc-code/skills/` for directories.
2. Read each `SKILL.md`'s first 20 lines (the frontmatter + summary).
3. Match the user's request to the best-fitting skill by the `when_to_use`
   field.
4. Load the full `SKILL.md` body + any referenced scripts into context.
5. Execute following the **procedure** section of the skill.

## Adding a new skill

```bash
mkdir -p ~/.config/xpllc-code/skills/my-skill
cat > ~/.config/xpllc-code/skills/my-skill/SKILL.md <<'EOF'
# my-skill

when_to_use: |
  Short description of when the agent should invoke this skill.

## Procedure
1. Step one
2. Step two
EOF
```

That's it. No restart required — the agent picks up new skills on next scan.
