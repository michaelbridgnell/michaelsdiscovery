import SwiftUI

enum LegalDoc { case privacy, terms }

struct LegalView: View {
    let doc: LegalDoc
    @Environment(\.dismiss) var dismiss

    var title: String { doc == .privacy ? "Privacy Policy" : "Terms of Service" }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gray)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Spacer()
                    Text(title)
                        .font(.headline).foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 28)
                }
                .padding()

                ScrollView {
                    if doc == .privacy {
                        privacyContent
                    } else {
                        termsContent
                    }
                }
            }
        }
    }

    var privacyContent: some View {
        legalText("""
PRIVACY POLICY
Last updated: April 2026

1. Who we are
Sonik ("we", "us", "our") is an AI-powered music discovery app. Contact: privacy@sonik.app

2. What we collect
• Account data: username and email address when you register.
• Audio interaction data: which tracks you like or dislike, used solely to train your personal taste model.
• Posts: content you write in the Community tab.
• Authentication tokens stored on your device.

We do NOT collect:
• Precise location
• Contacts or photos
• Payment information
• Any third-party tracking data

3. How we use it
• To provide personalised music recommendations (the core feature).
• To let you connect with friends and share taste.
• To run the Community feed.
• We do not sell your data. Ever.

4. Data storage
Your data is stored on Render.com servers (US region). Audio preview files are fetched from Apple's iTunes API and are not stored by us.

5. Data retention
You may delete your account at any time by emailing privacy@sonik.app. We will delete all personal data within 30 days.

6. Third parties
• Apple iTunes Search API — used to find songs (no personal data sent).
• Render.com — hosting provider.
• LAION CLAP — open-source audio model run on our servers.

7. Your rights
You have the right to access, correct, or delete your personal data. Email privacy@sonik.app.

8. Children
Sonik is not directed at users under 13. If you are under 13, do not create an account.

9. Changes
We will notify registered users of material changes to this policy.
""")
    }

    var termsContent: some View {
        legalText("""
TERMS OF SERVICE
Last updated: April 2026

By creating a Sonik account you agree to these terms.

1. Your account
• You must be 13 or older to use Sonik.
• You are responsible for keeping your password secure.
• One account per person. Do not impersonate others.

2. Acceptable use
You agree NOT to:
• Post hate speech, harassment, or content that targets people based on race, gender, religion, nationality, sexual orientation, or disability.
• Post illegal content or promote illegal activities.
• Spam, scrape, or reverse-engineer the app.
• Attempt to access other users' data.

Violations will result in immediate account termination.

3. Your content
Posts you write remain yours. By posting you grant Sonik a non-exclusive licence to display them in the app. We do not use your content to train any external models.

4. Music content
Song previews are sourced from Apple's iTunes API under their terms of use. Sonik does not store or redistribute full audio tracks.

5. AI recommendations
The recommendation engine is experimental. We do not guarantee accuracy, completeness, or fitness for any particular purpose.

6. Disclaimers
Sonik is provided "as is". We are not liable for lost data, service interruptions, or indirect damages.

7. Changes
We may update these terms. Continued use after changes constitutes acceptance.

8. Governing law
These terms are governed by the laws of England and Wales.

Contact: legal@sonik.app
""")
    }

    func legalText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Color.white.opacity(0.75))
            .lineSpacing(5)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
