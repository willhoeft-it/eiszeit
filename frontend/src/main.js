import '@babel/polyfill'
import Vue from 'vue'
import './plugins/vuetify'
import App from './App.vue'
import VueRouter from 'vue-router'
import DailyBookingPage from '@/views/DailyBookingPage.vue'
import TaskManagingPage from '@/views/TaskManagingPage.vue'
import UserManagingPage from '@/views/UserManagingPage.vue'
import ReportProjectsPage from '@/views/ReportProjectsPage.vue'
import ReportWorkingtimePage from '@/views/ReportWorkingtimePage.vue'
import ResetPasswordPage from '@/views/ResetPasswordPage.vue'

Vue.config.productionTip = false
Vue.use(VueRouter)

const router = new VueRouter({
  routes: [
    { path: '/', component: null },
    { path: '/dashboard', component: null },
    { path: '/dailyBooking', component: DailyBookingPage },
    { path: '/taskManaging', component: TaskManagingPage },
    { path: '/userManaging', component: UserManagingPage },
    { path: '/reportProjects', component: ReportProjectsPage },
    { path: '/reportWorkingtime', component: ReportWorkingtimePage },
    { path: '/resetPassword', component: ResetPasswordPage },
  ]
})

new Vue({
  router,
  render: h => h(App)
}).$mount('#app')
