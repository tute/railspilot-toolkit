// node probe.mjs <config.json> <pageKey> <width> <js-expression>
// Evaluates an expression on the page (computed styles, overflow, focus order) and prints the JSON result.
import fs from "node:fs"
import { connect, login, assertRole, setViewport, setScheme, seedStorage, settle } from "./cdp.mjs"

const [configPath, key, width, expr] = process.argv.slice(2)
const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"))
const cdp = await connect(cfg.port || 9334)
await setViewport(cdp, +width, 1000)
if (cfg.login) await login(cdp, cfg.host, cfg.login)
await seedStorage(cdp, cfg.localStorage)
await setScheme(cdp, process.env.SCHEME || "light", cfg.scheme || {})
await cdp.go(cfg.host + cfg.pages[key])
await settle(cdp, cfg.settle || {})
await assertRole(cdp, cfg.login?.assert)
console.log(JSON.stringify(await cdp.evaluate(expr), null, 2))
const errs = cdp.errors.filter((e) => !(cfg.ignoreErrors || []).some((p) => new RegExp(p).test(e)))
if (errs.length) console.log("console errors:", errs)
await cdp.close()
