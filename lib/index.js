import { createPlugin, pkgRootFrom } from '@deepwhale-cn/dsh-guard-core/plugin';

export const { name, inject, apply } = createPlugin({
  name: 'sbom',
  pkgRoot: pkgRootFrom(import.meta.url),
  skillFile: 'skill/sbom.md',
  binFile: 'bin/cli.mjs',
  description: '你的产物里到底有谁，清单说了算',
  whenToUse: '要确认一个项目「有没有 SBOM、全不全、新不新、格式对不对」时用。'
    + '用户会说：「我这个项目有 SBOM 吗」「清单是不是过期了」「SBOM 怎么生成才合规」'
    + '「供应链安全要交的物料清单齐不齐」「这个 bom.json 能用吗」。'
    + '注意：它只检查清单，不负责生成清单。',
});
