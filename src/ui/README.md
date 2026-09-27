# src/ui/

Drawing and input. **Owns no rules.** It reads the core state and never writes
to it.

Shake, particles, lighting, damage numbers and transitions all live here, and
none of them may be visible to the determinism hash. A task in this directory
that moves the hash is a bug, not a new baseline.
