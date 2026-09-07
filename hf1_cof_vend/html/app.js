const cache = new Map();
window.addEventListener('message', (event) => {
    const d = event.data || {};
    if (d.action !== 'play' || !d.file) return;
    let a = cache.get(d.file);
    if (!a) { a = new Audio(`sounds/${d.file}`); a.preload = 'auto'; cache.set(d.file, a); }
    a.pause(); a.currentTime = 0; a.volume = Math.max(0, Math.min(1, Number(d.volume ?? 0.45))); a.play().catch(() => {});
});
