# Gates: unlazy skill study

OWNS: GATES.md

Scope: read the complete unlazy skill documentation set and deliver one detailed, accurate explanation of its acceptance-gate workflow

- [x] G0: this ledger is machine-parseable and every oracle in it can fail
  CHECK: node "C:\Users\DELL\Downloads\Admin Mobile application build\.agents\skills\unlazy\scripts\gate-lint.mjs" GATES.md
  EXPECT: LINT OK
  EVIDENCE: automatic-evidence=v1; definition-sha256=e872fcc7e4822ed3b895703735fba4ab0f5cb0a44c9fefa07eaed3d97a219451; exit=0; EXPECT=matched; output-sha256=5f1b07cf89f3a3616276d79663dab2251d308c53854f59d4b12ee3c6d3b5e05f; output-bytes=268; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G1: the unlazy study reading set is present and non-empty on disk
  CHECK: node -e "const fs=require('fs');const b='C:/Users/DELL/Downloads/Admin Mobile application build/.agents/skills/unlazy/';const f=['SKILL.md','README.md','SECURITY.md','references/gates.md','references/method.md','references/orchestration.md','references/dispatch.md','references/parallel.md','references/token-economy.md','templates/gates-leaf.md','templates/gates-node.md','templates/PLAN.md'];const bad=f.filter(function(x){try{const s=fs.statSync(b+x);return !s.isFile()||s.size===0}catch(e){return true}});if(bad.length){console.error('missing-or-empty: '+bad.join(','));process.exit(1)}console.log('reading set complete')"
  EXPECT: reading set complete
  EVIDENCE: automatic-evidence=v1; definition-sha256=7e811417cdcf8547e10d417f167b042ba3267fa166f29913f84fb250ee57e801; exit=0; EXPECT=matched; output-sha256=b20fd23f60db75414089b8dc994419f65a3682d35f198e5dc5ebba082f7dcf2c; output-bytes=21; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G2: the unlazy skill is loaded and its gate workflow ran in the required order
  EVIDENCE: skill tool injected SKILL.md this session; gate-lint GATES.md exit=0 with LINT OK (2 advisory manual-gate warnings); gate-check --status before approval parsed 4 unchecked gates without executing; --approve disclosed CHECK/EXPECT/CWD/cmd.exe/PATH then PASS GATES:G0 and GATES:G1 with automatic-evidence=v1 digests; negative control of the G1 script with a bogus filename exited 1

- [x] G3: a detailed and accurate explanation of the unlazy workflow is delivered in the final response
  EVIDENCE: final response explains gate format, approval and evidence model, solo vs orchestrated modes, depth tree, four-pass leaf work, verification hierarchy, dispatch waves, abandonment, and token rules, with measured gate counts
