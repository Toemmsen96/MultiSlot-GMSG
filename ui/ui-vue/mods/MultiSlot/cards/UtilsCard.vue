<template>
  <div class="ms-card" v-bng-scoped-nav>
    <BngCardHeading class="block-heading" type="ribbon">Templates</BngCardHeading>
    <div class="ms-row">
      <span class="ms-muted">Templates found</span>
      <b>{{ store.state.templates.length }}</b>
      <BngButton accent="outlined" @click="store.rescanTemplates()">Get Templates</BngButton>
    </div>
    <div class="ms-button-row">
      <BngButton accent="outlined" @click="store.reloadModDB()">Reload ModDB</BngButton>
      <BngButton accent="destructive" @click="store.clearCache()">Clear Generated Mods Cache</BngButton>
    </div>

    <BngCardHeading class="block-heading" type="ribbon">Advanced</BngCardHeading>
    <BngSwitch v-model="utils.advancedMode">Advanced Mode</BngSwitch>

    <template v-if="utils.advancedMode">
      <p class="ms-note">Advanced actions can lag or reload the game - use with caution.</p>
      <div class="ms-button-row">
        <BngButton accent="destructive" @click="store.reloadGELua()">Reload GELUA</BngButton>
        <BngButton accent="outlined" @click="store.reloadGmsgUI()">Reload gmsgUI</BngButton>
        <BngButton accent="outlined" @click="store.reloadGmsg()">Reload GMSG / MultiSlot</BngButton>
      </div>

      <div class="ms-field">
        <span class="ms-field-label">Reload Extension</span>
        <div class="ms-row">
          <BngDropdown class="ms-grow" :items="extensionItems" v-model="utils.selectedExtension" show-search />
          <BngButton accent="outlined" :disabled="!utils.selectedExtension" @click="store.reloadSelectedExtension()">
            Reload
          </BngButton>
        </div>
      </div>

      <BngButton class="ms-self-start" accent="outlined" @click="store.loadDependencyInstallerUi()">
        Load Dependency Installer UI
      </BngButton>

      <div class="ms-field">
        <span class="ms-field-label">Concurrency Delay</span>
        <BngSlider :min="1 / 1000" :max="1" :step="0.001" with-input
          :model-value="utils.concurrencyDelay" @update:modelValue="store.setConcurrencyDelay" />
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed } from "vue"
import { BngCardHeading, BngButton, BngSwitch, BngDropdown, BngSlider } from "@/common/components/base"
import { vBngScopedNav } from "@/common/directives"
import store from "../store.js"

const utils = computed(() => store.state.utils)
const extensionItems = computed(() => store.state.loadedExtensions.map(e => ({ value: e, label: e })))
</script>

<style scoped lang="scss">
.ms-card {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  width: 100%;
  padding: 0.5rem;
  color: var(--bng-off-white);
}

.block-heading {
  margin-top: 0.5em;
  margin-bottom: 0;
  margin-left: -0.4em;

  &:first-child {
    margin-top: 0;
  }
}

.ms-row {
  display: flex;
  gap: 0.5em;
  align-items: center;
  flex-wrap: wrap;
}

.ms-button-row {
  display: flex;
  gap: 0.5em;
  flex-wrap: wrap;
}

.ms-field {
  display: flex;
  flex-direction: column;
  gap: 0.25em;
}

.ms-field-label {
  font-size: 0.85em;
  opacity: 0.75;
}

.ms-grow {
  flex: 1 1 auto;
  min-width: 0;
}

.ms-self-start {
  align-self: flex-start;
}

.ms-muted {
  opacity: 0.55;
}

.ms-note {
  font-size: 0.8em;
  opacity: 0.55;
  margin: 0;
}
</style>
