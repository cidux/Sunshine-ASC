<script setup>
import { ref } from 'vue'
import { $tp } from '../../../platform-i18n'
import PlatformLayout from '../../../PlatformLayout.vue'

const props = defineProps({
  platform: String,
  config: Object,
})

const config = ref(props.config)

const clampNumber = (value, fallback, minimum, maximum) => {
  const number = Number(value)
  return Math.min(maximum, Math.max(minimum, Number.isFinite(number) ? Math.round(number) : fallback))
}

config.value.monitor_poll_interval_ms = clampNumber(config.value.monitor_poll_interval_ms, 25, 10, 1000)
config.value.monitor_debounce_ms = clampNumber(config.value.monitor_debounce_ms, 50, 0, 5000)

let _outputNamePlaceholder = '0';
if(props.platform === 'windows') {
  _outputNamePlaceholder = '{de9bb7e2-186e-505b-9e93-f48793333810}';
} else if(props.platform === 'linux' || props.platform === 'freebsd') {
  _outputNamePlaceholder = 'DP-0';
}
const outputNamePlaceholder = _outputNamePlaceholder;  // NOSONAR(javascript:S1481,javascript:S1854): Constant used by vue.js binding for placeholder below
</script>

<template>
  <div class="mb-3">
    <label for="output_name" class="form-label">{{ $t('config.output_name') }}</label>
    <input type="text" class="form-control" id="output_name" :placeholder="outputNamePlaceholder"
           v-model="config.output_name"/>
    <div class="form-text">
      {{ $tp('config.output_name_desc') }}<br>
      <PlatformLayout :platform="platform">
        <template #windows>
          <pre style="white-space: pre-line;">
            <b>&nbsp;&nbsp;{</b>
            <b>&nbsp;&nbsp;&nbsp;&nbsp;"device_id": "{de9bb7e2-186e-505b-9e93-f48793333810}"</b>
            <b>&nbsp;&nbsp;&nbsp;&nbsp;"display_name": "\\\\.\\DISPLAY1"</b>
            <b>&nbsp;&nbsp;&nbsp;&nbsp;"friendly_name": "ROG PG279Q"</b>
            <b>&nbsp;&nbsp;&nbsp;&nbsp;...</b>
            <b>&nbsp;&nbsp;}</b>
          </pre>
        </template>
        <template #freebsd>
          <pre style="white-space: pre-line;">
            Info: Detecting displays
            Info: Detected display: HDMI-A-1 connected: true
            Info: Detected display: DP-1 connected: true
            Info: Detected display: DP-2 connected: false
            Info: Detected display: DVI-D-3 connected: false
          </pre>
        </template>
        <template #linux>
          <pre style="white-space: pre-line;">
            Info: Detecting displays
            Info: Detected display: HDMI-A-1 connected: true
            Info: Detected display: DP-1 connected: true
            Info: Detected display: DP-2 connected: false
            Info: Detected display: DVI-D-3 connected: false
          </pre>
        </template>
        <template #macos>
          <pre style="white-space: pre-line;">
            Info: Detecting displays
            Info: Detected display: Monitor-0 (id: 3) connected: true
            Info: Detected display: Monitor-1 (id: 2) connected: true
          </pre>
        </template>
      </PlatformLayout>
    </div>
  </div>

  <div v-if="platform === 'windows'" class="mb-3">
    <label for="monitor_switching_mode" class="form-label">{{ $t("config.monitor_switching_mode") }}</label>
    <select id="monitor_switching_mode" class="form-select" v-model="config.monitor_switching_mode">
      <option value="manual">{{ $t("config.monitor_switching_manual") }}</option>
      <option value="focused">{{ $t("config.monitor_switching_focused") }}</option>
      <option value="mouse">{{ $t("config.monitor_switching_mouse") }}</option>
    </select>
    <div class="form-text">
      {{ $t("config.monitor_switching_mode_desc") }}
    </div>
  </div>

  <template v-if="platform === 'windows' && config.monitor_switching_mode !== 'manual'">
    <div class="mb-3">
      <label for="monitor_poll_interval_ms" class="form-label">{{ $t("config.monitor_poll_interval_ms") }}</label>
      <input
        id="monitor_poll_interval_ms"
        v-model.number="config.monitor_poll_interval_ms"
        @change="config.monitor_poll_interval_ms = clampNumber(config.monitor_poll_interval_ms, 25, 10, 1000)"
        type="number"
        class="form-control"
        min="10"
        max="1000"
        step="1"
      />
      <div class="form-text">{{ $t("config.monitor_poll_interval_ms_desc") }}</div>
    </div>

    <div class="mb-3">
      <label for="monitor_debounce_ms" class="form-label">{{ $t("config.monitor_debounce_ms") }}</label>
      <input
        id="monitor_debounce_ms"
        v-model.number="config.monitor_debounce_ms"
        @change="config.monitor_debounce_ms = clampNumber(config.monitor_debounce_ms, 50, 0, 5000)"
        type="number"
        class="form-control"
        min="0"
        max="5000"
        step="1"
      />
      <div class="form-text">{{ $t("config.monitor_debounce_ms_desc") }}</div>
    </div>
  </template>
</template>
