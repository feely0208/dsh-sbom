# acme-inventory-api

库存查询服务。`GET /stock/:sku` 返回各仓库存。

## 构建与发布

```bash
npm ci
npm start
```

## 依赖清单（SBOM）

仓库里有几份「清单」，质量参差不齐：

- `sbom.json` —— 由导出脚本生成，但 components 是空的
- `bom.json` —— 实际上是 `npm ls --json` 的导出，改了名字
- `security/bom.xml` —— 早先从内部库存系统导出的 XML
- `docs/deps.cdx.json` —— 一年多前导出的老清单

> 这个目录是 dsh-sbom 的演示样本，故意做成各种残缺，请勿当真。
