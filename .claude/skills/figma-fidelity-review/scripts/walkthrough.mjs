// node walkthrough.mjs <config.json> <pageKey> <width> [scale|fit]
// HOLD=1 keeps the session open (device emulation is dropped the moment the
// CDP connection detaches), so run it in the background for a scaled/phone view.
// Puts the app tab of a VISIBLE Chrome (cfg.port) on one page at the frame's width,
// scaled to fit the window, logged in as cfg.login, so a person can compare it with
// the Figma frame beside it. Prints the role assertion result and the final URL.
import fs from "node:fs"
import { connect, login, assertRole, setScheme, seedStorage, settle, scaleToWindow } from "./cdp.mjs"

const [configPath, key, widthArg, scaleArg] = process.argv.slice(2)
const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"))
const width = Number(widthArg)
const cdp = await connect(cfg.port, "about:blank", { keepOpen: true, reuse: true })
await cdp.send("Emulation.clearDeviceMetricsOverride")
if (cfg.login) console.log("login:", await login(cdp, cfg.host, cfg.login))
await setScheme(cdp, process.env.SCHEME || "light", cfg.scheme || {})
await seedStorage(cdp, cfg.localStorage)
await cdp.go(cfg.host + cfg.pages[key])
await settle(cdp, cfg.settle || {})
await assertRole(cdp, cfg.login?.assert)
const scale = scaleArg && scaleArg !== "fit" ? Number(scaleArg) : await scaleToWindow(cdp, width)
if (scaleArg && scaleArg !== "fit") await cdp.send("Emulation.setDeviceMetricsOverride", { width, height: 2400, deviceScaleFactor: 1, mobile: width < 768, scale })
await cdp.evaluate("scrollTo(0, 0)")
console.log(JSON.stringify({ url: await cdp.evaluate("location.href"), width, scale, title: await cdp.evaluate("document.querySelector('h1')?.innerText") }))
if (process.env.HOLD) { console.log("holding the CDP session so the emulation survives; kill this process to release"); await new Promise(() => {}) }
await cdp.close()
