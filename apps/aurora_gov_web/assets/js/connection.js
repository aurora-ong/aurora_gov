// ============================================================================
// Connection Status Management
// ============================================================================

export function updateConnectionUI(connected) {
  const connectedEl = document.getElementById("connection-status-connected")
  const disconnectedEl = document.getElementById("connection-status-disconnected")

  if (connected) {
    if (connectedEl) connectedEl.classList.remove("hidden")
    if (disconnectedEl) {
      disconnectedEl.classList.add("hidden")
      disconnectedEl.classList.remove("flex")
    }
  } else {
    if (connectedEl) connectedEl.classList.add("hidden")
    if (disconnectedEl) {
      disconnectedEl.classList.remove("hidden")
      disconnectedEl.classList.add("flex")
    }
  }
}

export function setupConnectionListeners(liveSocket) {
  liveSocket.getSocket().onOpen(() => updateConnectionUI(true))
  liveSocket.getSocket().onError(() => updateConnectionUI(false))
  liveSocket.getSocket().onClose(() => updateConnectionUI(false))
}
