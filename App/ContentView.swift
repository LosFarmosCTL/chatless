import Account
import Auth
import Chat
import SwiftData
import SwiftUI

struct ContentView: View {
  @EnvironmentObject private var auth: AuthenticationStore

  @Query(sort: \AuthenticatedUser.lastLogin, order: .reverse)
  var allAccounts: [AuthenticatedUser]

  @State private var showingLogin = false

  var body: some View {
    NavigationStack {
      VStack {
        ChatListView()

        LoginButton()
      }
      .sheet(isPresented: $showingLogin) {
        LoginButton()
      }
      .navigationTitle("Chatless")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            Menu("Switch Account") {
              ForEach(allAccounts) { account in
                let isValid = auth.hasValidTokens(for: account.id)
                let isActive = account.id == auth.activeUserID

                Button {
                  if isValid {
                    auth.switchTo(id: account.id)
                  } else {
                    showingLogin = true
                  }
                } label: {
                  HStack {
                    AsyncImage(url: account.profileImageURL) { image in
                      image.resizable().scaledToFill()
                    } placeholder: {
                      Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                      Text(account.displayName ?? account.login)
                      if isActive {
                        Text("Active")
                          .font(.caption)
                          .foregroundStyle(.green)
                      } else if !isValid {
                        Text("Session Expired")
                          .font(.caption)
                          .foregroundStyle(.red)
                      }
                    }
                  }
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
              } placeholder: {
                Circle().fill(Color.gray)
              }
              .frame(width: 32, height: 32)
              .clipShape(Circle())
            } else {
              Image(systemName: "person.circle.fill")
            }
          }
        }
      }
    }
  }
}

#Preview {
  let (store, container) = PreviewHelper.authSetup(loggedIn: true, numOfAccounts: 4)

  ContentView()
    .environmentObject(store)
    .modelContainer(container)
}
