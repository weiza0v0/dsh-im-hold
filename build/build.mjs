import { build } from 'esbuild';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const pkg = process.env.DSH_IM_PKG_DIR
  || resolve(here, '../../../profiles/web/node_modules/@xmanrui/dsh-im');

const { larkSdkHandshakePatch } = await import(
  resolve(pkg, 'plugin-src/host/lark-sdk-handshake-patch.mjs')
);

const externalRuntimePackages = [
  '@tencent-connect/qqbot-connector',
  '@tencent-connect/qqbot-nodejs',
  '@wecom/aibot-node-sdk',
  'dingtalk-stream',
  'imapflow',
  'mailparser',
  'nodemailer',
  'qrcode',
  'sharp',
  'undici',
];
const external = externalRuntimePackages.flatMap((name) => [name, `${name}/*`]);

await build({
  entryPoints: [resolve(pkg, 'plugin-src/host/index.mjs')],
  bundle: true,
  format: 'esm',
  platform: 'node',
  target: ['node22'],
  mainFields: ['module', 'main'],
  nodePaths: [resolve(here, 'node_modules')],
  external,
  plugins: [larkSdkHandshakePatch],
  outfile: resolve(pkg, 'lib/index.js'),
  banner: {
    js: [
      "import { createRequire as __dshCreateRequire } from 'node:module';",
      "import { dirname as __dshDirname } from 'node:path';",
      "import { fileURLToPath as __dshFileURLToPath } from 'node:url';",
      'const require = __dshCreateRequire(import.meta.url);',
      'const __filename = __dshFileURLToPath(import.meta.url);',
      'const __dirname = __dshDirname(__filename);',
    ].join('\n'),
  },
  sourcemap: false,
  minify: true,
  legalComments: 'eof',
});

console.log(`Wrote ${resolve(pkg, 'lib/index.js')}`);
