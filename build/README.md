# Build the patched host bundle

The runtime loads `lib/index.js`; editing `src/` alone changes nothing until you rebuild it.

## Prerequisites

```bash
cd build
npm install          # esbuild 0.25.9 + the three devDeps the upstream build needs
```

`@larksuiteoapi/node-sdk`, `@whiskeysockets/baileys`, `react` and `react-dom` are bundled into the
host bundle, so they must be resolvable at build time. They are listed in `package.json` here.

## Build

```bash
# point at the installed (already patched) package
DSH_IM_PKG_DIR="$HOME/.dsh/profiles/web/node_modules/@xmanrui/dsh-im" node build.mjs
```

The script mirrors the upstream `plugin-src/host/build.mjs` options: ESM bundle for Node 22, the same
external list, the same banner, minified, `legalComments: eof`.

## Verify

```bash
node --input-type=module -e "import('file:///…/lib/index.js').then(m => console.log(Object.keys(m)))"
# expect: [ 'apply', 'createImHostPlugin', 'inject', 'name' ]
```
