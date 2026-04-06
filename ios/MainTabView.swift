import SwiftUI

struct MainTabView: View {

    init() {
        let bg     = UIColor(red: 0.06, green: 0.03, blue: 0.1, alpha: 1)
        let purple = UIColor(red: 0.66, green: 0.33, blue: 0.97, alpha: 1)

        let item = UITabBarItemAppearance(style: .stacked)
        item.normal.iconColor = UIColor.gray
        item.normal.titleTextAttributes  = [.foregroundColor: UIColor.gray,
                                            .font: UIFont.systemFont(ofSize: 10)]
        item.selected.iconColor = purple
        item.selected.titleTextAttributes = [.foregroundColor: purple,
                                             .font: UIFont.systemFont(ofSize: 10)]

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bg
        appearance.shadowColor     = .clear
        appearance.selectionIndicatorTintColor = .clear
        appearance.stackedLayoutAppearance       = item
        appearance.inlineLayoutAppearance        = item
        appearance.compactInlineLayoutAppearance = item

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent        = false
        UITabBar.appearance().barTintColor         = bg
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }

    var body: some View {
        TabView {
            SwipeView()
                .tabItem { Label("Discover",   systemImage: "music.note") }
            RecommendationsView()
                .tabItem { Label("For You",    systemImage: "star.fill") }
            CommunityView()
                .tabItem { Label("Community",  systemImage: "person.2.fill") }
            ProfileView()
                .tabItem { Label("Profile",    systemImage: "person.crop.circle") }
        }
        .tint(Color(hex: "a855f7"))
        .toolbarBackground(Color(hex: "0f0520"), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
