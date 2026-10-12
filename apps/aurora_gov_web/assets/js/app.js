// ============================================================================
// AuroraGov Web Client Application
// ============================================================================

import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import MishkaComponents from "../vendor/mishka_components.js"

import Hooks from "./hooks"
import { setupToastListeners } from "./notifications"
import { setupConnectionListeners } from "./connection"

// ----------------------------------------------------------------------------
// 1. LiveSocket Configuration
// ----------------------------------------------------------------------------
const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    ...Hooks,
    ...MishkaComponents
  }
})

// ----------------------------------------------------------------------------
// 2. Navigation & Progress Bar
// ----------------------------------------------------------------------------
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })

window.addEventListener("phx:page-loading-start", _info => {
  topbar.show(300)
  // Cerrar menú lateral en móvil/tablet al iniciar navegación
  document.documentElement.classList.remove("sidebar-open")
})

window.addEventListener("phx:page-loading-stop", info => {
  topbar.hide()
  // En móvil/tablet (< lg), reiniciar el scroll de la vista principal en navegaciones internas
  if (info.detail && info.detail.kind === "patch" && window.innerWidth < 1024) {
    const scrollEl = document.getElementById("panel-module-content") || document.getElementById("panel-main-content")
    if (scrollEl) {
      scrollEl.scrollTo(0, 0)
    } else {
      window.scrollTo(0, 0)
    }
  }
})

// ----------------------------------------------------------------------------
// 3. Subsystem Listeners & Socket Connection
// ----------------------------------------------------------------------------
setupToastListeners()
setupConnectionListeners(liveSocket)

liveSocket.connect()

window.liveSocket = liveSocket
