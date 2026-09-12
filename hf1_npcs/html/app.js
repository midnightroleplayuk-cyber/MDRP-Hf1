let activeAudio = null;

function reportSoundError(sound, reason) {
    try {
        fetch(`https://${GetParentResourceName()}/dialogueSoundError`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ sound, reason: String(reason || 'Playback failed') })
        }).catch(() => {});
    } catch (_) {}
}

function stopActiveAudio() {
    if (!activeAudio) return;
    try {
        activeAudio.pause();
        activeAudio.currentTime = 0;
    } catch (_) {}
    activeAudio = null;
}

function tryPlaySound(sound, volume, urls, index = 0) {
    if (index >= urls.length) {
        reportSoundError(sound, 'Could not load sound from any NUI path');
        return;
    }

    const audio = new Audio();
    audio.preload = 'auto';
    audio.volume = volume;
    audio.src = urls[index];

    let failed = false;

    const fail = (reason) => {
        if (failed) return;
        failed = true;
        try {
            audio.pause();
            audio.currentTime = 0;
        } catch (_) {}
        tryPlaySound(sound, volume, urls, index + 1);
    };

    audio.addEventListener('error', () => {
        const code = audio.error ? audio.error.code : 'unknown';
        fail(`NUI audio error (${code})`);
    }, { once: true });

    audio.addEventListener('ended', () => {
        if (activeAudio === audio) activeAudio = null;
    }, { once: true });

    audio.play().then(() => {
        activeAudio = audio;
    }).catch((err) => {
        fail(err && err.message ? err.message : 'audio.play() rejected');
    });
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action !== 'playDialogueSound') return;

    const sound = String(data.sound || '');
    if (!/^[A-Za-z0-9_.-]+\.ogg$/i.test(sound) || sound.includes('..')) {
        reportSoundError(sound, 'Invalid sound filename');
        return;
    }

    stopActiveAudio();

    const volumeValue = Number(data.volume);
    const volume = Math.max(0, Math.min(1, Number.isFinite(volumeValue) ? volumeValue : 0.65));
    const encoded = encodeURIComponent(sound);
    const resource = GetParentResourceName();

    // First use the page-relative path. Since ui_page is html/index.html,
    // this resolves to html/sounds/<file>.ogg.
    // Fallback to FiveM's explicit cfx-nui resource URL.
    const urls = [
        `./sounds/${encoded}`,
        `https://cfx-nui-${resource}/html/sounds/${encoded}`
    ];

    tryPlaySound(sound, volume, urls);
});
