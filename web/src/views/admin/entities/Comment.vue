
<template>
  <div>
    <h4 class="mb-3">Comments</h4>
    <CRow class="g-3 mb-3">
      <CCol :md="8">
        <CFormInput v-model="newComment.content" placeholder="Comment content" />
      </CCol>
      <CCol :md="2">
        <CFormInput v-model.number="newComment.postId" type="number" placeholder="Post Id" />
      </CCol>
      <CCol :md="2">
        <CFormInput v-model.number="newComment.userId" type="number" placeholder="User Id" />
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
              <CTableHeaderCell>PostId</CTableHeaderCell>
              <CTableHeaderCell>UserId</CTableHeaderCell>
              <CTableHeaderCell>Actions</CTableHeaderCell>
            </CTableRow>
          </CTableHead>
          <CTableBody>
            <CTableRow v-for="c in comments" :key="c.id">
              <CTableDataCell>{{ c.id }}</CTableDataCell>
              <CTableDataCell>{{ c.content }}</CTableDataCell>
              <CTableDataCell>{{ c.postId }}</CTableDataCell>
              <CTableDataCell>{{ c.userId }}</CTableDataCell>
              <CTableDataCell>
                <CButton color="danger" size="sm" @click="remove(c.id)">Delete</CButton>
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
import { commentService } from '../../../services/commentService'

const comments = ref([])
const loading = ref(false)
const error = ref('')

const newComment = ref({ content: '', postId: 1, userId: 1 })

async function load() {
  error.value = ''
  loading.value = true
  try {
    comments.value = await commentService.list()
  } catch (e) {
    error.value = e.message || 'Load failed'
  } finally {
    loading.value = false
  }
}

async function create() {
  if (!newComment.value.content) return
  try {
    await commentService.create(newComment.value)
    newComment.value.content = ''
    await load()
  } catch (e) {
    error.value = e.message || 'Create failed'
  }
}

async function remove(id) {
  try {
    await commentService.remove(id)
    await load()
  } catch (e) {
    error.value = e.message || 'Delete failed'
  }
}

onMounted(load)
</script>

<style scoped>
</style>

