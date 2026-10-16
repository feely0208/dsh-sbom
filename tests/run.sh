#!/bin/bash
# 双向验证：正例必须报，反例必须不报（误报是安全工具的头号杀手）
set -uo pipefail
export PATH="/usr/local/bin:$PATH"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
ok(){ echo "  ✅ $1"; PASS=$((PASS+1)); }
bad(){ echo "  ❌ $1"; FAIL=$((FAIL+1)); }

echo ""; echo "  $(node -p "require('./package.json').name") · 双向验证"
echo "  ────────────────────────────────────────────────"

echo ""; echo "  【样本】时效判据看的是文件修改时间，而 git 不保存 mtime —— 必要时回拨"
STALE_F=tests/fixtures/fail/demo-project/docs/deps.cdx.json
if [ -f "$STALE_F" ]; then
  OLD=$(python3 -c "import os,time;print(1 if (time.time()-os.path.getmtime('$STALE_F'))/86400>180 else 0)" 2>/dev/null)
  if [ "${OLD:-0}" = "1" ]; then
    ok "过期样本 mtime 正常（已超过 180 天）"
  else
    touch -t 202403110820 "$STALE_F" && ok "过期样本 mtime 被重置过，已回拨到 2024-03-11" || bad "无法回拨 $STALE_F 的修改时间"
  fi
else
  bad "缺过期样本：$STALE_F"
fi

echo ""; echo "  【正例】tests/fixtures/fail/demo-project（每条判据都必须报出）"
J=$(node bin/cli.mjs --root tests/fixtures/fail/demo-project --json 2>&1)
for rid in SBOM-EMPTY-SHELL SBOM-NOT-STANDARD SBOM-STALE SBOM-NO-IDENTIFIER; do
  c=$(echo "$J" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(len([f for f in d.get('findings',[]) if f.get('ruleId')=='$rid']))
except Exception: print(0)" 2>/dev/null)
  [ "${c:-0}" -gt 0 ] && ok "$rid 报出（$c 处）" || bad "$rid 未报出"
done

echo ""; echo "  【正例·absence】tests/fixtures/absent/minimal（有 lockfile、没有任何 SBOM）"
A=$(node bin/cli.mjs --root tests/fixtures/absent/minimal --json 2>&1)
c=$(echo "$A" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(len([f for f in d.get('findings',[]) if f.get('ruleId')=='SBOM-NO-LIST']))
except Exception: print(0)" 2>/dev/null)
[ "${c:-0}" -gt 0 ] && ok "SBOM-NO-LIST 报出（$c 处）" || bad "SBOM-NO-LIST 未报出"
n=$(echo "$A" | python3 -c "
import json,sys
try:
    print(len(json.load(sys.stdin).get('findings',[])))
except Exception: print(-1)" 2>/dev/null)
[ "${n:-1}" = "1" ] && ok "该样本只报 1 条（没有 SBOM 时不会误报其它判据）" || bad "该样本报了 ${n} 条，除 absence 外还有误报"

echo ""; echo "  【反例】tests/fixtures/pass/clean-project（必须 0 命中）"
M=$(node bin/cli.mjs --root tests/fixtures/pass/clean-project --quiet 2>&1 | grep -oE '^[0-9]+' | head -1)
[ "${M:-1}" = "0" ] && ok "干净样本 0 命中" || bad "误报 ${M} 条"

echo ""; echo "  【覆盖率】每种格式都要有样本，否则正则的某个分支是死的"
for f in tests/fixtures/pass/clean-project/sbom.json \
         tests/fixtures/pass/clean-project/bom.xml \
         tests/fixtures/pass/clean-project/spdx/sbom.spdx.json \
         tests/fixtures/fail/demo-project/sbom.json \
         tests/fixtures/fail/demo-project/bom.json \
         tests/fixtures/fail/demo-project/security/bom.xml \
         tests/fixtures/fail/demo-project/docs/deps.cdx.json; do
  [ -f "$f" ] && ok "样本存在：$f" || bad "缺样本：$f"
done

echo ""; echo "  【回归】SBOM 文件名 glob 必须覆盖多级目录与多种命名"
G=$(node --input-type=module -e "
import { globToRe } from '@deepwhale-cn/dsh-guard-core';
const cases=[
  ['**/sbom.json','sbom.json',true],
  ['**/sbom.json','a/b/sbom.json',true],
  ['**/bom.json','security/bom.xml',false],
  ['**/*.cdx.json','docs/deps.cdx.json',true],
  ['**/*.spdx.json','spdx/sbom.spdx.json',true],
  ['**/bom.xml','bom.xml',true],
  ['**/*.cdx.xml','x/y.cdx.xml',true],
];
let bad=0; for(const [g,p,w] of cases) if(globToRe(g).test(p)!==w){bad++;console.error('FAIL',g,p);}
console.log(bad);" 2>/dev/null)
[ "${G:-1}" = "0" ] && ok "glob 语义正确（多级目录 + 多命名）" || bad "glob 用例失败 ${G} 个"

echo ""; echo "  【溯源】每条规则必须带 source，且建议 ≥40 字"
python3 - <<'PY' && ok "全部规则均有 source 与 advice" || bad "有规则缺 source / advice 过短"
import json,glob,sys
bad=0
for f in sorted(glob.glob('rules/*.json')):
    r=json.load(open(f,encoding='utf-8'))
    if not r.get('source'): print('缺 source:',r.get('id'),file=sys.stderr); bad+=1
    if len(r.get('advice') or '')<40: print('advice 过短:',r.get('id'),file=sys.stderr); bad+=1
sys.exit(1 if bad else 0)
PY

echo ""; echo "  ────────────────────────────────────────────────"
echo "  通过 $PASS · 失败 $FAIL"; echo ""
[ "$FAIL" -eq 0 ] || exit 1
