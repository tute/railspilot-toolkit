export async function connect(port, url = "about:blank", { keepOpen = false, reuse = false } = {}) {
  const target = reuse
    ? (await (await fetch(`http://127.0.0.1:${port}/json`)).json()).find((t) => t.type === "page")
    : await (await fetch(`http://127.0.0.1:${port}/json/new?${url}`, { method: "PUT" })).json()
  const ws = new WebSocket(target.webSocketDebuggerUrl.replace(/localhost:\d+|127\.0\.0\.1:\d+/, `127.0.0.1:${port}`))
  await new Promise((r) => ws.addEventListener("open", r))
  let id = 0
  const pending = new Map()
  const listeners = []
  ws.addEventListener("message", (m) => {
    const msg = JSON.parse(m.data)
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id)
      pending.delete(msg.id)
      msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result)
    } else if (msg.method) listeners.forEach((l) => l(msg))
  })
  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const n = ++id
      pending.set(n, { resolve, reject })
      ws.send(JSON.stringify({ id: n, method, params }))
    })
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
  const evaluate = async (expression) =>
    (await send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true })).result?.value
  const on = (method, fn) => listeners.push((m) => m.method === method && fn(m.params))
  const waitLoad = () =>
    new Promise((r) => {
      const l = (m) => {
        if (m.method === "Page.loadEventFired") {
          listeners.splice(listeners.indexOf(l), 1)
          r()
        }
      }
      listeners.push(l)
    })
  const go = async (url) => {
    const p = waitLoad()
    await send("Page.navigate", { url })
    await p
  }
  const errors = []
  on("Runtime.exceptionThrown", (p) => errors.push(p.exceptionDetails?.exception?.description || p.exceptionDetails?.text))
  on("Runtime.consoleAPICalled", (p) => p.type === "error" && errors.push(p.args.map((a) => a.value || a.description).join(" ")))
  on("Log.entryAdded", (p) => p.entry.level === "error" && errors.push(`${p.entry.source}: ${p.entry.text} ${p.entry.url || ""}`))
  await send("Page.enable")
  await send("Runtime.enable")
  await send("Log.enable")
  const close = async () => {
    ws.close()
    if (!keepOpen) await fetch(`http://127.0.0.1:${port}/json/close/${target.id}`).catch(() => {})
  }
  return { send, evaluate, sleep, go, waitLoad, on, errors, close }
}

export async function login(cdp, host, { path, email, password, emailField, passwordField, assert }) {
  await cdp.send("Network.clearBrowserCookies")
  await cdp.go(host + path)
  const form = `input[name="${emailField}"]`
  if (await cdp.evaluate(`!document.querySelector('${form}')`)) throw new Error("still signed in after clearing cookies; the host may not be the one the session cookie is on")
  await cdp.evaluate(`(() => {
    const e = document.querySelector('${form}'); e.value = ${JSON.stringify(email)};
    document.querySelector('input[name="${passwordField}"]').value = ${JSON.stringify(password)};
    e.form.submit() })()`)
  await cdp.waitLoad()
  await cdp.sleep(1500)
  if (await cdp.evaluate(`!!document.querySelector('${form}')`))
    throw new Error(`login failed, still on the sign-in form: ${await cdp.evaluate("document.body.innerText.slice(0, 300)")}`)
  return cdp.evaluate("location.href")
}

export async function assertRole(cdp, assert) {
  if (!assert) return
  if (!(await cdp.evaluate(`!!(${assert})`)))
    throw new Error(`role assertion failed on ${await cdp.evaluate("location.href")}: ${assert}`)
}

export async function scaleToWindow(cdp, width, height = 2400) {
  const win = JSON.parse(await cdp.evaluate("JSON.stringify({w: innerWidth, h: innerHeight})"))
  const scale = Math.min(1, win.w / width)
  await cdp.send("Emulation.setDeviceMetricsOverride", { width, height: Math.round(win.h / scale), deviceScaleFactor: 1, mobile: false, scale })
  return scale
}

export async function setViewport(cdp, width, height = 1000) {
  await cdp.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile: width < 768 })
}

export async function setScheme(cdp, scheme, { localStorageKey, emulateMedia }) {
  if (localStorageKey) await cdp.evaluate(`localStorage.setItem(${JSON.stringify(localStorageKey)}, ${JSON.stringify(scheme)})`)
  if (emulateMedia) await cdp.send("Emulation.setEmulatedMedia", { features: [{ name: "prefers-color-scheme", value: scheme }] })
}

export async function seedStorage(cdp, entries = {}) {
  for (const [k, v] of Object.entries(entries)) await cdp.evaluate(`localStorage.setItem(${JSON.stringify(k)}, ${JSON.stringify(v)})`)
}

export async function settle(cdp, { ready, busy, polls = 90, extraMs = 2500 }) {
  let done = false
  for (let i = 0; i < polls && !done; i++) {
    done = await cdp.evaluate(`(${JSON.stringify(ready || "true")} === "true" || !!document.querySelector(${JSON.stringify(ready || "body")})) && !document.querySelector(${JSON.stringify(busy || "turbo-frame[busy]")})`)
    if (!done) await cdp.sleep(500)
  }
  if (!done) console.error(`NOT SETTLED after ${polls / 2}s on ${await cdp.evaluate("location.href")}`)
  await cdp.sleep(extraMs)
  await cdp.evaluate(`(() => { const s = document.createElement("style"); s.textContent = "*{transition:none!important;animation:none!important;caret-color:transparent!important}"; document.head.appendChild(s) })()`)
  return done
}

export async function fullPage(cdp, width, { remove = [], maxHeight = 12000 } = {}) {
  if (remove.length) await cdp.evaluate(`document.querySelectorAll(${JSON.stringify(remove.join(","))}).forEach(e => e.remove())`)
  const height = await cdp.evaluate(`Math.max(...[document.documentElement, document.body, ...document.querySelectorAll('main, #main-content, [data-controller~="design-system-scrollport"]')].map(e => e.scrollHeight))`)
  await setViewport(cdp, width, Math.min(height, maxHeight))
  await cdp.sleep(800)
  const shot = await cdp.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: true })
  return { png: Buffer.from(shot.data, "base64"), height }
}
