# @deepwhale-cn/dsh-sbom

**你的产物里到底有谁，清单说了算。**

**关键词**：软件物料清单 · SBOM · 供应链安全 · CycloneDX · SPDX · 依赖透明 · 行政令 14028 · NTIA 最低要素

---

## 先说清楚它是什么、不是什么

**是**：检查一个项目的 SBOM —— **有没有、全不全、新不新、格式对不对**。
有 lockfile 却一份清单都没有、清单是个空壳、文件名叫 `bom.json` 却不是标准格式、
清单一整年没更新、组件没有 `purl` 唯一标识 —— 这些它都会指出来。

**不是**：
- ❌ **不是 SBOM 生成器** —— 它**不生成**清单，只检查已有的清单（生成是 cyclonedx-npm / syft / spdx-sbom-generator 的活）
- ❌ **不是漏洞扫描器** —— 不查 CVE，那是 `dsh-dep-audit` 的活
- ❌ **不做许可证合规判定** —— 只关心「清单里有没有写清谁是谁」
- ❌ **不下「合规 / 不合规」的结论** —— 只描述事实，判断留给你

**一句话分界**：**别的工具负责写清单，它负责查清单。**

```
dsh-dep-audit  = 查【依赖树】里的漏洞与许可证
dsh-sbom       = 查【物料清单】本身有没有、全不全、新不新
```

---

## 它查什么（5 条）

| 规则 | 查什么 | 级别 |
|---|---|---|
| `SBOM-NO-LIST` | 有 lockfile，却找不到任何 SBOM 文件（absence）| 🔴 |
| `SBOM-EMPTY-SHELL` | SBOM 在，但里面没有任何组件条目 —— 空壳 | 🔴 |
| `SBOM-NOT-STANDARD` | 没有 `bomFormat` / `spdxVersion`，下游工具没法消费 | 🔴 |
| `SBOM-STALE` | SBOM 超过 180 天没更新 | 🟡 |
| `SBOM-NO-IDENTIFIER` | 组件只有名字和版本，没有 `purl` / `CPE` | 🔵 |

**每条都会给出：哪个文件、什么证据、依据是什么、怎么办。**

### 认哪些文件名

`sbom.json` · `bom.json` · `*.cdx.json` · `*.spdx.json` · `*.sbom.json` · `cyclonedx.json` ·
`bom.xml` · `sbom.xml` · `*.cdx.xml` · `*.spdx`（可放在任意子目录）

### 认哪些格式

**CycloneDX**（JSON / XML）· **SPDX**（JSON / tag-value）

### 出处

- 美国行政令 14028《改善国家网络安全》第 4(e) 条
- NTIA《SBOM Minimum Elements》（Components / Component Identifier / Timestamp 等最低要素）
- CycloneDX 规范 / SPDX 规范的官方文档

---

## 安装

```bash
dsh plugin --profile web add @deepwhale-cn/dsh-sbom
```

## 用法

```bash
# 检查当前项目
dsh-sbom

# 检查指定目录
dsh-sbom --root /path/to/project

# 看内置演示（一个「有 lockfile、清单却各种残缺」的样本项目）
dsh-sbom --demo

# 列出判据与出处
dsh-sbom --list-rules

# 出 HTML 报告（可截图存档）
dsh-sbom --root /path/to/project --html sbom.html

# 给 CI 用：有 high 命中时退出码 1
dsh-sbom --root . --quiet
```

---

## 一个真实的例子

`--demo` 那个样本项目，看起来挺正常：有 `package.json`、有 `package-lock.json`、有 CI，
`npm run sbom` 脚本也在。仓库里甚至有四份「清单」：

```
sbom.json              导出脚本生成的，但 components 是空的
bom.json               其实是 npm ls --json 导出后改的名
security/bom.xml       内部库存系统导出的 XML，不是 CycloneDX
docs/deps.cdx.json     一年多前导出的老清单，组件没有 purl
```

工具会把它们一条条拎出来：

```
🔴 SBOM 文件里没有组件条目 —— 清单是个空壳        sbom.json / bom.json / security/bom.xml
🔴 SBOM 文件不是标准格式 —— 没有格式标识          bom.json / security/bom.xml
🟡 SBOM 文件超过 180 天没更新                     docs/deps.cdx.json（949 天）
🔵 SBOM 里的组件没有唯一标识（purl / CPE）        docs/deps.cdx.json / sbom.json / …
```

而「有 lockfile 却一份清单都没有」这种项目（`tests/fixtures/absent/minimal`）会报：

```
🔴 有依赖清单却没有物料清单 —— 项目里找不到任何 SBOM 文件
```

**「有清单」和「有一份能用的清单」是两件事**，这个工具查的就是后者。

---

## 边界

- **不生成清单** —— 只检查；生成请用 cyclonedx-npm / syft / spdx-sbom-generator
- **只看清单文件本身** —— 不读产物二进制、不递归进依赖树、不查 CVE
- **不判定合规** —— 报出来是提示确认。清单在发布流水线里临时生成、不进仓库，
  在很多团队是正常做法；工具会照报，需要你自己说明
- **有扫描盲区** —— `dist/` `build/` `node_modules/` 等目录默认跳过，清单若只存在于
  这些目录，会被报成「找不到」；如果清单放在别处且命名不同，也可能漏认
- **时效判断用文件修改时间** —— 如果文件被重新 checkout 过，`SBOM-STALE` 可能不报或误报

---

## 开发

```bash
bash tests/run.sh        # 双向验证：正例全报 + 反例 0 命中
```

> `SBOM-STALE` 看的是**文件修改时间**，而 git 不保存 mtime。如果 `docs/deps.cdx.json`
> 的修改时间被重置（重新 checkout、拷贝目录），这条判据在正例上就报不出来 ——
> `tests/run.sh` 会自动回拨，手动修复用：
> `touch -t 202403110820 tests/fixtures/fail/demo-project/docs/deps.cdx.json`

样本目录（同时是 `--demo` 的数据源，没有第二套）：

```
tests/fixtures/fail/demo-project/     正例：清单空壳 / 非标准格式 / 过期 / 无标识
tests/fixtures/absent/minimal/        正例·absence：有 lockfile、没有任何 SBOM
tests/fixtures/pass/clean-project/    反例：CycloneDX JSON+XML、SPDX JSON 三种格式都合规
```

---

## License

MIT © 深鲸 DeepWhale
