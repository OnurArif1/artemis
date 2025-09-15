<template>
  <div class="admin-layout d-flex">
    <CSidebar class="min-vh-100" :visible="true" position="fixed">
      <CSidebarBrand class="d-none d-md-flex" to="/admin">
        <h5 class="m-0">Artemis Admin</h5>
      </CSidebarBrand>
      <CSidebarNav>
        <CNavTitle>General</CNavTitle>
        <CNavItem to="/admin" :active="$route.name === 'AdminDashboard'">
          <CIcon :icon="icons.cilSpeedometer" class="me-2" /> Dashboard
        </CNavItem>
        <CNavTitle>Entities</CNavTitle>
        <CNavGroup toggler="Entities">
          <CNavItem to="/admin/entities/comment"><CIcon :icon="icons.cilCommentSquare" class="me-2" /> Comment</CNavItem>
          <CNavItem to="/admin/entities/reaction"><CIcon :icon="icons.cilThumbUp" class="me-2" /> Reaction</CNavItem>
          <CNavItem to="/admin/entities/post"><CIcon :icon="icons.cilList" class="me-2" /> Post</CNavItem>
          <CNavItem to="/admin/entities/topic"><CIcon :icon="icons.cilLayers" class="me-2" /> Topic</CNavItem>
          <CNavItem to="/admin/entities/user"><CIcon :icon="icons.cilUser" class="me-2" /> User</CNavItem>
          <CNavItem to="/admin/entities/notification"><CIcon :icon="icons.cilBell" class="me-2" /> Notification</CNavItem>
          <CNavItem to="/admin/entities/place"><CIcon :icon="icons.cilLocationPin" class="me-2" /> Place</CNavItem>
          <CNavItem to="/admin/entities/place-category"><CIcon :icon="icons.cilBookmark" class="me-2" /> Place Category</CNavItem>
          <CNavItem to="/admin/entities/report"><CIcon :icon="icons.cilReportSlash" class="me-2" /> Report</CNavItem>
        </CNavGroup>
      </CSidebarNav>
    </CSidebar>

    <div class="wrapper d-flex flex-column min-vh-100 w-100">
      <CHeader position="sticky" class="mb-4">
        <CContainer fluid>
          <CHeaderBrand to="/admin">Artemis Admin</CHeaderBrand>
          <CHeaderNav class="ms-auto">
            <CNavItem>
              <router-link to="/profile" class="nav-link">Profile</router-link>
            </CNavItem>
          </CHeaderNav>
        </CContainer>
      </CHeader>
      <CContainer class="flex-grow-1">
        <router-view />
      </CContainer>
      <CFooter>
        <div>
          <span>© 2025 Artemis</span>
        </div>
      </CFooter>
    </div>
  </div>
</template>

<script setup>
import { inject } from 'vue'
const icons = inject('icons')
</script>

<style scoped>
.admin-layout { min-height: 100vh; }
</style>

