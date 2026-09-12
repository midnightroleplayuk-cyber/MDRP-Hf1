let activeAudio = null;

function reportSoundError(sound, reason) {
    try {
        fetch(`https://${GetParentResourceName()}/dialogueSoundError`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ sound, reason: String(reason || 'Playback failed') })
        });
    } catch (_) {}
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action !== 'playDialogueSound') return;

    const sound = String(data.sound || '');
    if (!/^[A-Za-z0-9_.-]+\.ogg$/i.test(sound) || sound.includes('..')) {
        reportSoundError(sound, 'Invalid sound filename');
        return;
    }

    if (activeAudio) {
        activeAudio.pause();
        activeAudio.currentTime = 0;
        activeAudio = null;
    }

    const volumeValue = Number(data.volume);
    const volume = Math.max(0, Math.min(1, Number.isFinite(volumeValue) ? volumeValue : 0.65));
    const resource = GetParentResourceName();
    const url = `https://${resource}/sounds/${encodeURIComponent(sound)}`;
    const audio = new Audio();
    audio.preload = 'auto';
    audio.src = url;
    audio.volume = volume;

    audio.addEventListener('ended', () => {
        if (activeAudio === audio) activeAudio = null;
    }, { once: true });

    audio.addEventListener('error', () => {
        const code = audio.error ? audio.error.code : 'unknown';
        reportSoundError(sound, `NUI audio error (${code})`);
        if (activeAudio === audio) activeAudio = null;
    }, { once: true });

    activeAudio = audio;
    audio.load();
    audio.play().catch((err) => {
        reportSoundError(sound, err && err.message ? err.message : 'audio.play() rejected');
        if (activeAudio === audio) activeAudio = null;
    });
});
