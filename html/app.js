(() => {
    'use strict';

    const isNui = typeof GetParentResourceName !== 'undefined';
    const resourceName = isNui ? GetParentResourceName() : 'jrmy_tags';
    const reducedMotionQuery = window.matchMedia ? window.matchMedia('(prefers-reduced-motion: reduce)') : { matches: false };
    const $ = (selector, root = document) => root.querySelector(selector);
    const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));
    const hasOwn = (object, key) => Object.prototype.hasOwnProperty.call(object, key);

    const icons = {
        x: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
        eye: '<path d="M2.06 12.35a1 1 0 0 1 0-.7C3.64 7.6 7.56 5 12 5c4.44 0 8.36 2.6 9.94 6.65a1 1 0 0 1 0 .7C20.36 16.4 16.44 19 12 19c-4.44 0-8.36-2.6-9.94-6.65"/><circle cx="12" cy="12" r="3"/>',
        'eye-off': '<path d="m15 18-.72-3.25"/><path d="M2 8a10.65 10.65 0 0 0 20 0"/><path d="m20 15-1.73-2.05"/><path d="m4 15 1.73-2.05"/><path d="m9 18 .72-3.25"/>',
        moon: '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9"/>',
        'user-plus': '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6"/><path d="M22 11h-6"/>',
        'badge-check': '<path d="M3.85 8.62a4 4 0 0 1 4.77-4.77 4 4 0 0 1 6.76 0 4 4 0 0 1 4.77 4.77 4 4 0 0 1 0 6.76 4 4 0 0 1-4.77 4.77 4 4 0 0 1-6.76 0 4 4 0 0 1-4.77-4.77 4 4 0 0 1 0-6.76Z"/><path d="m9 12 2 2 4-4"/>',
        users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
        palette: '<circle cx="13.5" cy="6.5" r=".5"/><circle cx="17.5" cy="10.5" r=".5"/><circle cx="8.5" cy="7.5" r=".5"/><circle cx="6.5" cy="12.5" r=".5"/><path d="M12 22a10 10 0 1 0-10-10 10 10 0 0 0 10 10Zm0 0c1.1 0 2-.9 2-2v-.7c0-.7.6-1.3 1.3-1.3H17a5 5 0 0 0 5-5"/>',
        'refresh-cw': '<path d="M21 12a9 9 0 0 1-15.3 6.4L3 16"/><path d="M3 21v-5h5"/><path d="M3 12A9 9 0 0 1 18.3 5.6L21 8"/><path d="M21 3v5h-5"/>',
        search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
        'wand-sparkles': '<path d="m15 4-1-2-1 2-2 1 2 1 1 2 1-2 2-1-2-1Z"/><path d="m21 12-1-2-1 2-2 1 2 1 1 2 1-2 2-1-2-1Z"/><path d="m9 9-1.5-3L6 9l-3 1.5L6 12l1.5 3L9 12l3-1.5L9 9Z"/><path d="m9 15 6 6"/><path d="m15 15-6 6"/>',
        check: '<path d="m20 6-11 11-5-5"/>',
        'trash-2': '<path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><path d="M10 11v6"/><path d="M14 11v6"/>',
        'triangle-alert': '<path d="m21.73 18-8-14a2 2 0 0 0-3.46 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
        sparkles: '<path d="M9.94 15.5A2 2 0 0 0 8.5 14.06l-6.14-1.58a.5.5 0 0 1 0-.96L8.5 9.94A2 2 0 0 0 9.94 8.5l1.58-6.14a.5.5 0 0 1 .96 0l1.58 6.14a2 2 0 0 0 1.44 1.44l6.14 1.58a.5.5 0 0 1 0 .96l-6.14 1.58a2 2 0 0 0-1.44 1.44l-1.58 6.14a.5.5 0 0 1-.96 0Z"/><path d="M20 3v4"/><path d="M22 5h-4"/>',
        'user-round': '<circle cx="12" cy="8" r="5"/><path d="M20 21a8 8 0 0 0-16 0"/>',
        pencil: '<path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
        microphone: '<path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><path d="M12 19v3"/>',
        crown: '<path d="m2 4 3 12h14l3-12-6 7-4-7-4 7-6-7Z"/><path d="M5 20h14"/>',
        'code-xml': '<path d="m18 16 4-4-4-4"/><path d="m6 8-4 4 4 4"/><path d="m14.5 4-5 16"/>',
        'shield-check': '<path d="M20 13c0 5-3.5 7.5-8 9-4.5-1.5-8-4-8-9V5l8-3 8 3v8Z"/><path d="m9 12 2 2 4-4"/>',
        star: '<path d="m12 2 3.09 6.26L22 9.27l-5 4.87L18.18 21 12 17.77 5.82 21 7 14.14 2 9.27l6.91-1.01L12 2Z"/>',
        gem: '<path d="M6 3h12l4 6-10 13L2 9l4-6Z"/><path d="m11 3-3 6 4 13 4-13-3-6"/><path d="M2 9h20"/>',
        'party-popper': '<path d="M5.8 11.3 2 22l10.7-3.79"/><path d="M4 3h.01"/><path d="M22 8h.01"/><path d="M15 2h.01"/><path d="M22 20h.01"/><path d="m22 2-2.24.75a2.9 2.9 0 0 0-1.81 1.81L17.2 6.8"/><path d="m15 9 .6-.4a2 2 0 0 0 .8-2.6L16 5"/><path d="M9 2 8.6 3.1A2 2 0 0 0 9.4 5.6L10 6"/><path d="M15 22h.01"/><path d="M4 3a5 5 0 0 1 5 5"/><path d="M22 8a5 5 0 0 0-5 5"/><path d="M22 20a5 5 0 0 1-5-5"/><path d="M15 2a5 5 0 0 0-5 5"/>',
        heart: '<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78L12 21.23l8.84-8.84a5.5 5.5 0 0 0 0-7.78Z"/>',
        'paw-print': '<circle cx="11" cy="4" r="2"/><circle cx="18" cy="8" r="2"/><circle cx="20" cy="16" r="2"/><path d="M9 10a5 5 0 0 1 6.8 7.5l-.4.6A4 4 0 0 1 12 20H9.5a4.5 4.5 0 0 1-3.6-7.2Z"/><circle cx="4" cy="10" r="2"/>',
        coffee: '<path d="M10 2v2"/><path d="M14 2v2"/><path d="M6 2v2"/><path d="M18 8h1a4 4 0 0 1 0 8h-1"/><path d="M4 8h14v9a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4Z"/><path d="M6 1v1"/>',
        'gamepad-2': '<line x1="6" x2="10" y1="11" y2="11"/><line x1="8" x2="8" y1="9" y2="13"/><line x1="15" x2="15.01" y1="12" y2="12"/><line x1="18" x2="18.01" y1="10" y2="10"/><path d="M17.32 5H6.68a4 4 0 0 0-3.94 3.32l-1.28 7.33A3 3 0 0 0 4.42 19H6l2-3h8l2 3h1.58a3 3 0 0 0 2.96-3.35l-1.28-7.33A4 4 0 0 0 17.32 5Z"/>',
        wrench: '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76Z"/>',
        megaphone: '<path d="m3 11 18-5v12L3 14v-3Z"/><path d="M11.6 16.8 13 21H8l-1.8-5.8"/><path d="M21 12h2"/>',
        'circle-check': '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
        'loader-circle': '<path d="M21 12a9 9 0 1 1-6.22-8.56"/>',
        'volume-2': '<path d="M11 5 6 9H2v6h4l5 4z"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/>',
        'volume-x': '<path d="M11 5 6 9H2v6h4l5 4z"/><path d="m22 9-6 6"/><path d="m16 9 6 6"/>',
    };

    const fallbacks = {
        close: 'Cerrar',
        mute: 'Silenciar sonidos',
        unmute: 'Activar sonidos',
        player_tab: 'Mi colección',
        admin_tab: 'Administración',
        tags_owned: 'Tags disponibles',
        visible_now: 'Visible ahora',
        hidden_now: 'Oculto ahora',
        afk_active: 'Estás AFK',
        afk_inactive: 'Disponible',
        show_tag: 'Mostrar tag',
        hide_tag: 'Ocultar tag',
        enable_afk: 'Entrar en AFK',
        disable_afk: 'Volver',
        select: 'Seleccionar',
        selected: 'Seleccionado',
        permanent: 'Permanente',
        refresh: 'Actualizar',
        choose_target: 'Selecciona una persona',
        custom: 'Personalizado',
        active: 'Activo',
        online: 'Conectado',
        offline: 'Desconectado',
        visible: 'Visible',
        hidden: 'Oculto',
        temporary: 'Temporal',
        edit: 'Editar',
        remove: 'Retirar',
        deliver: 'Entregar tag',
        save: 'Guardar cambios',
        loading: 'Cargando...',
        days: 'días',
        required_fields: 'Selecciona una persona y un estilo.',
        operation_failed: 'No se pudo completar la operación.',
        save_success: 'Tag guardado correctamente.',
        revoke_success: 'Tag retirado correctamente.',
        select_success: 'Tag seleccionado.',
        visibility_success: 'Visibilidad actualizada.',
        id_label: 'ID {id}',
        assignment_count: '{count} tags',
        expires_in: 'Vence en {days} días',
        expires_today: 'Vence hoy',
        delete_text: '{label} desaparecerá de la colección de {name}.',
        filters_label: 'Filtros',
    };

    const allowed = {
        tone: new Set(['rose', 'hot', 'lilac', 'mint', 'gold', 'cream']),
        variant: new Set(['royal', 'mono', 'candy', 'sakura', 'sticker', 'minimal', 'ribbon']),
        font: new Set(['display', 'body', 'mono']),
        effect: new Set(['none', 'glow', 'float', 'pulse', 'shimmer']),
        symbol: new Set(['icon', 'emoji', 'none']),
        backgroundFit: new Set(['cover', 'contain', 'fill']),
        backgroundPosition: new Set(['center', 'top', 'bottom', 'left', 'right']),
        backgroundTint: new Set(['none', 'soft', 'medium', 'strong']),
        backgroundMotion: new Set(['none', 'drift', 'pan', 'pulse']),
    };

    const state = {
        strings: {},
        locale: 'es',
        mode: 'player',
        styles: [],
        styleMap: new Map(),
        player: {},
        grants: [],
        admin: { players: [], assignments: [], stats: {} },
        session: null,
        assignmentFilter: 'all',
        editing: null,
        deleting: null,
        busy: null,
        busyTimer: null,
        refreshTimer: null,
        playerBusy: null,
        playerBusyTimer: null,
        lastFocus: null,
        activeLayer: null,
        muted: false,
        petalsBuilt: false,
        visibilityGeneration: 0,
        worldRevision: 0,
        worldDefinitions: new Map(),
        worldNodes: new Map(),
        worldFrames: new Map(),
        worldRaf: 0,
    };

    const pick = (value, ...keys) => {
        for (const key of keys) {
            if (value && value[key] !== undefined && value[key] !== null) {
                return value[key];
            }
        }
        return undefined;
    };

    const truthy = (value, fallback = false) => value === undefined || value === null ? fallback : value === true || value === 1 || value === '1';
    const finite = (value, fallback = 0) => Number.isFinite(Number(value)) ? Number(value) : fallback;
    const clamp = (value, min, max) => Math.min(max, Math.max(min, finite(value, min)));
    const text = (value, fallback = '') => typeof value === 'string' || typeof value === 'number' ? String(value) : fallback;
    const enumValue = (group, value, fallback) => allowed[group].has(String(value || '').toLowerCase()) ? String(value).toLowerCase() : fallback;
    const responseAccepted = (value) => Boolean(value && (value.ok === true || value.accepted === true));
    const expirationDays = (value) => {
        const expiresAt = finite(pick(value, 'expiresAt', 'expires_at'), 0);
        return expiresAt > 0 ? Math.max(0, Math.ceil((expiresAt - Date.now() / 1000) / 86400)) : -1;
    };

    function svgMarkup(name) {
        const key = hasOwn(icons, name) ? name : 'sparkles';
        return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[key]}</svg>`;
    }

    function svgElement(name) {
        const wrapper = document.createElement('span');
        wrapper.innerHTML = svgMarkup(name);
        return wrapper.firstElementChild;
    }

    function paintIcons(root = document) {
        $$('[data-icon]', root).forEach((element) => {
            element.replaceChildren(svgElement(element.dataset.icon));
        });
    }

    function tr(key, replacements = {}) {
        let value = text(state.strings[key], fallbacks[key] || key);
        Object.entries(replacements).forEach(([name, replacement]) => {
            value = value.replaceAll(`{${name}}`, String(replacement));
        });
        return value;
    }

    function applyTranslations() {
        $$('[data-i18n]').forEach((element) => {
            element.textContent = tr(element.dataset.i18n);
        });
        $$('[data-i18n-placeholder]').forEach((element) => {
            element.placeholder = tr(element.dataset.i18nPlaceholder);
        });
        $$('[data-i18n-aria-label]').forEach((element) => {
            element.setAttribute('aria-label', tr(element.dataset.i18nAriaLabel));
        });
        $('#closeButton').setAttribute('aria-label', tr('close'));
        $('#closeButton').title = tr('close');
        $('#refreshButton').setAttribute('aria-label', tr('refresh'));
        $('#refreshButton').title = tr('refresh');
        $$('.modal-backdrop, .modal-close').forEach((element) => element.setAttribute('aria-label', tr('close')));
        updateSoundButton();
    }

    function post(name, payload = {}) {
        if (!isNui) {
            return Promise.resolve({ accepted: true, preview: true });
        }
        return fetch(`https://${resourceName}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload),
        }).then((response) => response.json().catch(() => ({}))).catch(() => ({}));
    }

    let audioContext = null;
    let lastHover = 0;

    function audio() {
        if (!audioContext) {
            try {
                audioContext = new (window.AudioContext || window.webkitAudioContext)();
            } catch (error) {
                return null;
            }
        }
        if (audioContext.state === 'suspended') {
            audioContext.resume().catch(() => {});
        }
        return audioContext;
    }

    function tone(frequency, duration, delay = 0, type = 'sine', volume = .04) {
        const context = audio();
        if (!context) {
            return;
        }
        const oscillator = context.createOscillator();
        const gain = context.createGain();
        const start = context.currentTime + delay;
        oscillator.type = type;
        oscillator.frequency.value = frequency;
        gain.gain.setValueAtTime(0, start);
        gain.gain.linearRampToValueAtTime(volume, start + .008);
        gain.gain.exponentialRampToValueAtTime(.0001, start + duration);
        oscillator.connect(gain);
        gain.connect(context.destination);
        oscillator.start(start);
        oscillator.stop(start + duration + .02);
    }

    const sounds = {
        hover() {
            const now = performance.now();
            if (now - lastHover < 48) {
                return;
            }
            lastHover = now;
            tone(1180, .05, 0, 'sine', .016);
        },
        click() {
            tone(560, .09, 0, 'triangle', .045);
            tone(840, .07, .01, 'sine', .026);
        },
        toggle() {
            tone(660, .07, 0, 'triangle', .04);
        },
        open() {
            [392, 523, 659, 880].forEach((frequency, index) => tone(frequency, .2, index * .05, 'sine', .035));
        },
        success() {
            [523, 659, 784, 1046].forEach((frequency, index) => tone(frequency, .16, index * .06, 'sine', .045));
        },
        error() {
            tone(240, .16, 0, 'triangle', .055);
            tone(180, .18, .07, 'sine', .045);
        },
    };

    function play(name) {
        if (!state.muted && sounds[name]) {
            sounds[name]();
        }
    }

    function updateSoundButton() {
        const button = $('#soundButton');
        if (!button) {
            return;
        }
        button.replaceChildren(svgElement(state.muted ? 'volume-x' : 'volume-2'));
        button.setAttribute('aria-label', tr(state.muted ? 'unmute' : 'mute'));
        button.title = tr(state.muted ? 'unmute' : 'mute');
    }

    function toast(message, kind = 'info') {
        if (!message || !$('#panelApp').classList.contains('is-open')) {
            return;
        }
        const element = document.createElement('div');
        element.className = `toast toast--${kind === 'error' ? 'error' : kind === 'success' ? 'success' : 'info'}`;
        element.setAttribute('role', kind === 'error' ? 'alert' : 'status');
        const icon = document.createElement('span');
        icon.className = 'toast__icon';
        icon.appendChild(svgElement(kind === 'error' ? 'triangle-alert' : kind === 'success' ? 'circle-check' : 'sparkles'));
        const copy = document.createElement('span');
        copy.textContent = text(message);
        element.append(icon, copy);
        $('#toasts').appendChild(element);
        play(kind === 'error' ? 'error' : kind === 'success' ? 'success' : 'click');
        window.setTimeout(() => {
            element.classList.add('is-leaving');
            window.setTimeout(() => element.remove(), 270);
        }, 2700);
    }

    function buildPetals() {
        if (state.petalsBuilt) {
            return;
        }
        state.petalsBuilt = true;
        const box = $('#petals');
        for (let index = 0; index < 10; index += 1) {
            const petal = document.createElement('span');
            const size = 8 + Math.random() * 11;
            petal.className = 'petal';
            petal.style.left = `${4 + Math.random() * 92}%`;
            petal.style.width = `${size}px`;
            petal.style.height = `${size}px`;
            petal.style.opacity = String(.07 + Math.random() * .13);
            petal.style.animationDuration = `${10 + Math.random() * 9}s`;
            petal.style.animationDelay = `${-Math.random() * 14}s`;
            box.appendChild(petal);
        }
    }

    function safeColor(value) {
        if (typeof value !== 'string') {
            return '';
        }
        const trimmed = value.trim();
        return /^(#[0-9a-f]{3,8}|rgba?\([\d\s.,%]+\))$/i.test(trimmed) ? trimmed : '';
    }

    function normalizeColors(value) {
        const source = value && typeof value === 'object' ? value : {};
        return {
            accent: safeColor(pick(source, 'accent', 'Accent')),
            surface: safeColor(pick(source, 'surface', 'Surface')),
            border: safeColor(pick(source, 'border', 'Border')),
            text: safeColor(pick(source, 'text', 'Text')),
        };
    }

    function safeBackgroundFile(value) {
        const file = text(value).trim();
        if (!/^[a-z0-9][a-z0-9._-]{3,95}$/.test(file) || file.includes('..')) {
            return '';
        }
        const extension = file.split('.').pop();
        return ['png', 'jpg', 'jpeg', 'webp', 'gif'].includes(extension) ? file : '';
    }

    function normalizeBackground(value) {
        const source = value && typeof value === 'object' ? value : {};
        const file = safeBackgroundFile(pick(source, 'file', 'File'));
        if (!file) {
            return null;
        }
        const animated = truthy(pick(source, 'animated', 'Animated'), false) || file.endsWith('.gif');
        const fallback = safeBackgroundFile(pick(source, 'fallback', 'Fallback'));
        return {
            file,
            fallback: fallback || (animated ? '' : file),
            animated,
            fit: enumValue('backgroundFit', pick(source, 'fit', 'Fit'), 'cover'),
            position: enumValue('backgroundPosition', pick(source, 'position', 'Position'), 'center'),
            tint: enumValue('backgroundTint', pick(source, 'tint', 'Tint'), 'medium'),
            opacity: clamp(pick(source, 'opacity', 'Opacity') ?? .65, .15, 1),
            motion: enumValue('backgroundMotion', pick(source, 'motion', 'Motion'), 'none'),
        };
    }

    function normalizeStyle(raw, fallbackKey = '') {
        const value = raw && typeof raw === 'object' ? raw : {};
        const key = text(pick(value, 'key', 'id', 'styleKey', 'StyleKey'), fallbackKey);
        return {
            key,
            name: text(pick(value, 'name', 'Name'), key || 'Tag'),
            label: text(pick(value, 'label', 'Label'), key || 'TAG').slice(0, 32),
            subtitle: text(pick(value, 'subtitle', 'Subtitle')).slice(0, 48),
            symbol: enumValue('symbol', pick(value, 'symbol', 'Symbol'), 'icon'),
            icon: hasOwn(icons, text(pick(value, 'icon', 'Icon'))) ? text(pick(value, 'icon', 'Icon')) : 'sparkles',
            emoji: text(pick(value, 'emoji', 'Emoji'), '✨').slice(0, 12),
            variant: enumValue('variant', pick(value, 'variant', 'Variant'), 'candy'),
            tone: enumValue('tone', pick(value, 'tone', 'Tone'), 'rose'),
            font: enumValue('font', pick(value, 'font', 'Font'), 'body'),
            effect: enumValue('effect', pick(value, 'effect', 'Effect'), 'none'),
            background: normalizeBackground(pick(value, 'background', 'Background')),
            uppercase: truthy(pick(value, 'uppercase', 'Uppercase'), false),
            colors: normalizeColors(pick(value, 'colors', 'Colors')),
        };
    }

    function normalizeStyles(raw) {
        if (Array.isArray(raw)) {
            return raw.map((style, index) => normalizeStyle(style, text(pick(style, 'key', 'id'), String(index + 1))));
        }
        if (raw && typeof raw === 'object') {
            return Object.entries(raw).map(([key, style]) => normalizeStyle(style, key));
        }
        return [];
    }

    function setStyles(raw) {
        state.styles = normalizeStyles(raw);
        state.styleMap = new Map(state.styles.map((style) => [String(style.key), style]));
    }

    function normalizeDefinition(raw, fallbackId = '') {
        const value = raw && typeof raw === 'object' ? raw : {};
        const styleKey = text(pick(value, 'styleKey', 'style', 'StyleKey', 'key'));
        const template = state.styleMap.get(styleKey) || {};
        const merged = { ...template, ...value };
        const normalized = normalizeStyle(merged, styleKey);
        normalized.id = text(pick(value, 'id', 'assignmentId'), fallbackId);
        normalized.styleKey = styleKey || normalized.key;
        normalized.label = text(pick(value, 'label', 'Label'), normalized.label).slice(0, 32);
        normalized.subtitle = text(pick(value, 'subtitle', 'Subtitle'), normalized.subtitle).slice(0, 48);
        normalized.emoji = text(pick(value, 'emoji', 'Emoji'), normalized.emoji).slice(0, 12);
        normalized.colors = normalizeColors({
            ...normalized.colors,
            accent: pick(value, 'accent', 'Accent') ?? normalized.colors.accent,
            surface: pick(value, 'surface', 'Surface') ?? normalized.colors.surface,
            border: pick(value, 'border', 'Border') ?? normalized.colors.border,
            text: pick(value, 'text', 'Text') ?? normalized.colors.text,
        });
        normalized.serverId = pick(value, 'serverId', 'source', 'playerId');
        normalized.showServerId = truthy(pick(value, 'showServerId', 'ShowServerId'), false);
        normalized.afk = truthy(pick(value, 'afk', 'isAfk'), false);
        normalized.afkLabel = text(pick(value, 'afkLabel', 'AfkLabel'), 'AFK').slice(0, 18);
        return normalized;
    }

    function applyBadgeColors(badge, colors) {
        const pairs = [
            ['--tag-accent', colors.accent],
            ['--tag-surface', colors.surface],
            ['--tag-border', colors.border],
            ['--tag-text', colors.text],
        ];
        pairs.forEach(([property, value]) => {
            if (value) {
                badge.style.setProperty(property, value);
            }
        });
    }

    function createBadge(raw, context = 'preview') {
        const definition = normalizeDefinition(raw);
        const effect = context === 'compact' ? 'none' : definition.effect;
        const badge = document.createElement('div');
        badge.className = `tag-badge tone--${definition.tone} variant--${definition.variant} font--${definition.font} effect--${effect}`;
        badge.classList.toggle('is-uppercase', definition.uppercase);
        applyBadgeColors(badge, definition.colors);

        if (definition.background) {
            const background = definition.background;
            const useFallback = background.animated && (context === 'compact' || reducedMotionQuery.matches);
            const file = useFallback ? background.fallback : background.file;
            if (file) {
                const motion = context === 'compact' ? 'none' : background.motion;
                const backdrop = document.createElement('span');
                backdrop.className = 'tag-badge__backdrop';
                backdrop.setAttribute('aria-hidden', 'true');
                backdrop.style.backgroundImage = `url("assets/tag-backgrounds/${encodeURIComponent(file)}")`;
                backdrop.style.backgroundSize = background.fit === 'fill' ? '100% 100%' : background.fit;
                backdrop.style.backgroundPosition = background.position;
                badge.style.setProperty('--tag-background-opacity', String(background.opacity));
                badge.classList.add('has-background', `background-tint--${background.tint}`, `background-motion--${motion}`);
                badge.appendChild(backdrop);
            }
        }

        if (definition.symbol !== 'none') {
            const symbol = document.createElement('span');
            symbol.className = 'tag-badge__symbol';
            if (definition.symbol === 'emoji' && definition.emoji) {
                symbol.textContent = definition.emoji;
            } else {
                symbol.appendChild(svgElement(definition.icon));
            }
            badge.appendChild(symbol);
        }

        const copy = document.createElement('span');
        copy.className = 'tag-badge__copy';
        const label = document.createElement('strong');
        label.className = 'tag-badge__label';
        label.textContent = definition.label || 'TAG';
        copy.appendChild(label);
        if (definition.subtitle) {
            const subtitle = document.createElement('small');
            subtitle.className = 'tag-badge__subtitle';
            subtitle.textContent = definition.subtitle;
            copy.appendChild(subtitle);
        }
        badge.appendChild(copy);

        const voice = document.createElement('span');
        voice.className = 'tag-badge__voice';
        voice.appendChild(svgElement('microphone'));
        badge.appendChild(voice);
        return badge;
    }

    function worldKey(value) {
        const id = pick(value, 'serverId', 'source', 'playerId', 'id');
        return id === undefined || id === null ? '' : String(id);
    }

    function worldNode(definition, key) {
        let node = state.worldNodes.get(key);
        if (!node) {
            node = document.createElement('div');
            node.className = 'world-tag';
            node.dataset.worldId = key;
            $('#worldLayer').appendChild(node);
            state.worldNodes.set(key, node);
        }
        node.replaceChildren(createBadge(definition, 'world'));
        const meta = document.createElement('div');
        meta.className = 'world-tag__meta';
        if (definition.afk) {
            const afk = document.createElement('span');
            afk.className = 'world-tag__afk';
            afk.textContent = definition.afkLabel || 'AFK';
            meta.appendChild(afk);
        }
        if (definition.showServerId && definition.serverId !== undefined && definition.serverId !== null) {
            const id = document.createElement('span');
            id.className = 'world-tag__id';
            id.textContent = `#${definition.serverId}`;
            meta.appendChild(id);
        }
        if (meta.childElementCount > 0) {
            node.appendChild(meta);
        }
        return node;
    }

    function setWorldDefinition(raw) {
        const key = worldKey(raw || {});
        if (!key) {
            return;
        }
        const definition = normalizeDefinition(raw, key);
        if (definition.serverId === undefined || definition.serverId === null) {
            definition.serverId = key;
        }
        state.worldDefinitions.set(key, definition);
        if (state.worldNodes.has(key)) {
            worldNode(definition, key);
        }
    }

    function removeWorldDefinition(id) {
        const key = id === undefined || id === null ? '' : String(id);
        if (!key) {
            return;
        }
        state.worldDefinitions.delete(key);
        state.worldFrames.delete(key);
        const node = state.worldNodes.get(key);
        if (node) {
            node.remove();
            state.worldNodes.delete(key);
        }
    }

    function syncWorld(entries, revision) {
        const nextRevision = finite(revision, state.worldRevision);
        if (revision !== undefined && nextRevision < state.worldRevision) {
            return;
        }
        state.worldRevision = nextRevision;
        const seen = new Set();
        (Array.isArray(entries) ? entries : []).forEach((entry) => {
            const key = worldKey(entry || {});
            if (key) {
                seen.add(key);
                setWorldDefinition(entry);
            }
        });
        Array.from(state.worldDefinitions.keys()).forEach((key) => {
            if (!seen.has(key)) {
                removeWorldDefinition(key);
            }
        });
        scheduleWorldFrame();
    }

    function renderWorldFrame() {
        state.worldRaf = 0;
        const width = window.innerWidth;
        const height = window.innerHeight;
        state.worldNodes.forEach((node, key) => {
            const frame = state.worldFrames.get(key);
            if (!frame) {
                node.classList.remove('is-visible', 'is-voice');
                node.style.opacity = '0';
                return;
            }
            const x = clamp(pick(frame, 'x', 'screenX'), 0, 1);
            const y = clamp(pick(frame, 'y', 'screenY'), 0, 1);
            const scale = clamp(frame.scale, .4, 1.8);
            const opacity = clamp(frame.opacity, 0, 1);
            if (opacity <= .01) {
                node.classList.remove('is-visible', 'is-voice');
                node.style.opacity = '0';
                return;
            }
            node.style.transform = `translate3d(${Math.round(x * width)}px, ${Math.round(y * height)}px, 0) translate3d(-50%, -100%, 0) scale(${scale})`;
            node.style.opacity = String(opacity);
            node.classList.add('is-visible');
            node.classList.toggle('is-voice', truthy(pick(frame, 'voice', 'talking'), false));
        });
    }

    function scheduleWorldFrame() {
        if (!state.worldRaf) {
            state.worldRaf = window.requestAnimationFrame(renderWorldFrame);
        }
    }

    function setWorldFrame(entries) {
        const frames = new Map();
        (Array.isArray(entries) ? entries : []).forEach((entry) => {
            const key = worldKey(entry || {});
            const definition = key && state.worldDefinitions.get(key);
            if (key && definition) {
                frames.set(key, entry);
                if (!state.worldNodes.has(key)) {
                    worldNode(definition, key);
                }
            }
        });
        state.worldNodes.forEach((node, key) => {
            if (!frames.has(key)) {
                node.remove();
                state.worldNodes.delete(key);
            }
        });
        state.worldFrames = frames;
        scheduleWorldFrame();
    }

    function normalizePlayer(payload) {
        const source = payload && typeof payload === 'object' ? payload : {};
        const player = source.player && typeof source.player === 'object' ? source.player : {};
        return {
            ...player,
            name: text(pick(player, 'name', 'playerName'), text(pick(source, 'playerName', 'name'), 'Player')),
            selectedGrantId: pick(player, 'selectedGrantId', 'selectedId') ?? pick(source, 'selectedGrantId', 'selectedId'),
            visible: truthy(pick(player, 'visible', 'isVisible') ?? pick(source, 'visible', 'isVisible'), false),
            afk: truthy(pick(player, 'afk', 'isAfk') ?? pick(source, 'afk', 'isAfk'), false),
            afkEnabled: pick(player, 'afkEnabled') ?? pick(source, 'afkEnabled'),
        };
    }

    function normalizeGrant(raw) {
        const value = raw && typeof raw === 'object' ? raw : {};
        const definitionSource = value.definition || value.tag || value;
        const definition = normalizeDefinition({ ...value, ...definitionSource }, text(pick(value, 'id', 'assignmentId')));
        return {
            ...value,
            id: pick(value, 'id', 'assignmentId', 'grantId'),
            styleKey: definition.styleKey,
            styleName: text(pick(value, 'styleName', 'name'), state.styleMap.get(definition.styleKey)?.name || definition.styleKey || definition.label),
            selected: truthy(pick(value, 'selected', 'active'), false),
            expiresLabel: text(pick(value, 'expiresLabel', 'expirationLabel')),
            daysRemaining: pick(value, 'daysRemaining', 'daysLeft') ?? expirationDays(value),
            temporary: truthy(pick(value, 'temporary'), finite(pick(value, 'expiresAt', 'expires_at'), 0) > 0),
            definition,
        };
    }

    function normalizeAdmin(raw) {
        const value = raw && typeof raw === 'object' ? raw : {};
        return {
            players: Array.isArray(value.players) ? value.players : [],
            assignments: Array.isArray(value.assignments) ? value.assignments : [],
            stats: value.stats && typeof value.stats === 'object' ? value.stats : {},
        };
    }

    function updatePanelState(payload, preserveMode = false) {
        const value = payload && typeof payload === 'object' ? payload : {};
        const translations = value.strings || value.ui;
        if (translations && typeof translations === 'object') {
            state.strings = translations.ui && typeof translations.ui === 'object' ? translations.ui : translations;
        }
        if (value.locale) {
            state.locale = value.locale === 'en' ? 'en' : 'es';
        }
        if (!preserveMode && (value.mode === 'player' || value.mode === 'admin')) {
            state.mode = value.mode;
        }
        if (value.styles !== undefined) {
            setStyles(value.styles);
        }
        state.player = normalizePlayer(value);
        const grantSource = Array.isArray(value.grants) ? value.grants : Array.isArray(value.player?.grants) ? value.player.grants : state.grants;
        state.grants = grantSource.map(normalizeGrant);
        if (value.admin !== undefined) {
            state.admin = normalizeAdmin(value.admin);
        } else if (value.players || value.assignments || value.stats) {
            state.admin = normalizeAdmin(value);
        }
        if (value.session !== undefined) {
            state.session = value.session;
        }
        const selectedId = state.player.selectedGrantId;
        if (selectedId !== undefined && selectedId !== null) {
            state.grants.forEach((grant) => {
                grant.selected = String(grant.id) === String(selectedId);
            });
        }
    }

    function selectedGrant() {
        return state.grants.find((grant) => grant.selected) || null;
    }

    function setPreview(container, definition) {
        container.replaceChildren();
        if (definition) {
            container.appendChild(createBadge(definition));
        }
    }

    function grantExpiry(grant) {
        if (grant.expiresLabel) {
            return grant.expiresLabel;
        }
        const days = finite(grant.daysRemaining, -1);
        if (days === 0) {
            return tr('expires_today');
        }
        if (days > 0) {
            return tr('expires_in', { days });
        }
        return tr('permanent');
    }

    function setPlayerBusy(operation = null) {
        if (state.playerBusyTimer) {
            window.clearTimeout(state.playerBusyTimer);
            state.playerBusyTimer = null;
        }
        state.playerBusy = operation;
        if (operation) {
            state.playerBusyTimer = window.setTimeout(() => {
                state.playerBusyTimer = null;
                state.playerBusy = null;
                if (state.mode === 'player' && $('#panelApp').classList.contains('is-open')) {
                    renderPlayer();
                    toast(tr('operation_failed'), 'error');
                }
            }, 6500);
        }
    }

    function requestSelect(id) {
        if (state.playerBusy || id === undefined || id === null) {
            return;
        }
        setPlayerBusy('select');
        renderPlayer();
        play('click');
        post('select', { id }).then((response) => {
            if (!responseAccepted(response)) {
                setPlayerBusy(null);
                renderPlayer();
                toast(tr('operation_failed'), 'error');
            }
        });
    }

    function createGrantCard(grant, index) {
        const card = document.createElement('article');
        card.className = `tag-card${grant.selected ? ' is-selected' : ''}`;
        card.style.animationDelay = `${Math.min(index, 8) * 40}ms`;
        const preview = document.createElement('div');
        preview.className = 'tag-card__preview';
        preview.appendChild(createBadge(grant.definition));
        const copy = document.createElement('div');
        copy.className = 'tag-card__copy';
        const name = document.createElement('h3');
        name.textContent = grant.styleName || grant.definition.label;
        const meta = document.createElement('div');
        meta.className = 'tag-card__meta';
        const style = document.createElement('span');
        style.className = 'meta-pill';
        style.textContent = grant.styleKey || tr('custom');
        meta.appendChild(style);
        if (grant.selected) {
            const active = document.createElement('span');
            active.className = 'meta-pill meta-pill--selected';
            active.textContent = tr('active');
            meta.appendChild(active);
        }
        copy.append(name, meta);
        const footer = document.createElement('div');
        footer.className = 'tag-card__footer';
        const expiry = document.createElement('span');
        expiry.className = 'tag-card__expiry';
        expiry.textContent = grantExpiry(grant);
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `button ${grant.selected ? 'button--secondary' : 'button--primary'}`;
        button.disabled = grant.selected || state.playerBusy !== null;
        const icon = document.createElement('span');
        icon.className = 'button__icon';
        icon.appendChild(svgElement(state.playerBusy === 'select' && !grant.selected ? 'loader-circle' : grant.selected ? 'circle-check' : 'sparkles'));
        const label = document.createElement('span');
        label.textContent = grant.selected ? tr('selected') : tr('select');
        button.append(icon, label);
        button.classList.toggle('is-loading', state.playerBusy === 'select' && !grant.selected);
        button.addEventListener('click', () => requestSelect(grant.id));
        footer.append(expiry, button);
        card.append(preview, copy, footer);
        return card;
    }

    function renderPlayer() {
        const grid = $('#grantGrid');
        const current = selectedGrant();
        $('#playerName').textContent = state.player.name || 'Player';
        $('#grantCount').textContent = String(state.grants.length);
        $('#playerEmpty').hidden = state.grants.length !== 0;
        grid.hidden = state.grants.length === 0;
        grid.replaceChildren();
        state.grants.forEach((grant, index) => grid.appendChild(createGrantCard(grant, index)));
        setPreview($('#playerTagPreview'), current ? current.definition : null);

        const visible = truthy(state.player.visible, false);
        const afk = truthy(state.player.afk, false);
        const status = $('#playerStatusPill');
        status.textContent = tr(visible ? 'visible_now' : 'hidden_now');
        status.classList.toggle('is-visible', visible);

        const visibility = $('#visibilityButton');
        visibility.disabled = !current || state.playerBusy !== null;
        visibility.setAttribute('aria-pressed', String(visible));
        $('strong', visibility).textContent = tr(visible ? 'hide_tag' : 'show_tag');
        $('#visibilityState').textContent = tr(visible ? 'visible_now' : 'hidden_now');
        const visibilityIcon = $('.quick-control__icon', visibility);
        visibilityIcon.replaceChildren(svgElement(visible ? 'eye' : 'eye-off'));

        const afkButton = $('#afkButton');
        afkButton.disabled = state.player.afkEnabled === false || state.playerBusy !== null;
        afkButton.setAttribute('aria-pressed', String(afk));
        $('strong', afkButton).textContent = tr(afk ? 'disable_afk' : 'enable_afk');
        $('#afkState').textContent = tr(afk ? 'afk_active' : 'afk_inactive');
    }

    function playerMatches(player, search) {
        return !search || `${text(player.name)} ${text(pick(player, 'source', 'serverId', 'id'))}`.toLocaleLowerCase(state.locale).includes(search);
    }

    function openEditorFromPlayer(player) {
        openEditor(null, pick(player, 'source', 'serverId', 'id'));
    }

    function renderOnlinePlayers() {
        const list = $('#onlineList');
        const search = $('#playerSearch').value.trim().toLocaleLowerCase(state.locale);
        const players = state.admin.players.filter((player) => playerMatches(player, search));
        list.replaceChildren();
        $('#onlineEmpty').hidden = players.length !== 0;
        list.hidden = players.length === 0;
        players.forEach((player) => {
            const button = document.createElement('button');
            button.type = 'button';
            button.className = 'player-row';
            const avatar = document.createElement('span');
            avatar.className = 'player-row__avatar';
            avatar.appendChild(svgElement('user-round'));
            const copy = document.createElement('span');
            copy.className = 'player-row__copy';
            const name = document.createElement('strong');
            name.textContent = text(player.name, 'Player');
            const id = document.createElement('small');
            id.textContent = tr('id_label', { id: pick(player, 'source', 'serverId', 'id') ?? '—' });
            copy.append(name, id);
            const count = document.createElement('span');
            count.className = 'player-row__count';
            count.textContent = tr('assignment_count', { count: finite(pick(player, 'count', 'tagCount'), 0) });
            button.append(avatar, copy, count);
            button.addEventListener('click', () => openEditorFromPlayer(player));
            list.appendChild(button);
        });
    }

    function assignmentDefinition(assignment) {
        return normalizeDefinition(assignment.definition || assignment.tag || assignment, text(pick(assignment, 'id', 'assignmentId')));
    }

    function assignmentMatches(assignment, search) {
        const online = truthy(assignment.online, false);
        const visible = truthy(assignment.visible, false);
        const temporary = truthy(assignment.temporary, finite(pick(assignment, 'expiresAt', 'expires_at'), 0) > 0);
        const filterMatches = state.assignmentFilter === 'all'
            || (state.assignmentFilter === 'online' && online)
            || (state.assignmentFilter === 'visible' && visible)
            || (state.assignmentFilter === 'temporary' && temporary);
        const definition = assignmentDefinition(assignment);
        const haystack = `${text(pick(assignment, 'ownerName', 'playerName', 'name'))} ${definition.label} ${definition.subtitle} ${definition.styleKey}`.toLocaleLowerCase(state.locale);
        return filterMatches && (!search || haystack.includes(search));
    }

    function rowAction(iconName, label, danger = false) {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `row-action${danger ? ' row-action--danger' : ''}`;
        button.appendChild(svgElement(iconName));
        button.setAttribute('aria-label', label);
        button.title = label;
        return button;
    }

    function createAssignmentRow(assignment, index) {
        const definition = assignmentDefinition(assignment);
        const row = document.createElement('article');
        const visible = truthy(assignment.visible, false);
        const online = truthy(assignment.online, false);
        row.className = `assignment-row${visible ? ' is-visible' : ''}`;
        row.style.animationDelay = `${Math.min(index, 10) * 34}ms`;
        const top = document.createElement('div');
        top.className = 'assignment-row__top';
        const identity = document.createElement('div');
        identity.className = 'assignment-row__identity';
        const who = document.createElement('div');
        who.className = 'assignment-row__who';
        const owner = document.createElement('strong');
        owner.textContent = text(pick(assignment, 'ownerName', 'playerName', 'name'), 'Player');
        const label = document.createElement('small');
        label.textContent = definition.label;
        who.append(owner, label);
        const sample = document.createElement('div');
        sample.className = 'assignment-row__sample';
        sample.appendChild(createBadge(definition, 'compact'));
        identity.append(who, sample);
        const actions = document.createElement('div');
        actions.className = 'assignment-row__actions';
        const edit = rowAction('pencil', tr('edit'));
        edit.addEventListener('click', () => openEditor(assignment));
        const remove = rowAction('trash-2', tr('remove'), true);
        remove.addEventListener('click', () => openConfirm(assignment));
        actions.append(edit, remove);
        top.append(identity, actions);

        const meta = document.createElement('div');
        meta.className = 'assignment-row__meta';
        const style = document.createElement('span');
        style.className = 'meta-pill';
        style.textContent = definition.styleKey || tr('custom');
        const connection = document.createElement('span');
        connection.className = `meta-pill ${online ? 'meta-pill--online' : 'meta-pill--offline'}`;
        connection.textContent = tr(online ? 'online' : 'offline');
        const visibility = document.createElement('span');
        visibility.className = `meta-pill${visible ? ' meta-pill--online' : ''}`;
        visibility.textContent = tr(visible ? 'visible' : 'hidden');
        meta.append(style, connection, visibility);
        if (truthy(assignment.temporary, finite(pick(assignment, 'expiresAt', 'expires_at'), 0) > 0)) {
            const temporary = document.createElement('span');
            temporary.className = 'meta-pill';
            temporary.textContent = tr('temporary');
            meta.appendChild(temporary);
        }
        const date = document.createElement('span');
        const expiresAt = finite(pick(assignment, 'expiresAt', 'expires_at'), 0);
        const daysRemaining = expirationDays(assignment);
        date.className = 'assignment-row__date';
        date.textContent = text(pick(assignment, 'expiresLabel', 'expirationLabel'))
            || (expiresAt > 0 ? daysRemaining === 0 ? tr('expires_today') : tr('expires_in', { days: daysRemaining }) : text(pick(assignment, 'grantedAt', 'granted_at', 'grantedDate', 'createdAt')));
        date.hidden = date.textContent === '';
        meta.appendChild(date);
        row.append(top, meta);
        return row;
    }

    function renderAssignments() {
        const list = $('#assignmentList');
        const search = $('#assignmentSearch').value.trim().toLocaleLowerCase(state.locale);
        const assignments = state.admin.assignments.filter((assignment) => assignmentMatches(assignment, search));
        list.replaceChildren();
        $('#assignmentEmpty').hidden = state.admin.assignments.length !== 0;
        list.hidden = state.admin.assignments.length === 0;
        if (state.admin.assignments.length > 0 && assignments.length === 0) {
            const empty = document.createElement('div');
            empty.className = 'mini-empty';
            const icon = document.createElement('span');
            icon.appendChild(svgElement('search'));
            const copy = document.createElement('strong');
            copy.textContent = tr('operation_failed').replace('.', '');
            empty.append(icon, copy);
            list.appendChild(empty);
            return;
        }
        assignments.forEach((assignment, index) => list.appendChild(createAssignmentRow(assignment, index)));
    }

    function renderAdmin() {
        const stats = state.admin.stats || {};
        const assignments = state.admin.assignments.length;
        const people = new Set(state.admin.assignments.map((entry) => text(pick(entry, 'ownerKey', 'ownerName', 'playerName'))).filter(Boolean)).size;
        const visible = state.admin.assignments.filter((entry) => truthy(entry.visible, false)).length;
        $('#statAssignments').textContent = String(finite(pick(stats, 'assignments', 'total'), assignments));
        $('#statPeople').textContent = String(finite(pick(stats, 'people', 'players'), people));
        $('#statVisible').textContent = String(finite(stats.visible, visible));
        $('#statTemplates').textContent = String(finite(pick(stats, 'templates', 'styles'), state.styles.length));
        $('#refreshButton').classList.remove('is-spinning');
        $('#refreshButton').replaceChildren(svgElement('refresh-cw'));
        renderOnlinePlayers();
        renderAssignments();
    }

    function renderMode() {
        const admin = state.mode === 'admin';
        $('#playerView').classList.toggle('is-active', !admin);
        $('#adminView').classList.toggle('is-active', admin);
        $('#modeBadge').classList.toggle('is-admin', admin);
        $('#modeBadge').textContent = tr(admin ? 'admin_tab' : 'player_tab');
        $('#panelTitle').textContent = tr(admin ? 'admin_title' : 'brand_title');
        $('#panelSubtitle').textContent = tr(admin ? 'admin_subtitle' : 'brand_subtitle');
        if (admin) {
            renderAdmin();
        } else {
            renderPlayer();
        }
    }

    function populateTargets(selectedSource = null) {
        const select = $('#targetSelect');
        select.replaceChildren();
        const placeholder = document.createElement('option');
        placeholder.value = '';
        placeholder.disabled = true;
        placeholder.selected = selectedSource === null || selectedSource === undefined;
        placeholder.textContent = tr('choose_target');
        select.appendChild(placeholder);
        state.admin.players.forEach((player) => {
            const source = pick(player, 'source', 'serverId', 'id');
            const option = document.createElement('option');
            option.value = text(pick(player, 'token', 'targetToken'), text(source));
            option.dataset.source = text(source);
            option.textContent = `${text(player.name, 'Player')} · ${tr('id_label', { id: source ?? '—' })}`;
            option.selected = selectedSource !== null && selectedSource !== undefined && String(source) === String(selectedSource);
            select.appendChild(option);
        });
    }

    function populateStyles(selectedKey = '') {
        const select = $('#styleSelect');
        select.replaceChildren();
        state.styles.forEach((style) => {
            const option = document.createElement('option');
            option.value = style.key;
            option.textContent = style.name;
            option.selected = String(style.key) === String(selectedKey);
            select.appendChild(option);
        });
    }

    function selectedEditorStyle() {
        return state.styleMap.get($('#styleSelect').value) || state.styles[0] || normalizeStyle({}, 'custom');
    }

    function editorDefinition() {
        const style = selectedEditorStyle();
        return normalizeDefinition({
            ...style,
            styleKey: style.key,
            label: $('#labelInput').value.trim() || style.label,
            subtitle: $('#subtitleInput').value.trim() || style.subtitle,
            emoji: $('#emojiInput').value.trim() || style.emoji,
        });
    }

    function updateDaysOutput() {
        const days = finite($('#daysInput').value, 0);
        $('#daysOutput').textContent = `${days} ${tr('days')}`;
    }

    function updateEditorPreview() {
        updateDaysOutput();
        setPreview($('#editorTagPreview'), editorDefinition());
    }

    function applyStyleDefaults() {
        if (state.editing) {
            updateEditorPreview();
            return;
        }
        const style = selectedEditorStyle();
        $('#labelInput').value = style.label;
        $('#subtitleInput').value = style.subtitle;
        $('#emojiInput').value = style.emoji;
        updateEditorPreview();
    }

    function showLayer(layer, modal, focusSelector) {
        state.lastFocus = document.activeElement;
        state.activeLayer = layer;
        $('#panel').setAttribute('inert', '');
        $('#panel').setAttribute('aria-hidden', 'true');
        layer.classList.add('is-open');
        layer.setAttribute('aria-hidden', 'false');
        window.setTimeout(() => {
            const target = focusSelector ? $(focusSelector, modal) : null;
            (target || modal).focus();
        }, 30);
    }

    function hideLayer(layer, force = false) {
        if (state.busy && !force) {
            return;
        }
        layer.classList.remove('is-open');
        layer.setAttribute('aria-hidden', 'true');
        $('#panel').removeAttribute('inert');
        $('#panel').removeAttribute('aria-hidden');
        if (state.activeLayer === layer) {
            state.activeLayer = null;
        }
        if (!force && state.lastFocus && document.contains(state.lastFocus)) {
            state.lastFocus.focus();
        }
    }

    function setBusy(operation = null) {
        if (state.busyTimer) {
            window.clearTimeout(state.busyTimer);
            state.busyTimer = null;
        }
        state.busy = operation;
        const save = $('#saveButton');
        const remove = $('#confirmDeleteButton');
        save.disabled = operation !== null;
        remove.disabled = operation !== null;
        const saveIcon = $('.button__icon', save);
        saveIcon.replaceChildren(svgElement(operation === 'save' ? 'loader-circle' : 'check'));
        save.classList.toggle('is-loading', operation === 'save');
        $('#saveButtonText').textContent = operation === 'save' ? tr('loading') : tr(state.editing ? 'save' : 'deliver');
        const removeIcon = $('.button__icon', remove);
        removeIcon.replaceChildren(svgElement(operation === 'delete' ? 'loader-circle' : 'trash-2'));
        remove.classList.toggle('is-loading', operation === 'delete');
        if (operation) {
            state.busyTimer = window.setTimeout(() => {
                state.busyTimer = null;
                setBusy(null);
                toast(tr('operation_failed'), 'error');
            }, 20000);
        }
    }

    function clearRefreshBusy() {
        if (state.refreshTimer) {
            window.clearTimeout(state.refreshTimer);
            state.refreshTimer = null;
        }
        const button = $('#refreshButton');
        button.disabled = false;
        button.classList.remove('is-spinning');
        button.replaceChildren(svgElement('refresh-cw'));
    }

    function startRefreshBusy() {
        clearRefreshBusy();
        const button = $('#refreshButton');
        button.disabled = true;
        button.classList.add('is-spinning');
        state.refreshTimer = window.setTimeout(() => {
            state.refreshTimer = null;
            button.disabled = false;
            button.classList.remove('is-spinning');
            button.replaceChildren(svgElement('refresh-cw'));
            toast(tr('operation_failed'), 'error');
        }, 10000);
    }

    function openEditor(assignment = null, selectedSource = null) {
        if (state.busy) {
            return;
        }
        state.editing = assignment;
        $('#editorForm').reset();
        const definition = assignment ? assignmentDefinition(assignment) : state.styles[0] || normalizeStyle({}, 'custom');
        populateTargets(selectedSource ?? pick(assignment || {}, 'source', 'serverId', 'playerId'));
        populateStyles(definition.styleKey || definition.key);
        $('#targetField').hidden = assignment !== null;
        $('#targetSelect').disabled = assignment !== null;
        $('#editorTitle').textContent = tr(assignment ? 'editor_edit_title' : 'editor_new_title');
        $('#saveButtonText').textContent = tr(assignment ? 'save' : 'deliver');
        $('#labelInput').value = definition.label || '';
        $('#subtitleInput').value = definition.subtitle || '';
        $('#emojiInput').value = definition.emoji || '';
        $('#daysInput').value = String(clamp(pick(assignment || {}, 'days', 'durationDays', 'daysRemaining') ?? expirationDays(assignment || {}), 0, 365));
        setBusy(null);
        updateEditorPreview();
        showLayer($('#editorLayer'), $('#editorModal'), assignment ? '#styleSelect' : '#targetSelect');
        play('click');
    }

    function closeEditor() {
        hideLayer($('#editorLayer'));
        if (!state.busy) {
            state.editing = null;
        }
    }

    function openConfirm(assignment) {
        if (state.busy) {
            return;
        }
        state.deleting = assignment;
        const definition = assignmentDefinition(assignment);
        $('#confirmText').textContent = tr('delete_text', {
            label: definition.label,
            name: text(pick(assignment, 'ownerName', 'playerName', 'name'), 'Player'),
        });
        setBusy(null);
        showLayer($('#confirmLayer'), $('#confirmModal'), '#confirmDeleteButton');
        play('click');
    }

    function closeConfirm() {
        hideLayer($('#confirmLayer'));
        if (!state.busy) {
            state.deleting = null;
        }
    }

    function submitEditor(event) {
        event.preventDefault();
        if (state.busy) {
            return;
        }
        const styleKey = $('#styleSelect').value;
        const target = $('#targetSelect');
        if ((!state.editing && !target.value) || !styleKey) {
            toast(tr('required_fields'), 'error');
            return;
        }
        const selectedOption = target.selectedOptions[0];
        const expiresDays = finite($('#daysInput').value, 0);
        const payload = {
            session: state.session,
            id: state.editing ? pick(state.editing, 'id', 'assignmentId') : null,
            targetToken: state.editing ? null : target.value,
            target: state.editing ? null : target.value,
            source: state.editing ? null : selectedOption?.dataset.source,
            styleKey,
            style: styleKey,
            label: $('#labelInput').value.trim(),
            subtitle: $('#subtitleInput').value.trim(),
            emoji: $('#emojiInput').value.trim(),
            days: expiresDays,
            expiresDays,
        };
        setBusy('save');
        post('adminSave', payload).then((response) => {
            if (!responseAccepted(response)) {
                setBusy(null);
                toast(tr('operation_failed'), 'error');
            }
        });
    }

    function confirmDelete() {
        if (!state.deleting || state.busy) {
            return;
        }
        setBusy('delete');
        post('adminDelete', {
            session: state.session,
            id: pick(state.deleting, 'id', 'assignmentId'),
        }).then((response) => {
            if (!responseAccepted(response)) {
                setBusy(null);
                toast(tr('operation_failed'), 'error');
            }
        });
    }

    function openPanel(payload) {
        if (!payload || (payload.mode !== 'player' && payload.mode !== 'admin')) {
            return;
        }
        updatePanelState(payload);
        document.documentElement.lang = state.locale;
        applyTranslations();
        renderMode();
        buildPetals();
        paintIcons();
        const app = $('#panelApp');
        const generation = ++state.visibilityGeneration;
        app.hidden = false;
        app.classList.remove('is-closing');
        app.classList.add('is-open');
        app.setAttribute('aria-hidden', 'false');
        post('opened');
        window.setTimeout(() => {
            if (generation === state.visibilityGeneration && app.classList.contains('is-open')) {
                $('#panel').focus();
            }
        }, 40);
        play('open');
    }

    function resetPanel() {
        const app = $('#panelApp');
        state.visibilityGeneration += 1;
        if (state.busyTimer) {
            window.clearTimeout(state.busyTimer);
            state.busyTimer = null;
        }
        if (state.playerBusyTimer) {
            window.clearTimeout(state.playerBusyTimer);
            state.playerBusyTimer = null;
        }
        clearRefreshBusy();
        state.busy = null;
        state.playerBusy = null;
        state.editing = null;
        state.deleting = null;
        state.activeLayer = null;
        state.lastFocus = null;
        app.classList.remove('is-open', 'is-closing');
        app.setAttribute('aria-hidden', 'true');
        app.hidden = true;
        $('#panel').removeAttribute('inert');
        $('#panel').removeAttribute('aria-hidden');
        $$('.modal-layer').forEach((layer) => {
            layer.classList.remove('is-open');
            layer.setAttribute('aria-hidden', 'true');
        });
        $('#toasts').replaceChildren();
    }

    function hidePanel(sendClose = false, immediate = false) {
        const app = $('#panelApp');
        if (immediate) {
            resetPanel();
        } else if (app.classList.contains('is-open') && !app.classList.contains('is-closing')) {
            if (state.activeLayer) {
                hideLayer(state.activeLayer, true);
            }
            const generation = ++state.visibilityGeneration;
            app.classList.add('is-closing');
            window.setTimeout(() => {
                if (generation === state.visibilityGeneration) {
                    resetPanel();
                }
            }, 280);
        }
        if (sendClose) {
            post('close');
        }
    }

    function trapFocus(event) {
        const scope = state.activeLayer ? $('.modal', state.activeLayer) : $('#panel');
        if (!scope) {
            return;
        }
        const focusable = $$('button:not(:disabled):not([hidden]), input:not(:disabled):not([hidden]), select:not(:disabled):not([hidden]), [tabindex]:not([tabindex="-1"]):not([hidden])', scope)
            .filter((element) => element.offsetParent !== null);
        if (focusable.length === 0) {
            event.preventDefault();
            scope.focus();
            return;
        }
        const first = focusable[0];
        const last = focusable[focusable.length - 1];
        if (event.shiftKey && document.activeElement === first) {
            event.preventDefault();
            last.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
            event.preventDefault();
            first.focus();
        }
    }

    function handleAdminResult(message) {
        const operation = text(message.operation, state.busy || 'save');
        const ok = message.ok === true;
        if (operation === 'refresh') {
            clearRefreshBusy();
        } else {
            setBusy(null);
        }
        const payload = message.payload || message.data;
        if (payload) {
            updatePanelState(payload, true);
            renderAdmin();
        }
        if (!ok) {
            return;
        }
        if (operation === 'delete' || operation === 'revoke') {
            hideLayer($('#confirmLayer'), true);
            state.deleting = null;
        } else if (operation === 'save' || operation === 'create' || operation === 'update') {
            hideLayer($('#editorLayer'), true);
            state.editing = null;
        }
    }

    function handleMessage(event) {
        const message = event.data && typeof event.data === 'object' ? event.data : {};
        if (message.action === 'worldSync') {
            syncWorld(message.entries || message.definitions || message.payload || [], message.revision);
        } else if (message.action === 'worldSet') {
            if (message.revision === undefined || finite(message.revision, state.worldRevision) >= state.worldRevision) {
                state.worldRevision = finite(message.revision, state.worldRevision);
                setWorldDefinition(message.entry || message.definition || message.payload || message.data);
                scheduleWorldFrame();
            }
        } else if (message.action === 'worldRemove') {
            if (message.revision === undefined || finite(message.revision, state.worldRevision) >= state.worldRevision) {
                state.worldRevision = finite(message.revision, state.worldRevision);
                removeWorldDefinition(message.serverId ?? message.id ?? message.payload);
            }
        } else if (message.action === 'worldFrame') {
            setWorldFrame(message.entries || message.players || message.payload || []);
        } else if (message.action === 'open') {
            openPanel(message.payload || message.data);
        } else if (message.action === 'playerData') {
            const payload = message.payload || message.data || {};
            updatePanelState(payload, true);
            setPlayerBusy(null);
            applyTranslations();
            if (state.mode === 'player') {
                renderPlayer();
            }
        } else if (message.action === 'adminData') {
            const payload = message.payload || message.data || {};
            updatePanelState(payload, true);
            clearRefreshBusy();
            if (state.mode === 'admin') {
                renderAdmin();
            }
        } else if (message.action === 'adminResult') {
            handleAdminResult(message);
        } else if (message.action === 'toast') {
            if (message.kind === 'error' && state.playerBusy) {
                setPlayerBusy(null);
                if (state.mode === 'player') {
                    renderPlayer();
                }
            }
            toast(message.message, message.kind);
        } else if (message.action === 'close') {
            hidePanel(false, message.immediate === true);
        } else if (message.action === 'resetPanel' || message.action === 'reset') {
            resetPanel();
        }
    }

    resetPanel();
    window.addEventListener('message', handleMessage);

    document.addEventListener('DOMContentLoaded', () => {
        try {
            state.muted = localStorage.getItem('jrmy_tags_muted') === '1';
        } catch (error) {
            state.muted = false;
        }
        paintIcons();
        updateSoundButton();
        $('#closeButton').addEventListener('click', () => hidePanel(true));
        $('#soundButton').addEventListener('click', () => {
            state.muted = !state.muted;
            try {
                localStorage.setItem('jrmy_tags_muted', state.muted ? '1' : '0');
            } catch (error) {
                void error;
            }
            updateSoundButton();
            if (!state.muted) {
                play('toggle');
            }
        });
        $('#visibilityButton').addEventListener('click', () => {
            if (state.playerBusy || !selectedGrant()) {
                return;
            }
            setPlayerBusy('visibility');
            renderPlayer();
            play('toggle');
            post('toggleVisibility', { visible: !truthy(state.player.visible, false) }).then((response) => {
                if (!responseAccepted(response)) {
                    setPlayerBusy(null);
                    renderPlayer();
                    toast(tr('operation_failed'), 'error');
                }
            });
        });
        $('#afkButton').addEventListener('click', () => {
            if (state.playerBusy) {
                return;
            }
            setPlayerBusy('afk');
            renderPlayer();
            play('toggle');
            post('toggleAfk', { afk: !truthy(state.player.afk, false) }).then((response) => {
                if (!responseAccepted(response)) {
                    setPlayerBusy(null);
                    renderPlayer();
                    toast(tr('operation_failed'), 'error');
                }
            });
        });
        $('#newAssignmentButton').addEventListener('click', () => openEditor());
        $('#refreshButton').addEventListener('click', () => {
            const button = $('#refreshButton');
            if (button.disabled) {
                return;
            }
            startRefreshBusy();
            play('click');
            post('adminRefresh', { session: state.session }).then((response) => {
                if (!responseAccepted(response)) {
                    clearRefreshBusy();
                    toast(tr('operation_failed'), 'error');
                }
            });
        });
        $('#playerSearch').addEventListener('input', renderOnlinePlayers);
        $('#assignmentSearch').addEventListener('input', renderAssignments);
        $$('#assignmentFilters .chip').forEach((button) => button.addEventListener('click', () => {
            state.assignmentFilter = button.dataset.filter;
            $$('#assignmentFilters .chip').forEach((item) => {
                const selected = item === button;
                item.classList.toggle('is-active', selected);
                item.setAttribute('aria-pressed', String(selected));
            });
            renderAssignments();
            play('toggle');
        }));
        $('#editorForm').addEventListener('submit', submitEditor);
        $('#styleSelect').addEventListener('change', applyStyleDefaults);
        ['labelInput', 'subtitleInput', 'emojiInput', 'daysInput'].forEach((id) => $(`#${id}`).addEventListener('input', updateEditorPreview));
        $$('.modal-close, .editor-cancel', $('#editorLayer')).forEach((button) => button.addEventListener('click', closeEditor));
        $('.modal-backdrop', $('#editorLayer')).addEventListener('click', closeEditor);
        $$('.confirm-cancel', $('#confirmLayer')).forEach((button) => button.addEventListener('click', closeConfirm));
        $('.modal-backdrop', $('#confirmLayer')).addEventListener('click', closeConfirm);
        $('#confirmDeleteButton').addEventListener('click', confirmDelete);
        document.addEventListener('keydown', (event) => {
            if (!$('#panelApp').classList.contains('is-open')) {
                return;
            }
            if (event.key === 'Tab') {
                trapFocus(event);
            } else if (event.key === 'Escape') {
                if ($('#confirmLayer').classList.contains('is-open')) {
                    closeConfirm();
                } else if ($('#editorLayer').classList.contains('is-open')) {
                    closeEditor();
                } else {
                    hidePanel(true);
                }
            }
        });
        document.addEventListener('pointerover', (event) => {
            if ($('#panelApp').classList.contains('is-open') && event.target.closest('button, input, select, .tag-card')) {
                play('hover');
            }
        });
        window.addEventListener('resize', scheduleWorldFrame);
        post('ready');
    });

    window.jrmyTagsPreview = openPanel;
})();
