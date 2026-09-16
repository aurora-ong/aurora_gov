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

window.addEventListener("phx:toast", (e) => {
  showToast(e.detail.kind, e.detail.title, e.detail.msg);
});

function showToast(kind, title, msg) {
  let container = document.getElementById("toast-container");
  if (!container) {
    container = document.createElement("div");
    container.id = "toast-container";
    container.className = "fixed top-5 right-5 z-50 flex flex-col gap-3 w-80";
    document.body.appendChild(container);
  }
  
  const toast = document.createElement("div");
  toast.className = "transform transition-all duration-300 translate-y-[-10px] opacity-0 flex items-start p-4 rounded-lg shadow-lg border overflow-hidden relative cursor-pointer";
  
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
    colorClasses = "bg-blue-50 border-blue-200 text-blue-800";
  }
  
  toast.classList.add(...colorClasses.split(" "));
  
  const progressId = "prog-" + Math.random().toString(36).substr(2, 9);
  
  toast.innerHTML = `
    <div class="flex-shrink-0 mr-3 mt-0.5">
      ${icon}
    </div>
    <div class="flex-1">
      ${title && title !== "nil" ? "<h4 class=\"font-bold text-sm mb-1\">" + title + "</h4>" : ""}
      <p class="text-sm">${msg}</p>
    </div>
    <div class="absolute bottom-0 left-0 h-1 bg-black/10 w-full">
      <div id="${progressId}" class="h-full bg-black/20 w-full" style="transition: width 5s linear;"></div>
    </div>
  `;
  
  container.appendChild(toast);
  
  requestAnimationFrame(() => {
    toast.classList.remove("translate-y-[-10px]", "opacity-0");
    const progress = document.getElementById(progressId);
    if(progress) progress.style.width = "0%";
  });
  
  const removeToast = () => {
    toast.classList.add("opacity-0", "scale-95");
    setTimeout(() => toast.remove(), 300);
  };
  
  toast.addEventListener("click", removeToast);
  setTimeout(removeToast, 5000);
}
