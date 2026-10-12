// ============================================================================
// Toast Notification System
// ============================================================================

export function showToast(kind, title, msg, customIcon) {
  let container = document.getElementById("toast-container")
  if (!container) {
    container = document.createElement("div")
    container.id = "toast-container"
    container.className = "fixed bottom-5 right-5 z-50 flex flex-col gap-3 w-80"
    document.body.appendChild(container)
  }

  const toast = document.createElement("div")
  toast.className =
    "transform transition-all duration-300 translate-y-[10px] opacity-0 flex items-start p-4 rounded-lg shadow-lg border overflow-hidden relative cursor-pointer"

  let icon = ""
  let colorClasses = ""

  if (kind === "error") {
    icon = '<i class="fa-solid fa-circle-exclamation text-xl"></i>'
    colorClasses = "bg-rose-50 border-rose-200 text-rose-800"
  } else if (kind === "success") {
    icon = '<i class="fa-solid fa-circle-check text-xl"></i>'
    colorClasses = "bg-emerald-50 border-emerald-200 text-emerald-800"
  } else {
    icon = '<i class="fa-solid fa-circle-info text-xl"></i>'
    colorClasses = "bg-[#F2F8FE] border-aurora_blue_light/30 text-aurora_blue"
  }

  if (customIcon && /^fa-[a-z0-9-]+$/.test(customIcon)) {
    icon = `<i class="fa-solid ${customIcon} text-xl"></i>`
  }

  toast.classList.add(...colorClasses.split(" "))
  toast.setAttribute("role", kind === "error" ? "alert" : "status")

  const progressId = "prog-" + Math.random().toString(36).substr(2, 9)

  toast.innerHTML = `
    <div class="flex-shrink-0 mr-3 mt-0.5">
      ${icon}
    </div>
    <div class="flex-1">
      ${title && title !== "nil" ? '<h4 class="font-bold text-sm mb-1"></h4>' : ""}
      <p class="text-sm"></p>
    </div>
    <button type="button" aria-label="Cerrar" class="flex-shrink-0 ml-3 opacity-50 hover:opacity-100">
      <i class="fa-solid fa-xmark"></i>
    </button>
    <div class="absolute bottom-0 left-0 h-1 bg-black/10 w-full">
      <div id="${progressId}" class="h-full bg-black/20 w-full" style="transition: width 5s linear;"></div>
    </div>
  `

  if (title && title !== "nil") toast.querySelector("h4").textContent = title
  toast.querySelector("p").textContent = msg

  while (container.children.length >= 4) {
    container.firstElementChild.remove()
  }
  container.appendChild(toast)

  requestAnimationFrame(() => {
    toast.classList.remove("translate-y-[10px]", "opacity-0")
    const progress = document.getElementById(progressId)
    if (progress) progress.style.width = "0%"
  })

  let remaining = 5000
  let start = Date.now()
  let timer

  const removeToast = () => {
    clearTimeout(timer)
    toast.classList.add("opacity-0", "scale-95")
    setTimeout(() => toast.remove(), 300)
  }

  toast.addEventListener("mouseenter", () => {
    clearTimeout(timer)
    remaining -= Date.now() - start
    const progress = document.getElementById(progressId)
    if (progress) {
      progress.style.transition = "none"
      progress.style.width = remaining / 50 + "%"
    }
  })

  toast.addEventListener("mouseleave", () => {
    start = Date.now()
    timer = setTimeout(removeToast, remaining)
    const progress = document.getElementById(progressId)
    if (progress) {
      progress.style.transition = "width " + remaining + "ms linear"
      progress.style.width = "0%"
    }
  })

  toast.addEventListener("click", removeToast)
  timer = setTimeout(removeToast, remaining)
}

export function setupToastListeners() {
  window.addEventListener("phx:toast", e => {
    showToast(e.detail.kind, e.detail.title, e.detail.msg, e.detail.icon)
  })
}
