# Gates: build, endpoint connectivity, and workflow review

OWNS: GATES.md, GATES-archive-grain-sales-fix.md, scripts/verify-endpoints.mjs, docs/audits/build-endpoint-workflow-review.md

Scope: review the current application build and prove, with re-measured evidence, that the build is healthy, every backend path the app calls exists in the deployed contract and is reachable live, all implemented workflows are wired end-to-end, and a severity-ranked findings report with remediation exists.

- [x] G0: this ledger states outcomes that can fail
  CHECK: node ".agents/skills/unlazy/scripts/gate-lint.mjs" GATES.md
  EXPECT: LINT OK
  EVIDENCE: automatic-evidence=v1; definition-sha256=279d35a814afc0e8282a005d41dd446d9b02a155aae1930ea56f7a4d1241cc63; exit=0; EXPECT=matched; output-sha256=48630b7361dd44ee870917b12c3d19b9d7bdea738aaca16bb04d4cab83b772d2; output-bytes=8; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G1: static analysis of the current sources reports zero issues
  CHECK: flutter analyze
  EXPECT: No issues found
  EVIDENCE: automatic-evidence=v1; definition-sha256=b8badb6fe2643761b647b9e939b258b60eb65ab6cd263d52b01f1d670b68a892; exit=0; EXPECT=matched; output-sha256=08551cbb35d72161c1946716261fe3c04711d24e87e6cc82908695c924d39566; output-bytes=96; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G2: the full test suite passes from a clean run
  CHECK: flutter test
  EXPECT: All tests passed!
  EVIDENCE: automatic-evidence=v1; definition-sha256=b0c5c7eac1cebd97a444c8321c184da087193670732e19682190d1f059dae84e; exit=0; EXPECT=matched; output-sha256=fb9d2b178aa158ab0d7ce5684ba56a67820860ad2975097d70ed9db67b003f9e; output-bytes=69381; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G3: the debug Android APK builds successfully from current sources
  CHECK: flutter build apk --debug
  EXPECT: app-debug.apk
  EVIDENCE: automatic-evidence=v1; definition-sha256=83d03707b2471063ab9bf34d021d8aa2fd5ef539a5f28e77674bb83059ad9f4b; exit=0; EXPECT=matched; output-sha256=b0bf69d02852e54f1ce7326f92683f482efbd5615e413ad6c16c3ef38e0218b3; output-bytes=127; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G4: every backend path referenced by lib/ exists in the deployed OpenAPI contract, with a positive control proving the absence check can fail
  CHECK: node scripts/verify-endpoints.mjs contract
  EXPECT: ENDPOINTS CONNECTED
  EVIDENCE: automatic-evidence=v1; definition-sha256=d1a99d4bb332422560560a7c79ccb6b45d2f44b8c7172f7067e246fa1dbb7625; exit=0; EXPECT=matched; output-sha256=1a4d9a803fa056ebbef147430a9309612bfacbe48ac39c27adfde280ef0a18a6; output-bytes=88; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G5: the live service answers public endpoints with 200 and guarded routes with auth rejection, after a 404 control confirms probe semantics
  CHECK: node scripts/verify-endpoints.mjs probes
  EXPECT: PROBES OK
  EVIDENCE: automatic-evidence=v1; definition-sha256=fe83f2675e07b093464d6b070b46d095e92ee630623ec9ad826b822d41631498; exit=0; EXPECT=matched; output-sha256=0116a2813af424e9d5c1cbc8336460297da8fa5e2a9e8406c150f6c32a0c3b6f; output-bytes=45; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G6: all nine admin modules and five manager tabs are wired to real screens with a placeholder fallback, measured from the shell sources
  CHECK: node -e "const fs=require('fs');const a=fs.readFileSync('lib/features/admin/presentation/admin_shell.dart','utf8');const m=fs.readFileSync('lib/features/manager/presentation/manager_shell.dart','utf8');const n=fs.readFileSync('lib/core/navigation/nav_destination.dart','utf8');const ids=['home','seedPurchase','seedsInventory','bookingSlot','farmVisits','grainSales','allFarmers','warehouse','account'];const miss=ids.filter(function(id){return a.indexOf('NavDestination.'+id+'.id')<0});if(miss.length){console.error('admin shell missing route checks: '+miss.join(','));process.exit(1)}if(a.indexOf('ModulePlaceholderScreen')<0){console.error('admin placeholder fallback missing');process.exit(1)}if(m.indexOf('ModulePlaceholderScreen')<0){console.error('manager placeholder fallback missing');process.exit(1)}const tabs=(n.match(/managerTabIndex:/g)||[]).length;if(tabs!==5){console.error('expected 5 manager tabs, found '+tabs);process.exit(1)}console.log('WORKFLOW WIRING OK (9 admin routes, 5 manager tabs, placeholder fallbacks present)')"
  EXPECT: WORKFLOW WIRING OK
  EVIDENCE: automatic-evidence=v1; definition-sha256=b266df01f8b5c8f55a6eca4ecfb2c3d0eb4257cfa7c8b70fa83207e7d2020aa2; exit=0; EXPECT=matched; output-sha256=f59513442a92a6de37f15e1bf08911df15c642f0ad67532df661b65025280389; output-bytes=83; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries

- [x] G7: the review report exists with build health, endpoint connectivity, workflow compliance, and severity-ranked remediation sections
  CHECK: node -e "const fs=require('fs');const f='docs/audits/build-endpoint-workflow-review.md';let t;try{t=fs.readFileSync(f,'utf8')}catch(e){console.error('report unreadable');process.exit(1)}const need=['## 1. Build Health','## 2. Endpoint Connectivity','## 3. Workflow Compliance','## 4. Discrepancies','Critical','Major','Minor','Remediation','/api/v1/seeds'];const miss=need.filter(function(s){return t.indexOf(s)<0});if(miss.length){console.error('report missing: '+miss.join(' | '));process.exit(1)}console.log('REVIEW REPORT COMPLETE (all required sections present)')"
  EXPECT: REVIEW REPORT COMPLETE
  EVIDENCE: automatic-evidence=v1; definition-sha256=4dc58faf6f1deeba74e678baf07ac201e70b3506d2305cb7c83edaeaed8e1285; exit=0; EXPECT=matched; output-sha256=01b0aa707d5e8f8a6b469b8dc4bccf3365be04adc105a46681975488f9c668b2; output-bytes=55; shell=C:\WINDOWS\system32\cmd.exe; cwd=C:\Users\DELL\Downloads\Admin Mobile application build; path=495a6e37bf0a/32 entries
