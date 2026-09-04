import Foundation
import Shared
import Twitch

extension ChannelStore {
  public func seedStreamStatus(channelID: String, isLive: Bool, title: String) {
    guard state(for: channelID) == nil else {
      return
    }

    let state = channel(for: channelID)
    state.isLive = isLive
    state.streamTitle = title
  }

  public func refreshStreamStatus() async {
    await refreshStreams(ids: Array(savedChannelIDs))
  }

  func scheduleRefresh(for id: String, titleOnly: Bool = false) {
    guard let state = state(for: id),
      let context
    else {
      return
    }

    pendingRefreshes[id] = (state, state.streamRevision, titleOnly)

    guard refreshTask == nil else {
      return
    }

    refreshTask = Task { [weak self] in
      defer {
        if self?.context?.id == context.id {
          self?.refreshTask = nil
        }
      }

      while !Task.isCancelled, self?.context?.id == context.id {
        // Subscription startup/recovery can notify for many channels at once.
        // Batch their Helix reconciliation rather than issue a request per subscription.
        do {
          try await Task.sleep(for: .milliseconds(100))
        } catch {
          return
        }

        guard !Task.isCancelled, self?.context?.id == context.id else {
          return
        }

        let requests =
          self?.pendingRefreshes.filter { id, request in
            self?.state(for: id) === request.state
              && request.state.streamRevision == request.revision
          } ?? [:]
        self?.pendingRefreshes.removeAll()

        guard !requests.isEmpty else {
          return
        }

        let titleOnlyIDs = Set(requests.filter { $0.value.titleOnly }.keys)
        await self?.refreshStreams(ids: Array(requests.keys), titleOnlyIDs: titleOnlyIDs)

        if self?.pendingRefreshes.isEmpty == true {
          return
        }
      }
    }
  }

  private func refreshStreams(ids: [String], titleOnlyIDs: Set<String> = []) async {
    guard let context else {
      return
    }

    for batch in ids.chunked(into: 100) {
      guard !Task.isCancelled, self.context?.id == context.id else {
        return
      }

      let token = UUID()
      let snapshots = streamSnapshots(for: batch, token: token)

      guard !snapshots.isEmpty else {
        continue
      }

      do {
        let (streams, _) = try await context.client.helix(
          endpoint: .getStreams(
            userIDs: snapshots.map { $0.0.channelID },
            limit: 100
          )
        )

        guard !Task.isCancelled, self.context?.id == context.id else {
          return
        }

        let streamsByID = Dictionary(
          streams.map { ($0.userID, $0) },
          uniquingKeysWith: { first, _ in first }
        )

        for (state, revision) in snapshots {
          guard self.state(for: state.channelID) === state,
            refreshTokens[state.channelID] == token,
            state.streamRevision == revision
          else {
            continue
          }

          let stream = streamsByID[state.channelID]
          applyStreamStatus(
            to: state,
            isLive: stream != nil,
            title: stream?.title,
            titleOnly: titleOnlyIDs.contains(state.channelID)
          )
        }
      } catch {
        // Failed requests retain the last known state; periodic reconciliation retries.
      }
    }
  }

  private func streamSnapshots(for ids: [String], token: UUID) -> [(ChannelState, Int)] {
    let savedIDs = savedChannelIDs

    return ids.compactMap { id in
      guard let state = state(for: id),
        savedIDs.contains(id)
      else {
        return nil
      }

      refreshTokens[id] = token

      return (state, state.streamRevision)
    }
  }

  private func applyStreamStatus(
    to state: ChannelState,
    isLive: Bool,
    title: String?,
    titleOnly: Bool
  ) {
    if !titleOnly {
      state.isLive = isLive
    }

    if let title {
      state.streamTitle = title
    } else if !titleOnly {
      state.streamTitle = ""
    }
  }
}
