import Account
import Auth
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
        List {
          ForEach(allAccounts) { account in
            let isValid = auth.hasValidTokens(for: account.id)

            HStack {
              AsyncImage(url: account.profileImageURL) { image in
                image.resizable().scaledToFill()
              } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
              }
              .frame(width: 40, height: 40)
              .clipShape(Circle())

              VStack(alignment: .leading) {
                Text(account.displayName ?? account.login)
                  .font(.headline)

                if account.id == auth.activeUserID {
                  Text("Active")
                    .font(.caption)
                    .foregroundStyle(.green)
                } else if !isValid {
                  Text("Session Expired - Tap to log in")
                    .font(.caption)
                    .foregroundStyle(.red)
                }
              }

              Spacer()

              if account.id == auth.activeUserID {
                Image(systemName: "checkmark")
                  .foregroundColor(.blue)
              } else if !isValid {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundColor(.red)
              }
            }
            .contentShape(Rectangle())
            .onTapGesture {
              if isValid {
                auth.switchTo(id: account.id)
              } else {
                showingLogin = true
              }
            }
          }
          .onDelete { indexSet in
            for index in indexSet {
              let accountToDelete = allAccounts[index]
              auth.removeAccount(id: accountToDelete.id, deleteProfile: true)
            }
          }
        }
        .sheet(isPresented: $showingLogin) {
          LoginButton()
        }

        LoginButton()
      }
      .navigationTitle("Chatless")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
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
