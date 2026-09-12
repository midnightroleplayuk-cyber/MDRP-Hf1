let activeAudio = null;

function postNui(name, payload = {}) {
    try {
        return fetch(`https://${GetParentResourceName()}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload)
        });
    } catch (_) {
        return Promise.reject(_);
    }
}

window.addEventListener('load', () => {
    postNui('dialogueSoundReady', { ok: true }).catch(() => {});
});

function reportSoundError(sound, reason) {
    postNui('dialogueSoundError', {
        sound,
        reason: String(reason || 'Playback failed')
    }).catch(() => {});
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

    let settled = false;

    const tryNext = (reason) => {
        if (settled) return;
        settled = true;
        try {
            audio.pause();
            audio.currentTime = 0;
        } catch (_) {}

        if (index + 1 < urls.length) {
            tryPlaySound(sound, volume, urls, index + 1);
        } else {
            reportSoundError(sound, reason);
        }
    };

    audio.addEventListener('canplaythrough', () => {
        postNui('dialogueSoundDebug', {
            stage: 'canplay',
            sound,
            url: urls[index]
        }).catch(() => {});
    }, { once: true });

    audio.addEventListener('error', () => {
        const code = audio.error ? audio.error.code : 'unknown';
        tryNext(`Audio load error code ${code} at ${urls[index]}`);
    }, { once: true });

    audio.addEventListener('ended', () => {
        if (activeAudio === audio) activeAudio = null;
    }, { once: true });

    audio.play().then(() => {
        settled = true;
        activeAudio = audio;
        postNui('dialogueSoundDebug', {
            stage: 'playing',
            sound,
            url: urls[index]
        }).catch(() => {});
    }).catch((err) => {
        tryNext(err && err.message ? err.message : 'audio.play() rejected');
    });
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action !== 'playDialogueSound') return;

    const sound = String(data.sound || '');

    postNui('dialogueSoundDebug', {
        stage: 'received',
        sound
    }).catch(() => {});

    if (!/^[A-Za-z0-9_.-]+\.ogg$/i.test(sound) || sound.includes('..')) {
        reportSoundError(sound, 'Invalid sound filename');
        return;
    }

    stopActiveAudio();

    const volumeValue = Number(data.volume);
    const volume = Math.max(0, Math.min(1, Number.isFinite(volumeValue) ? volumeValue : 0.65));
    const encoded = encodeURIComponent(sound);
    const resource = GetParentResourceName();

    const urls = [
        `./sounds/${encoded}`,
        `https://cfx-nui-${resource}/html/sounds/${encoded}`
    ];

    tryPlaySound(sound, volume, urls);
});
