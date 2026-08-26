// Thin wrappers around the tommot_gmsg_pauseui GE extension's API
// (lua/ge/extensions/tommot/gmsg/pauseui.lua). Fire-and-forget; results come back
// through the guihooks "MultiSlotState" event handled in store.js.
import { useBridge } from "@/bridge"
import { runRaw } from "@/bridge/libs/Lua"

const EXT = "extensions.tommot_gmsg_pauseui."

function ser(v) {
  const { api } = useBridge()
  return api.serializeToLua(v === undefined ? null : v)
}

function call(fn, ...args) {
  runRaw(EXT + fn + "(" + args.map(ser).join(", ") + ")", false)
}

export default {
  requestState: () => call("requestState"),

  // Generate Standalone
  generateSpecificMod: (templateName, outputPath, autoPack, addDependencyDownloader, includeMStemplate) =>
    call("generateSpecificMod", templateName, outputPath, !!autoPack, !!addDependencyDownloader, !!includeMStemplate),

  // Generate Manually
  generateMultiSlot: () => call("generateMultiSlot"),
  generateMultiSlotConcurrent: () => call("generateMultiSlotConcurrent"),
  generateSeparate: () => call("generateSeparate"),
  generateSeparateConcurrent: () => call("generateSeparateConcurrent"),
  generateAdditionalToMultiSlot: () => call("generateAdditionalToMultiSlot"),
  generateAdditionalToMultiSlotConcurrent: () => call("generateAdditionalToMultiSlotConcurrent"),

  // Settings
  setModSettings: json => call("setModSettings", JSON.stringify(json)),
  resetSettingsToDefaults: () => call("resetSettingsToDefaults"),

  // Utils
  rescanTemplates: () => call("rescanTemplates"),
  reloadModDB: () => call("reloadModDB"),
  clearCache: () => call("clearCache"),
  setConcurrencyDelay: delay => call("setConcurrencyDelay", delay),
  reloadGELua: () => call("reloadGELua"),
  reloadGmsgUI: () => call("reloadGmsgUI"),
  reloadGmsg: () => call("reloadGmsg"),
  reloadExtension: extName => call("reloadExtension", extName),
  loadDependencyInstallerUi: () => call("loadDependencyInstallerUi"),
}
