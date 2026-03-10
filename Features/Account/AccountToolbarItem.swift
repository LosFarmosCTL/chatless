import Auth
import SwiftData
import SwiftUI

public struct AccountToolbarItem: ToolbarContent {
  @EnvironmentObject private var auth: AuthenticationStore
  @EnvironmentObject private var loginService: LoginService
  @Environment(\.webAuthenticationSession) private var webAuthenticationSession

  @Query(sort: \AuthenticatedUser.lastLogin, order: .reverse)
  var accounts: [AuthenticatedUser]

  @State private var showingLogin = false

  public var placement: ToolbarItemPlacement
  public init(placement: ToolbarItemPlacement) {
    self.placement = placement
  }

  private func login() {
    Task { await loginService.login(using: webAuthenticationSession) }
  }

  public var body: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Menu {
        let accountBinding = Binding<String?>(
          get: { auth.activeUserID },
          set: { selectedID in
            if let id = selectedID {
              if auth.hasValidTokens(for: id) {
                auth.switchTo(id: id)
              } else {
                login()
              }
            }
          }
        )

        Menu("Switch Account", systemImage: "arrow.left.arrow.right") {
          Picker("Account", selection: accountBinding) {
            ForEach(accounts) { account in

              Button(action: {}) {
                AsyncImage(url: account.profileImageURL) { image in
                  // HACK: SwiftUIs native image rendering inside of a toolbar menu doesn't allow
                  // for the image to be clipped, so we have to render the clipped shape manually.
                  let renderer = ImageRenderer(
                    content: image.clipShape(RoundedRectangle(cornerRadius: 50)))

                  if let uiImage = renderer.uiImage {
                    Image(uiImage: uiImage)
                      .renderingMode(.original)
                  } else {
                    image
                  }
                } placeholder: {
                  ProgressView()
                }

                Text(account.displayName ?? account.login)

                if !auth.hasValidTokens(for: account.id) {
                  Text("Session Expired")
                }
              }
              .tag(Optional(account.id))
            }
          }
          .pickerStyle(.inline)

          Section {
            Button(action: login) {
              Image(systemName: "person.crop.circle.badge.plus")
              Text("Add account")
            }
          }
        }

        Button(role: .destructive) {
          auth.logoutActive(deleteProfile: false)
        } label: {
          Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
        }
      } label: {
        if let profile = auth.activeProfile {
          AsyncImage(url: profile.profileImageURL) { image in
            image.resizable().scaledToFill()
              .clipShape(Circle())
          } placeholder: {
            Circle().fill(Color.gray)
          }
          // use a scale effect to avoid the surrounding toolbar item from resizing
          .scaleEffect(1.6)
        } else {
          Image(systemName: "person.circle.fill")
        }
      }
    }
  }
}
