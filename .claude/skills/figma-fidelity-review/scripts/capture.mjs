// node capture.mjs <config.json> <outdir> [pageKey,...]
// Full-page PNGs per page x width x scheme, plus console/uncaught errors in <outdir>/errors.json.
import fs from "node:fs"
import { connect, login, assertRole, setViewport, setScheme, seedStorage, settle, fullPage } from "./cdp.mjs"

const [configPath, OUT, only] = process.argv.slice(2)
const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"))
const widths = (process.env.WIDTHS || cfg.widths.join(",")).split(",").map(Number)
const schemes = (process.env.SCHEMES || (cfg.schemes || ["light", "dark"]).join(",")).split(",")
fs.mkdirSync(OUT, { recursive: true })
const ignore = (cfg.ignoreErrors || []).map((p) => new RegExp(p))

const cdp = await connect(cfg.port || 9334)
await setViewport(cdp, 1536)
if (cfg.login) console.log("login:", await login(cdp, cfg.host, cfg.login))

const errorLog = fs.existsSync(`${OUT}/errors.json`) ? JSON.parse(fs.readFileSync(`${OUT}/errors.json`, "utf8")) : {}
for (const [key, path] of Object.entries(cfg.pages)) {
  if (only && !only.split(",").includes(key)) continue
  for (const width of widths) {
    for (const scheme of schemes) {
      cdp.errors.length = 0
      await setViewport(cdp, width)
      await setScheme(cdp, scheme, cfg.scheme || {})
      await seedStorage(cdp, cfg.localStorage)
      await cdp.go(cfg.host + path)
      await settle(cdp, cfg.settle || {})
      await assertRole(cdp, cfg.login?.assert)
      const { png, height } = await fullPage(cdp, width, { remove: cfg.remove || [] })
      const file = `${OUT}/${key}-${width}-${scheme}.png`
      fs.writeFileSync(file, png)
      const info = await cdp.evaluate(`JSON.stringify({ url: location.pathname, title: document.title, h: ${height}${cfg.probe ? ", probe: (" + cfg.probe + ")()" : ""} })`)
      const errs = cdp.errors.filter((e) => !ignore.some((re) => re.test(e)))
      errorLog[`${key}-${width}-${scheme}`] = errs
      console.log(file, info, errs.length ? `ERRORS ${errs.length}` : "")
    }
  }
}
fs.writeFileSync(`${OUT}/errors.json`, JSON.stringify(errorLog, null, 2))
await cdp.close()
