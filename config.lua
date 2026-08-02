Config = {}

-- Framework: auto, qbox, qb or esx.
Config.Framework = 'auto'

-- Language: es or en.
Config.Locale = 'es'

-- Commands.
Config.Commands = {
    Player = 'tags',
    Toggle = 'tag',
    Admin = 'tagadmin',
    AFK = 'afk',
}

-- Optional key for the personal panel.
Config.OpenKey = ''

-- Administrative access.
Config.AdminAce = 'jrmy_tags.admin'
Config.AdminGroups = {
    ['admin'] = true,
    ['superadmin'] = true,
    ['god'] = true,
}

-- Identity: license or character.
Config.IdentityScope = 'license'

-- Stable namespace for shared databases.
Config.StorageNamespace = ''

-- Assignment behavior.
Config.DefaultVisible = false
Config.MaxTagsPerPlayer = 8
Config.AdminListLimit = 500
Config.AdminSessionDuration = 600000
Config.ExpirationSweep = 60000

-- AFK status.
Config.AFK = {
    Enabled = true,
    Icon = 'moon',
    Emoji = '💤',
}

-- World rendering.
Config.Render = {
    MaxDistance = 18.0,
    ShowSelf = true,
    RequireLineOfSight = true,
    HideInvisible = true,
    MinimumAlpha = 100,
    HideWhenPaused = true,
    VoiceIndicator = true,
    ShowServerId = false,
    HeadOffset = 0.45,
    PositionInterval = 33,
    CandidateInterval = 350,
    IdleInterval = 750,
    PlayerRefreshInterval = 1000,
    MaxVisible = 24,
    FadeStart = 0.55,
    MinScale = 0.78,
}

-- Safe color presets.
Config.Tones = {
    rose = {
        Accent = '#EDB2C2',
        Surface = 'rgba(39, 27, 32, .96)',
        Border = 'rgba(237, 178, 194, .66)',
        Text = '#F6EAE6',
    },
    hot = {
        Accent = '#D9738F',
        Surface = 'rgba(39, 27, 32, .96)',
        Border = 'rgba(217, 115, 143, .72)',
        Text = '#F6EAE6',
    },
    lilac = {
        Accent = '#A392C0',
        Surface = 'rgba(39, 27, 32, .96)',
        Border = 'rgba(163, 146, 192, .72)',
        Text = '#F6EAE6',
    },
    mint = {
        Accent = '#8FD9A8',
        Surface = 'rgba(39, 27, 32, .96)',
        Border = 'rgba(143, 217, 168, .68)',
        Text = '#F6EAE6',
    },
    gold = {
        Accent = '#E8C88F',
        Surface = 'rgba(39, 27, 32, .97)',
        Border = 'rgba(232, 200, 143, .76)',
        Text = '#F6EAE6',
    },
    cream = {
        Accent = '#F6EAE6',
        Surface = 'rgba(27, 18, 22, .92)',
        Border = 'rgba(246, 234, 230, .52)',
        Text = '#F6EAE6',
    },
}

-- Local image and animated backgrounds.
Config.Backgrounds = {
    jaramiyo = {
        File = 'jaramiyo-avatar.webp',
        Fallback = 'jaramiyo-avatar.webp',
        Animated = false,
        Fit = 'cover',
        Position = 'center',
        Tint = 'medium',
        Opacity = 0.62,
        Motion = 'drift',
    },
}

-- Tag catalog.
Config.Styles = {
    owner = {
        Name = 'Owner',
        Label = 'OWNER',
        Subtitle = 'Founder',
        Symbol = 'emoji',
        Icon = 'crown',
        Emoji = '👑',
        Variant = 'royal',
        Tone = 'gold',
        Font = 'display',
        Effect = 'shimmer',
        Background = 'jaramiyo',
        Uppercase = true,
        Priority = 100,
    },
    developer = {
        Name = 'Developer',
        Label = 'DEVELOPER',
        Subtitle = 'Code atelier',
        Symbol = 'icon',
        Icon = 'code-xml',
        Emoji = '💻',
        Variant = 'mono',
        Tone = 'rose',
        Font = 'mono',
        Effect = 'glow',
        Uppercase = true,
        Priority = 90,
    },
    admin = {
        Name = 'Admin',
        Label = 'ADMIN',
        Subtitle = 'Administration',
        Symbol = 'icon',
        Icon = 'shield-check',
        Emoji = '🛡️',
        Variant = 'candy',
        Tone = 'hot',
        Font = 'display',
        Effect = 'glow',
        Uppercase = true,
        Priority = 80,
    },
    staff = {
        Name = 'Staff',
        Label = 'STAFF',
        Subtitle = 'Here to help',
        Symbol = 'emoji',
        Icon = 'star',
        Emoji = '🌸',
        Variant = 'sakura',
        Tone = 'lilac',
        Font = 'body',
        Effect = 'float',
        Background = 'jaramiyo',
        Uppercase = true,
        Priority = 70,
    },
    vip = {
        Name = 'VIP',
        Label = 'VIP',
        Subtitle = 'Special guest',
        Symbol = 'icon',
        Icon = 'gem',
        Emoji = '✨',
        Variant = 'sticker',
        Tone = 'gold',
        Font = 'display',
        Effect = 'pulse',
        Uppercase = true,
        Priority = 60,
    },
    creator = {
        Name = 'Creator',
        Label = 'CREATOR',
        Subtitle = 'Making magic',
        Symbol = 'emoji',
        Icon = 'sparkles',
        Emoji = '💗',
        Variant = 'minimal',
        Tone = 'mint',
        Font = 'body',
        Effect = 'float',
        Uppercase = true,
        Priority = 50,
    },
    event = {
        Name = 'Event',
        Label = 'EVENT',
        Subtitle = 'Limited edition',
        Symbol = 'emoji',
        Icon = 'party-popper',
        Emoji = '🎉',
        Variant = 'ribbon',
        Tone = 'rose',
        Font = 'display',
        Effect = 'shimmer',
        Uppercase = true,
        Priority = 40,
    },
}

-- Extra console output.
Config.Debug = false
