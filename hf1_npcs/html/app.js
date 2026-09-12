let activeAudio = null;

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action !== 'playDialogueSound') return;

    const sound = String(data.sound || '');
    if (!/^[A-Za-z0-9_./-]+\.ogg$/i.test(sound) || sound.includes('..')) return;

    if (activeAudio) {
        activeAudio.pause();
        activeAudio.currentTime = 0;
        activeAudio = null;
    }

    const volume = Math.max(0, Math.min(1, Number(data.volume) || 0.65));
    const audio = new Audio(`sounds/${sound}`);
    audio.volume = volume;
    audio.addEventListener('ended', () => {
        if (activeAudio === audio) activeAudio = null;
    }, { once: true });
    audio.addEventListener('error', () => {
        if (activeAudio === audio) activeAudio = null;
    }, { once: true });

    activeAudio = audio;
    audio.play().catch(() => {
        if (activeAudio === audio) activeAudio = null;
    });
});
