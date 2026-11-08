const [,, fileKey, nodeId, name, outDir] = process.argv;
const tabs = await (await fetch('http://localhost:9333/json')).json();
const tab = tabs.find(t => t.type === 'page' && t.url.includes('figma.com'));
const ws = new WebSocket(tab.webSocketDebuggerUrl);
let id = 0; const pending = new Map();
ws.onmessage = e => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } };
await new Promise(r => ws.onopen = r);
const send = (method, params = {}) => new Promise(r => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const sleep = ms => new Promise(r => setTimeout(r, ms));
const ev = async expr => (await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true })).result?.result?.value;
await send('Emulation.setFocusEmulationEnabled', { enabled: true });
await send('Browser.setDownloadBehavior', { behavior: 'allow', downloadPath: outDir, eventsEnabled: true });
await send('Page.navigate', { url: `https://www.figma.com/design/${fileKey}/x?node-id=${nodeId}` });
for (let i = 0; i < 60; i++) { await sleep(1000); if (await ev(`!!document.querySelector('canvas') && [...document.querySelectorAll('[role=tab],button')].some(b=>/^(Properties|Design)$/.test(b.textContent.trim()))`)) break; }
await sleep(4000);
console.log('title', await ev('document.title'));
await ev(`(()=>{const t=[...document.querySelectorAll('[role=tab],button')].find(b=>/^(Properties|Design)$/.test(b.textContent.trim())); t&&t.click(); return !!t})()`);
await sleep(1500);
const findExport = `[...document.querySelectorAll('button,[role=button]')].find(b=>/^Export /.test(b.textContent.trim()))`;
let has = await ev(`!!${findExport}`);
if (!has) { await ev(`document.querySelector('[aria-label="Add export settings"]')?.click()`); await sleep(1500); has = await ev(`!!${findExport}`); }
console.log('exportBtn', has, await ev(`${findExport}?.textContent.trim()`));
await ev(`${findExport}?.click()`);
await sleep(15000);
ws.close(); process.exit(0);
