export const commentService = {
  async list() {
    const res = await fetch(`${import.meta.env.VITE_API_BASE || 'http://localhost:5094'}/api/Comment`)
    if (!res.ok) throw new Error('Failed to fetch comments')
    return res.json()
  },
  async create(payload) {
    const res = await fetch(`${import.meta.env.VITE_API_BASE || 'http://localhost:5094'}/api/Comment`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!res.ok) throw new Error('Failed to create comment')
    return res.json()
  },
  async remove(id) {
    const res = await fetch(`${import.meta.env.VITE_API_BASE || 'http://localhost:5094'}/api/Comment/${id}`, {
      method: 'DELETE',
    })
    if (!res.ok) throw new Error('Failed to delete comment')
  },
}
