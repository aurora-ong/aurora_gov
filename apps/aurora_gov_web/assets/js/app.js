// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import MishkaComponents from "../vendor/mishka_components.js";

let Hooks = {}

Hooks.Tippy = {
  mounted() {
    tippy(this.el, {
      content: this.el.dataset.tippyContent,
      placement: this.el.dataset.tippyPlacement || 'top',
      theme: this.el.dataset.tippyTheme || undefined
    })
  }
}

Hooks.FlashToast = {
  mounted() { this.triggerToast() },
  updated() { this.triggerToast() },
  triggerToast() {
    const msg = this.el.innerText.trim();
    if(msg) {
      showToast(this.el.dataset.kind, this.el.dataset.title, msg);
      this.pushEvent("lv:clear-flash", {key: this.el.dataset.kind});
    }
  }
}

Hooks.ConnectionToast = {
  disconnected() { showToast("error", "Sin conexión", "Intentando reconectar...") },
  reconnected() { showToast("success", null, "Conexión restablecida.") }
}

Hooks.TableSelection = {
  mounted() { this.updateSelection() },
  updated() { this.updateSelection() },
  updateSelection() {
    const selectedId = this.el.dataset.selectedId;
    this.el.querySelectorAll('tr').forEach(tr => {
      if (tr.id === selectedId) {
        tr.classList.add("bg-blue-50/50");
        tr.classList.remove("hover:bg-gray-50");
        tr.style.boxShadow = "inset 4px 0 0 0 #FF5E00";
      } else {
        tr.classList.remove("bg-blue-50/50");
        tr.classList.add("hover:bg-gray-50");
        tr.style.boxShadow = "none";
      }
    });
  }
}

Hooks.InfiniteScroll = {
  mounted() {
    this.observer = new IntersectionObserver(entries => {
      const entry = entries[0];
      if (entry.isIntersecting) {
        this.pushEventTo(this.el, "load_more", {});
      }
    }, {
      root: null,
      rootMargin: "0px 0px 100px 0px",
      threshold: 0
    });

    this.observer.observe(this.el);
  },
  updated() {
    if (this.observer) {
      this.observer.unobserve(this.el);
      this.observer.observe(this.el);
    }
  },
  destroyed() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    ...Hooks,
    ...MishkaComponents
  }
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


  window.addEventListener("phx:toast", (e) => {
    showToast(e.detail.kind, e.detail.title, e.detail.msg, e.detail.icon);
  });

function showToast(kind, title, msg, customIcon) {
  let container = document.getElementById("toast-container");
  if (!container) {
    container = document.createElement("div");
    container.id = "toast-container";
    container.className = "fixed bottom-5 right-5 z-50 flex flex-col gap-3 w-80";
    document.body.appendChild(container);
  }
  
  const toast = document.createElement("div");
  toast.className = "transform transition-all duration-300 translate-y-[10px] opacity-0 flex items-start p-4 rounded-lg shadow-lg border overflow-hidden relative cursor-pointer";
  
  let icon = "";
  let colorClasses = "";
  
  if (kind === "error") {
    icon = "<i class=\"fa-solid fa-circle-exclamation text-xl\"></i>";
    colorClasses = "bg-rose-50 border-rose-200 text-rose-800";
  } else if (kind === "success") {
    icon = "<i class=\"fa-solid fa-circle-check text-xl\"></i>";
    colorClasses = "bg-emerald-50 border-emerald-200 text-emerald-800";
  } else {
    icon = "<i class=\"fa-solid fa-circle-info text-xl\"></i>";
    colorClasses = "bg-[#F2F8FE] border-aurora_blue_light/30 text-aurora_blue";
  }
  
  if (customIcon && /^fa-[a-z0-9-]+$/.test(customIcon)) {
    icon = "<i class=\"fa-solid " + customIcon + " text-xl\"></i>";
  }
  
  toast.classList.add(...colorClasses.split(" "));
  toast.setAttribute("role", kind === "error" ? "alert" : "status");
  
  const progressId = "prog-" + Math.random().toString(36).substr(2, 9);
  
  toast.innerHTML = `
    <div class="flex-shrink-0 mr-3 mt-0.5">
      ${icon}
    </div>
    <div class="flex-1">
      ${title && title !== "nil" ? "<h4 class=\"font-bold text-sm mb-1\"></h4>" : ""}
      <p class="text-sm"></p>
    </div>
    <button type="button" aria-label="Cerrar" class="flex-shrink-0 ml-3 opacity-50 hover:opacity-100">
      <i class="fa-solid fa-xmark"></i>
    </button>
    <div class="absolute bottom-0 left-0 h-1 bg-black/10 w-full">
      <div id="${progressId}" class="h-full bg-black/20 w-full" style="transition: width 5s linear;"></div>
    </div>
  `;
  
  if (title && title !== "nil") toast.querySelector("h4").textContent = title;
  toast.querySelector("p").textContent = msg;
  
  while (container.children.length >= 4) container.firstElementChild.remove();
  container.appendChild(toast);
  
  requestAnimationFrame(() => {
    toast.classList.remove("translate-y-[10px]", "opacity-0");
    const progress = document.getElementById(progressId);
    if(progress) progress.style.width = "0%";
  });
  
  let remaining = 5000;
  let start = Date.now();
  let timer;
  
  const removeToast = () => {
    clearTimeout(timer);
    toast.classList.add("opacity-0", "scale-95");
    setTimeout(() => toast.remove(), 300);
  };
  
  toast.addEventListener("mouseenter", () => {
    clearTimeout(timer);
    remaining -= Date.now() - start;
    const progress = document.getElementById(progressId);
    if(progress) {
      progress.style.transition = "none";
      progress.style.width = (remaining / 50) + "%";
    }
  });
  
  toast.addEventListener("mouseleave", () => {
    start = Date.now();
    timer = setTimeout(removeToast, remaining);
    const progress = document.getElementById(progressId);
    if(progress) {
      progress.style.transition = "width " + remaining + "ms linear";
      progress.style.width = "0%";
    }
  });
  
  toast.addEventListener("click", removeToast);
  timer = setTimeout(removeToast, remaining);
}
