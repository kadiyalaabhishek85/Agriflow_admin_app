# Gates: flutter app full-view survey

OWNS: GATES.md, APP_INVENTORY.md, GATES-archive-unlazy-study.md

Scope: establish and prove how much of the agriflow_admin Flutter application is actually seen, then answer the full-view question with measured evidence and explicit caveats

- [x] G0: this ledger is machine-parseable and every oracle in it can fail
  CHECK: node "C:\Users\DELL\Downloads\Admin Mobile application build\.agents\skills\unlazy\scripts\gate-lint.mjs" GATES.md
  EXPECT: LINT OK
  EVIDENCE: automatic-evidence=v1; definition-sha256=e872fcc7e4822ed3b895703735fba4ab0f5cb0a44c9fefa07eaed3d97a219451; exit=0; EXPECT=matched; output-sha256=5f1b07cf89f3a3616276d79663dab2251d308c53854f59d4b12ee3c6d3b5e05f; output-bytes=268; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G1: every dart file under lib and test is inventoried with a substantive description
  CHECK: node -e "const fs=require('fs');const p=require('path');const found=[];function walk(d){const es=fs.readdirSync(d,{withFileTypes:true});for(const e of es){const f=p.join(d,e.name);if(e.isDirectory()){walk(f)}else if(/\.dart$/.test(e.name)){found.push(f.split(p.sep).join('/'))}}}['lib','test'].forEach(function(r){if(!fs.existsSync(r)){console.error('missing root '+r);process.exit(1)}walk(r)});let txt='';try{txt=fs.readFileSync('APP_INVENTORY.md','utf8')}catch(e){console.error('inventory unreadable');process.exit(1)}const seen={};const re=/^-\s+`((?:lib|test)\/[^`]+\.dart)`:\s*(\S.{14,})\s*$/gm;let m;const listed=[];while((m=re.exec(txt))!==null){listed.push(m[1]);seen[m[1]]=(seen[m[1]]||0)+1}const missing=found.filter(function(f){return !seen[f]});const dup=listed.filter(function(f){return seen[f]>1});const extra=listed.filter(function(f){return found.indexOf(f)<0});if(missing.length||extra.length||dup.length){console.error('missing='+missing.join(' '));console.error('extra='+extra.join(' '));console.error('dup='+dup.join(' '));process.exit(1)}console.log('inventory covers every dart file with descriptions')"
  EXPECT: inventory covers every dart file with descriptions
  EVIDENCE: automatic-evidence=v1; definition-sha256=0a036e94574bf93eb66b388607050df48a9b50b61fdae73121ebb480ff1a8ee8; exit=0; EXPECT=matched; output-sha256=c6a403843bbb372b16c278c734cdbb5e9af6d5940555973b74a619c87902d15f; output-bytes=51; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G2: the application architecture is characterized from read source rather than file names alone
  EVIDENCE: read end-to-end in session: main.dart (21 lines), app.dart (650), admin_shell.dart (324), auth_controller.dart (126), auth_state.dart (93), nav_destination.dart (208), pubspec.yaml (92); sampled auth_remote_data_source.dart (90 of 249) and warehouse_repository_impl.dart (70 of 184); every one of the 153 dart files had its public types extracted from source text; APP_INVENTORY.md architecture section names concrete symbols, tab counts, NavDestination total, I* contract count, and the live api/v1 base URL

- [x] G3: a verdict on the full-view question is delivered with measured scope and explicit caveats
  EVIDENCE: final response states 153/153 files structurally inventoried (gate GATES:G1 exit=0), lists the files read in full, and explicitly scopes out line-by-line reading of the remaining lib bodies, the 17 test bodies, docs/, platform folders, and HTML/OpenAPI artifacts
