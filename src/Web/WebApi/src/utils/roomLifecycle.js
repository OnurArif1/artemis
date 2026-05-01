/**
 * Mobil `lifecycleExpiredFromRoomMap` ile uyumlu: süresi dolmuş odalar haritada gösterilmez.
 */
export function lifecycleExpiredFromRoom(room) {
    if (room == null) return false;

    let apiExpired;
    const rawFlag = room.lifecycleExpired ?? room.LifecycleExpired;
    if (typeof rawFlag === 'boolean') {
        apiExpired = rawFlag;
    } else if (typeof rawFlag === 'number') {
        apiExpired = rawFlag !== 0;
    } else if (rawFlag != null) {
        const t = String(rawFlag).toLowerCase().trim();
        if (t === 'true' || t === '1') apiExpired = true;
        if (t === 'false' || t === '0') apiExpired = false;
    }

    const lc = room.lifeCycle ?? room.LifeCycle;
    const cd = room.createDate ?? room.CreateDate;
    const minutes = typeof lc === 'number' ? lc : parseFloat(lc);
    const created = cd != null ? new Date(cd) : null;
    const createdValid = created != null && !Number.isNaN(created.getTime());

    let computedExpired = false;
    if (Number.isFinite(minutes) && createdValid) {
        const expiresMs = created.getTime() + Math.round(minutes * 60000);
        computedExpired = Date.now() > expiresMs;
    }

    if (apiExpired === true && !computedExpired && Number.isFinite(minutes) && minutes > 0 && createdValid) {
        return false;
    }
    if (apiExpired != null) return apiExpired;
    if (!Number.isFinite(minutes) || !createdValid) return false;
    return computedExpired;
}

export function roomsForMapMarkers(rooms) {
    if (!Array.isArray(rooms)) return [];
    return rooms.filter((r) => !lifecycleExpiredFromRoom(r));
}
