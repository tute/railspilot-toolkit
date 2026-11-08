// node sticky.mjs <config.json> <pageKey> <width> [tableSelector]
// Scrolls the largest scroller past the table and reports whether the header row stays pinned.
import fs from "node:fs"
import { connect, login, assertRole, setViewport, setScheme, seedStorage, settle } from "./cdp.mjs"

const [configPath, key, width, table = "table"] = process.argv.slice(2)
const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"))
const cdp = await connect(cfg.port || 9334)
await setViewport(cdp, +width, 900)
if (cfg.login) await login(cdp, cfg.host, cfg.login)
await seedStorage(cdp, cfg.localStorage)
await setScheme(cdp, process.env.SCHEME || "light", cfg.scheme || {})
await cdp.go(cfg.host + cfg.pages[key])
await settle(cdp, cfg.settle || {})
await assertRole(cdp, cfg.login?.assert)
console.log(await cdp.evaluate(`(async () => {
  const t = [...document.querySelectorAll(${JSON.stringify(table)})].filter(e => e.getBoundingClientRect().height > 0).sort((a, b) => b.querySelectorAll("tbody tr").length - a.querySelectorAll("tbody tr").length)[0]
  if (!t) return { error: "no table" }
  const all = [...document.querySelectorAll("*")].filter(e => e.scrollHeight > e.clientHeight + 20 && /(auto|scroll)/.test(getComputedStyle(e).overflowY))
  const sc = all.sort((a, b) => b.scrollHeight - a.scrollHeight)[0] || document.scrollingElement
  sc.scrollTop += t.getBoundingClientRect().top + 400
  await new Promise(r => setTimeout(r, 600))
  const th = t.querySelector("thead th").getBoundingClientRect()
  const tableTop = Math.round(t.getBoundingClientRect().top)
  return JSON.stringify({ rows: t.querySelectorAll("tbody tr").length, scroller: sc.id || sc.tagName, tableTop, thTop: Math.round(th.top), pinned: th.top >= 0 && th.top > tableTop })
})()`))
await cdp.close()
