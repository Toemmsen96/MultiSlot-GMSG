<template>
  <div class="ms-card" v-bng-scoped-nav>
    <div v-if="!store.state.ready" class="ms-waiting">Loading…</div>
    <div v-else-if="!store.state.templates.length" class="ms-error">
      No Templates found! Please download or create at least one MultiSlot / GMSG Plugin and
      ensure the template is in the modslotgenerator folder.
    </div>
    <template v-else>
      <BngCardHeading class="block-heading" type="ribbon">Template</BngCardHeading>
      <BngDropdown class="ms-field" :items="templateItems" v-model="standalone.selectedTemplate" />

      <BngCardHeading class="block-heading" type="ribbon">Output</BngCardHeading>
      <div class="ms-field">
        <span class="ms-field-label">Output Path (relative to the mods folder)</span>
        <BngInput v-model="standalone.outputPath" type="text" :maxlength="256" />
      </div>
      <BngSwitch v-model="standalone.autopack">Autopack generated Mod</BngSwitch>
      <BngSwitch v-model="standalone.includeMStemplate">Include MultiSlot-Template</BngSwitch>
      <BngSwitch v-model="standalone.addDependencyDownloader" :disabled="!standalone.includeMStemplate">
        Add Dependency-Downloader
      </BngSwitch>

      <BngButton
        class="ms-generate-button"
        accent="attention"
        :disabled="store.state.busy || !standalone.selectedTemplate"
        @click="store.generateSpecificMod()">
        Generate selected Mod
      </BngButton>
    </template>
  </div>
</template>

<script setup>
import { computed } from "vue"
import { BngCardHeading, BngButton, BngSwitch, BngInput, BngDropdown } from "@/common/components/base"
import { vBngScopedNav } from "@/common/directives"
import store from "../store.js"

const standalone = computed(() => store.state.standalone)
const templateItems = computed(() => store.state.templates.map(t => ({ value: t, label: t })))
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

.ms-field {
  display: flex;
  flex-direction: column;
  gap: 0.25em;
}

.ms-field-label {
  font-size: 0.85em;
  opacity: 0.75;
}

.ms-generate-button {
  align-self: flex-start;
  margin-top: 0.5em;
}

.ms-error {
  color: rgb(255, 120, 120);
  font-size: 0.9em;
}

.ms-waiting {
  opacity: 0.6;
}
</style>
