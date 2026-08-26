// Module-scope singleton store for the MultiSlot pause-menu tab.
// This tab is an action panel over the existing generator (mirrors gmsg/ui.lua's 4 imgui
// tabs), not a live-tuning UI — mostly fire-and-forget button actions plus a small local
// edit buffer for the "Generate Standalone" form and a couple of dev-only Utils fields.
import { reactive } from "vue"
import { useBridge } from "@/bridge"
import luaApi from "./luaApi.js"

const toArray = v => (Array.isArray(v) ? v : v && typeof v === "object" ? Object.values(v) : [])

const state = reactive({
  ready: false,
  cfg: {},
  templates: [],
  loadedExtensions: [],
  busy: false,

  // "Generate Standalone" tab form (mirrors renderTabStandalone's local imgui state)
  standalone: {
    selectedTemplate: null,
    outputPath: "/unpacked/gmsg_out/",
    autopack: false,
    includeMStemplate: true,
    addDependencyDownloader: true,
  },

  // "Utils" tab (mirrors renderTabUtils's local imgui state)
  utils: {
    advancedMode: false,
    concurrencyDelay: 2 / 3,
    selectedExtension: "",
  },
})

function onState(s) {
  state.cfg = (s && s.cfg) || {}
  state.templates = toArray(s && s.templates)
  state.loadedExtensions = toArray(s && s.loadedExtensions)
  state.ready = true
  state.busy = false
  if (!state.standalone.selectedTemplate && state.templates.length) {
    state.standalone.selectedTemplate = state.templates[0]
  }
}

function run(action) {
  state.busy = true
  action()
}

// ── Generate Standalone ──
function generateSpecificMod() {
  const s = state.standalone
  if (!s.selectedTemplate) return
  run(() => luaApi.generateSpecificMod(s.selectedTemplate, s.outputPath, s.autopack, s.addDependencyDownloader, s.includeMStemplate))
}

// ── Generate Manually ──
function generateMultiSlot() { run(luaApi.generateMultiSlot) }
function generateMultiSlotConcurrent() { run(luaApi.generateMultiSlotConcurrent) }
function generateSeparate() { run(luaApi.generateSeparate) }
function generateSeparateConcurrent() { run(luaApi.generateSeparateConcurrent) }
function generateAdditionalToMultiSlot() { run(luaApi.generateAdditionalToMultiSlot) }
function generateAdditionalToMultiSlotConcurrent() { run(luaApi.generateAdditionalToMultiSlotConcurrent) }

// ── Settings ──
function setSetting(key, value) {
  state.cfg[key] = value
  luaApi.setModSettings({ [key]: value })
}

// ── Utils ──
function rescanTemplates() { run(luaApi.rescanTemplates) }
function reloadModDB() { luaApi.reloadModDB() }
function setConcurrencyDelay(delay) {
  state.utils.concurrencyDelay = delay
  luaApi.setConcurrencyDelay(delay)
}
function reloadGELua() { luaApi.reloadGELua() }
function reloadGmsgUI() { luaApi.reloadGmsgUI() }
function reloadGmsg() { luaApi.reloadGmsg() }
function reloadSelectedExtension() {
  if (state.utils.selectedExtension) luaApi.reloadExtension(state.utils.selectedExtension)
}
function loadDependencyInstallerUi() { luaApi.loadDependencyInstallerUi() }

let inited = false
let bridgeEvents = null

function init() {
  if (inited) return
  inited = true
  bridgeEvents = useBridge().events
  bridgeEvents.on("MultiSlotState", onState)
  luaApi.requestState()
}

function dispose() {
  if (!inited) return
  inited = false
  if (bridgeEvents) bridgeEvents.off("MultiSlotState", onState)
  bridgeEvents = null
}

export default {
  state,
  init,
  dispose,
  generateSpecificMod,
  generateMultiSlot,
  generateMultiSlotConcurrent,
  generateSeparate,
  generateSeparateConcurrent,
  generateAdditionalToMultiSlot,
  generateAdditionalToMultiSlotConcurrent,
  setSetting,
  rescanTemplates,
  reloadModDB,
  setConcurrencyDelay,
  reloadGELua,
  reloadGmsgUI,
  reloadGmsg,
  reloadSelectedExtension,
  loadDependencyInstallerUi,
}
