import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import App from './App.vue'
import './assets/css/main.css'
// CoreUI styles
import '@coreui/coreui/dist/css/coreui.min.css'
// CoreUI Vue plugin and icons
import CoreuiVue from '@coreui/vue'
import CIcon from '@coreui/icons-vue'
import {
  cilSpeedometer,
  cilList,
  cilUser,
  cilBell,
  cilBookmark,
  cilCommentSquare,
  cilLocationPin,
  cilLayers,
  cilThumbUp,
  cilReportSlash,
} from '@coreui/icons'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(CoreuiVue)
app.component('CIcon', CIcon)
app.provide('icons', {
  cilSpeedometer,
  cilList,
  cilUser,
  cilBell,
  cilBookmark,
  cilCommentSquare,
  cilLocationPin,
  cilLayers,
  cilThumbUp,
  cilReportSlash,
})

app.mount('#app')
