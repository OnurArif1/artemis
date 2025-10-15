<template>
  <div>
    <h4 class="mb-3">Posts</h4>
    <CRow class="g-3 mb-3">
      <CCol :md="8">
        <CFormInput v-model="newPost.content" placeholder="Post content" />
      </CCol>
      <CCol :md="2">
        <CFormInput v-model.number="newPost.topicId" type="number" placeholder="Topic Id" />
      </CCol>
      <CCol :md="2">
        <CFormInput v-model.number="newPost.userId" type="number" placeholder="User Id" />
      </CCol>
      <CCol :md="12">
        <CButton color="primary" @click="create">Add</CButton>
      </CCol>
    </CRow>

    <CCard>
      <CCardBody>
        <CAlert v-if="error" color="danger" class="mb-3">{{ error }}</CAlert>
        <CSpinner v-if="loading" />
        <CTable v-else small hover>
          <CTableHead>
            <CTableRow>
              <CTableHeaderCell>ID</CTableHeaderCell>
              <CTableHeaderCell>Content</CTableHeaderCell>
              <CTableHeaderCell>TopicId</CTableHeaderCell>
              <CTableHeaderCell>UserId</CTableHeaderCell>
              <CTableHeaderCell>Actions</CTableHeaderCell>
            </CTableRow>
          </CTableHead>
          <CTableBody>
            <CTableRow v-for="p in posts" :key="p.id">
              <CTableDataCell>{{ p.id }}</CTableDataCell>
              <CTableDataCell>{{ p.content }}</CTableDataCell>
              <CTableDataCell>{{ p.topicId }}</CTableDataCell>
              <CTableDataCell>{{ p.userId }}</CTableDataCell>
              <CTableDataCell>
                <CButton color="danger" size="sm" @click="remove(p.id)">Delete</CButton>
              </CTableDataCell>
            </CTableRow>
          </CTableBody>
        </CTable>
      </CCardBody>
    </CCard>
  </div>
  </template>

<script setup>
import { ref, onMounted } from 'vue'
import { postService } from '../../../services/postService'

const posts = ref([])
const loading = ref(false)
const error = ref('')

const newPost = ref({ content: '', topicId: 1, userId: 1 })

async function load() {
  error.value = ''
  loading.value = true
  try {
    posts.value = await postService.list()
  } catch (e) {
    error.value = e.message || 'Load failed'
  } finally {
    loading.value = false
  }
}

async function create() {
  if (!newPost.value.content) return
  try {
    await postService.create(newPost.value)
    newPost.value.content = ''
    await load()
  } catch (e) {
    error.value = e.message || 'Create failed'
  }
}

async function remove(id) {
  try {
    await postService.remove(id)
    await load()
  } catch (e) {
    error.value = e.message || 'Delete failed'
  }
}

onMounted(load)
</script>

<style scoped>
</style>

