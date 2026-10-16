# 软件物料清单检查（dsh-sbom）

**什么时候用**：想知道一个项目「有没有 SBOM、全不全、新不新、格式对不对」。
用户会说：「我有 SBOM 吗」「清单是不是过期了」「这个 bom.json 能用吗」「供应链安全要交的物料清单齐不齐」。

## 怎么用

```bash
<cli 路径> --root <项目目录>       # 检查一个项目
<cli 路径> --demo                  # 用内置样本看检出效果
<cli 路径> --list-rules            # 列出判据与出处
<cli 路径> --html sbom.html        # 出 HTML 报告（可截图存档）
```

## 它查什么

5 条判据，全部围绕「有没有、全不全、新不新、格式对不对」：

| 规则 | 查什么 |
|---|---|
| `SBOM-NO-LIST` | 有 lockfile，却找不到任何 SBOM 文件 |
| `SBOM-EMPTY-SHELL` | SBOM 在，但里面没有任何组件条目（空壳） |
| `SBOM-NOT-STANDARD` | 文件像 SBOM，却没有 `bomFormat` / `spdxVersion` 这类标准格式标识 |
| `SBOM-STALE` | SBOM 超过 180 天没更新 |
| `SBOM-NO-IDENTIFIER` | 组件只有名字和版本，没有 purl / CPE 唯一标识 |

覆盖的文件名：`sbom.json`、`bom.json`、`*.cdx.json`、`*.spdx.json`、`*.sbom.json`、
`cyclonedx.json`、`bom.xml`、`sbom.xml`、`*.cdx.xml`、`*.spdx` —— 支持 CycloneDX JSON/XML、
SPDX JSON、SPDX tag-value 四种编码。

## 怎么读结果

1. **先看扫描范围和「检查规则 N/M 条」**。如果 M 小于 5，说明有规则因为
   `when` 条件不适用而没跑（例如项目里没有 lockfile），报告里会写明是哪几条。
2. **命中 ≠ 违规**。它是提示你去确认，不是下结论。特别是：
   - `SBOM-NO-LIST`：很多团队在发布流水线里临时生成 SBOM、不提交进仓库 ——
     这不算错，但要在文档里写明，否则审计时拿不出东西。
   - `SBOM-STALE`：看着「仓库里有清单」，但可能已是旧版本的产物。
   - `SBOM-NO-IDENTIFIER`：如果组件确实只用了文档内 `bom-ref` / `SPDXID`，可忽略。
3. **不要把它当生成器**。它不生成 SBOM，只检查已有清单。

## 不要做什么

- 不要因为它报 `SBOM-NOT-STANDARD` 就去删那份自制清单 —— 先确认它是给谁看的
- 不要把它当唯一的合规证据 —— 它检查的是「清单本身」，不含漏洞、许可证结论
- 不要以为「全绿」就等于合规 —— SBOM 只是供应链透明的一项，验收还要看发布流程

## 相关插件

- `dsh-dep-audit` —— 查依赖树里的已知漏洞与许可证
- `dsh-tool-vet` —— 装一个第三方包之前，看它会动什么
