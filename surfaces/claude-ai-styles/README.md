# claude.ai style skills (canonical backup)

Writing-style skills registered on claude.ai (Settings > Capabilities) that live **only** on the
account, not in a plugin. Kept here as the versioned source of truth so they cannot be lost if the
claude.ai copy is deleted.

Deliberately NOT in `skills/` and NOT live-read: these are **manually invoked** (they apply
only when the user names the skill by its exact name) and **stable** (a fixed writing style). A
registered static copy on claude.ai is the right delivery for that shape - naming the skill applies
it instantly, there is no stale-shadow risk on a fixed style, and live-read would add a needless
fetch. The live-read model (rules + operational skills read from the repo) is for content that
changes; these do not. So: keep them registered on claude.ai, and keep this backup current if you
ever edit them there.

- [caveman-mode-style.md](caveman-mode-style.md)
- [caveman-clarity-style.md](caveman-clarity-style.md)

Em dashes were normalized to hyphens on import to satisfy the repo writing-style gate
([writing-style.md](../../rules/global/writing-style.md)); content is otherwise verbatim.
