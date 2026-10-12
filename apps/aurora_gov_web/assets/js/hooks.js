// ============================================================================
// LiveView Hooks
// ============================================================================

import { updateConnectionUI } from "./connection"
import { showToast } from "./notifications"

const Hooks = {
  // Conexión LiveView: actualiza estado visual en el footer
  ConnectionStatus: {
    mounted() {
      updateConnectionUI(true)
    },
    disconnected() {
      updateConnectionUI(false)
    },
    reconnected() {
      updateConnectionUI(true)
    }
  },

  // Flashes de Phoenix mostrados como Toasts interactivos
  FlashToast: {
    mounted() {
      this.triggerToast()
    },
    updated() {
      this.triggerToast()
    },
    triggerToast() {
      const msg = this.el.innerText.trim()
      if (msg) {
        showToast(this.el.dataset.kind, this.el.dataset.title, msg)
        this.pushEvent("lv:clear-flash", { key: this.el.dataset.kind })
      }
    }
  },

  // Tooltips interactivos Tippy.js
  Tippy: {
    mounted() {
      if (typeof tippy === "function") {
        tippy(this.el, {
          content: this.el.dataset.tippyContent,
          placement: this.el.dataset.tippyPlacement || "top",
          theme: this.el.dataset.tippyTheme || undefined
        })
      }
    }
  },

  // Selección visual de fila en tablas
  TableSelection: {
    mounted() {
      this.updateSelection()
    },
    updated() {
      this.updateSelection()
    },
    updateSelection() {
      const selectedId = this.el.dataset.selectedId
      this.el.querySelectorAll("tr").forEach(tr => {
        if (tr.id === selectedId) {
          tr.classList.add("bg-blue-50/50")
          tr.classList.remove("hover:bg-gray-50")
          tr.style.boxShadow = "inset 4px 0 0 0 #FF5E00"
        } else {
          tr.classList.remove("bg-blue-50/50")
          tr.classList.add("hover:bg-gray-50")
          tr.style.boxShadow = "none"
        }
      })
    }
  },

  // Infinite scroll mediante IntersectionObserver
  InfiniteScroll: {
    mounted() {
      this.observer = new IntersectionObserver(
        entries => {
          const entry = entries[0]
          if (entry.isIntersecting) {
            this.pushEventTo(this.el, "load_more", {})
          }
        },
        { root: null, rootMargin: "0px 0px 100px 0px", threshold: 0 }
      )
      this.observer.observe(this.el)
    },
    updated() {
      if (this.observer) {
        this.observer.unobserve(this.el)
        this.observer.observe(this.el)
      }
    },
    destroyed() {
      if (this.observer) {
        this.observer.disconnect()
      }
    }
  }
}

export default Hooks
