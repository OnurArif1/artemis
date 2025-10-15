<template>
  <div>
    <h3 class="mb-4">Admin Dashboard</h3>
    <CRow class="g-4">
      <CCol :xs="12" :md="6" :lg="3">
        <CCard>
          <CCardBody>
            <div class="fs-5">Users</div>
            <div class="fs-3 fw-bold">—</div>
          </CCardBody>
        </CCard>
      </CCol>
      <CCol :xs="12" :md="6" :lg="3">
        <CCard>
          <CCardBody>
            <div class="fs-5">Posts</div>
            <div class="fs-3 fw-bold">—</div>
          </CCardBody>
        </CCard>
      </CCol>
      <CCol :xs="12" :md="6" :lg="3">
        <CCard>
          <CCardBody>
            <div class="fs-5">Comments</div>
            <div class="fs-3 fw-bold">—</div>
          </CCardBody>
        </CCard>
      </CCol>
      <CCol :xs="12" :md="6" :lg="3">
        <CCard>
          <CCardBody>
            <div class="fs-5">Topics</div>
            <div class="fs-3 fw-bold">—</div>
          </CCardBody>
        </CCard>
      </CCol>
    </CRow>
  </div>
</template>

<script setup>
</script>

<style scoped>
</style>

