import Foundation

enum QuoteLibrary {
    static let quotes: [BlockQuote] = [
        BlockQuote(text: "The best time to plant a tree was twenty years ago. The second best time is now.", attribution: "Chinese proverb"),
        BlockQuote(text: "Attention is the rarest and purest form of generosity.", attribution: "Simone Weil"),
        BlockQuote(text: "The art of being wise is the art of knowing what to overlook.", attribution: "William James"),
        BlockQuote(text: "You will never find time for anything. If you want time, you must make it.", attribution: "Charles Buxton"),
        BlockQuote(text: "Distraction is the only thing that consoles us for our miseries.", attribution: "Blaise Pascal"),
        BlockQuote(text: "The successful warrior is the average man, with laser-like focus.", attribution: "Bruce Lee"),
        BlockQuote(text: "Concentrate all your thoughts upon the work at hand.", attribution: "Alexander Graham Bell"),
        BlockQuote(text: "Where focus goes, energy flows.", attribution: "Tony Robbins"),
        BlockQuote(text: "It is during our darkest moments that we must focus to see the light.", attribution: "Aristotle"),
        BlockQuote(text: "The shorter way to do many things is to do only one thing at a time.", attribution: "Mozart"),
        BlockQuote(text: "Silence is a source of great strength.", attribution: "Lao Tzu"),
        BlockQuote(text: "One way to boost our willpower is to meditate.", attribution: "Kelly McGonigal")
    ]

    static func random() -> BlockQuote {
        quotes.randomElement() ?? quotes[0]
    }
}

enum StoneLibrary {
    static func all(unlockedIDs: Set<String>) -> [AnchorStone] {
        let defs: [(String, String, String, AnchorStone.StoneTier)] = [
            ("first_anchor", "First Anchor", "Complete your first session", .common),
            ("hour_focused", "One Hour", "Focus for 1 hour total", .common),
            ("seven_streak", "Seven Days", "Maintain a 7-day streak", .rare),
            ("night_owl", "Night Owl", "Complete an evening session", .rare),
            ("deep_dive", "Deep Dive", "Finish an Anchored session", .rare),
            ("hundred_hours", "Century", "100 hours of focus", .legendary),
            ("thirty_streak", "Unwavering", "30-day streak", .legendary)
        ]
        return defs.map { id, name, req, tier in
            AnchorStone(id: id, name: name, requirement: req, tier: tier, isUnlocked: unlockedIDs.contains(id))
        }
    }
}

enum DefaultData {
    static func blocklists() -> [Blocklist] {
        [
            Blocklist(
                name: "Deep Work",
                apps: [
                    BlockedApp(name: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap"),
                    BlockedApp(name: "Discord", bundleIdentifier: "com.hnc.Discord"),
                    BlockedApp(name: "Messages", bundleIdentifier: "com.apple.MobileSMS"),
                    BlockedApp(name: "Mail", bundleIdentifier: "com.apple.mail")
                ],
                sites: [
                    BlockedSite(domain: "twitter.com"),
                    BlockedSite(domain: "x.com"),
                    BlockedSite(domain: "reddit.com"),
                    BlockedSite(domain: "news.ycombinator.com")
                ],
                iconName: "brain.head.profile"
            ),
            Blocklist(
                name: "Social Currents",
                apps: [
                    BlockedApp(name: "Discord", bundleIdentifier: "com.hnc.Discord"),
                    BlockedApp(name: "Telegram", bundleIdentifier: "ru.keepcoder.Telegram")
                ],
                sites: [
                    BlockedSite(domain: "instagram.com"),
                    BlockedSite(domain: "facebook.com"),
                    BlockedSite(domain: "tiktok.com")
                ],
                iconName: "bubble.left.and.bubble.right"
            ),
            Blocklist(
                name: "Evening Wind-down",
                apps: [
                    BlockedApp(name: "Safari", bundleIdentifier: "com.apple.Safari"),
                    BlockedApp(name: "Chrome", bundleIdentifier: "com.google.Chrome")
                ],
                sites: [
                    BlockedSite(domain: "youtube.com"),
                    BlockedSite(domain: "netflix.com")
                ],
                iconName: "moon.stars"
            )
        ]
    }
}
