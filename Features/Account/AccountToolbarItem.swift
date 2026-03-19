import Auth
import SwiftData
import SwiftUI

public struct AccountToolbarItem: ToolbarContent {
  @Environment(\.webAuthenticationSession) private var webAuthenticationSession

  @Environment(AuthenticationStore.self) private var auth
  @Environment(LoginService.self) private var loginService

  @Query(sort: \AuthenticatedUser.lastLogin, order: .reverse)
  var accounts: [AuthenticatedUser]

  private let isLoading: Bool

  private let placement: ToolbarItemPlacement
  public init(placement: ToolbarItemPlacement, isLoading: Bool) {
    self.placement = placement
    self.isLoading = isLoading
  }

  private func login() { Task { await loginService.login(using: webAuthenticationSession) } }

  public var body: some ToolbarContent {
    ToolbarItem(id: "account", placement: self.placement) {
      Menu {
        let accountBinding = Binding<String?>(
          get: { auth.activeAccount?.profile.id },
          set: { selectedID in
            guard let selectedID else { return }

            guard auth.hasValidTokens(for: selectedID) else { return login() }
            auth.switchTo(accountID: selectedID)
          }
        )

        Menu("Switch Account", systemImage: "arrow.left.arrow.right") {
          Section {
            Button(action: login) {
              Image(systemName: "person.crop.circle.badge.plus")
              Text("Add account")
            }
          }

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

                Text(account.displayName)

                if !auth.hasValidTokens(for: account.id) {
                  Text("Login Expired")
                }
              }
              .tag(Optional(account.id))
            }
          }
          .pickerStyle(.inline)

          Button(role: .destructive) {
            auth.removeActiveAccount()
          } label: {
            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
          }
        }

        Section {
          Button {
          } label: {
            Label("Settings", systemImage: "gear")
          }
        }
      } label: {
        if isLoading {
          ProgressView()
        } else if let profile = auth.activeAccount?.profile {
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
