export const postService = {
  async list() {
    const res = await fetch(`${import.meta.env.VITE_API_BASE || 'http://localhost:5094'}/api/Post`)
    if (!res.ok) throw new Error('Failed to fetch posts')
    return res.json()
  },
  async create(payload) {
    const res = await fetch(`${import.meta.env.VITE_API_BASE || 'http://localhost:5094'}/api/Post`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!res.ok) throw new Error('Failed to create post')
    return res.json()
  },
  async remove(id) {
    const res = await fetch(`${import.meta.env.VITE_API_BASE || 'http://localhost:5094'}/api/Post/${id}`, {
      method: 'DELETE',
    })
    if (!res.ok) throw new Error('Failed to delete post')
  },
}
