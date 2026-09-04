import Foundation
import Twitch
import TwitchIRC

@MainActor
final class IRCChatConnection {
  var onMessage: (PrivateMessage) -> Void = { _ in }
  var onStatus: (String, ChatConnectionStatus) -> Void = { _, _ in }

  private var desired: Set<String> = []
  private var client: TwitchIRCClient?

  private var setupTask: Task<Void, Never>?
  private var messageTask: Task<Void, Never>?
  private var stateTask: Task<Void, Never>?
  private var membershipTask: Task<Void, Never>?
  private var retryTasks: [UUID: Task<Void, Never>] = [:]

  private var latestState: IRCState?
  private var observersInstalled = false
  private var generation = UUID()

  isolated deinit {
    stop()
  }

  func setChannels(_ logins: Set<String>) {
    desired = logins

    guard !desired.isEmpty else {
      stop()
      return
    }

    if client == nil {
      start()
    }

    publishStatuses()
    reconcileMembership()
  }

  func retry(_ login: String) {
    guard desired.contains(login) else {
      return
    }

    if client == nil || latestState?.status == .shutdown {
      start()
      return
    }

    if case .failed = latestState?.status {
      start()
      return
    }

    guard let client else {
      return
    }

    let generation = generation
    let requestID = UUID()

    retryTasks[requestID] = Task { [weak self] in
      defer {
        self?.retryTasks[requestID] = nil
      }

      do {
        try await client.retryChannel(login)
      } catch {
        guard !Task.isCancelled, self?.generation == generation,
          self?.desired.contains(login) == true
        else {
          return
        }

        self?.onStatus(login, .failed(String(describing: error)))
      }
    }
  }

  private func start() {
    stop()

    let generation = generation
    let client = TwitchIRCClient(.anonymous, mode: .receiveOnly)
    self.client = client

    publishStatuses()

    setupTask = Task { [weak self] in
      // Register both observers before connecting, including during multi-socket startup.
      let messages = await client.messages()
      let states = await client.stateUpdates()

      guard !Task.isCancelled, self?.generation == generation else {
        await client.shutdown()
        return
      }

      self?.observe(messages: messages, states: states, generation: generation)
      self?.observersInstalled = true
      self?.reconcileMembership()

      do {
        try await client.connect()
      } catch {
        guard !Task.isCancelled, self?.generation == generation else {
          return
        }

        self?.publishFailure(error)
      }
    }
  }

  private func observe(
    messages: AsyncThrowingStream<IncomingMessage, Error>,
    states: AsyncStream<IRCState>,
    generation: UUID
  ) {
    messageTask = Task { [weak self] in

      do {
        for try await message in messages {
          guard !Task.isCancelled, self?.generation == generation else {
            return
          }

          if case .privateMessage(let message) = message,
            self?.desired.contains(message.channel.lowercased()) == true
          {
            self?.onMessage(message)
          }
        }
      } catch {
        guard !Task.isCancelled, self?.generation == generation else {
          return
        }

        self?.publishFailure(error)
      }
    }

    stateTask = Task { [weak self] in
      for await state in states {
        guard !Task.isCancelled, self?.generation == generation else {
          return
        }

        self?.latestState = state
        self?.publishStatuses()
      }
    }
  }

  private func reconcileMembership() {
    guard observersInstalled, membershipTask == nil, let client else {
      return
    }

    let generation = generation

    membershipTask = Task { [weak self] in
      while !Task.isCancelled, self?.generation == generation {
        guard let desired = self?.desired else {
          return
        }

        do {
          try await client.setDesiredChannels(desired.sorted())
        } catch {
          guard !Task.isCancelled, self?.generation == generation else {
            return
          }

          self?.publishFailure(error)
          break
        }

        // Membership edits during suspension are coalesced into the latest complete set.
        if self?.desired == desired {
          break
        }
      }

      if self?.generation == generation {
        self?.membershipTask = nil
      }
    }
  }

  private func publishStatuses() {
    for login in desired {
      let status: ChatConnectionStatus

      if let channelStatus = latestState?.channels[login] {
        status =
          switch channelStatus {
          case .joining:
            .connecting
          case .joined:
            .connected
          case .reconnecting:
            .reconnecting("Reconnecting to chat")
          case .failed(let reason):
            .failed(String(describing: reason))
          }
      } else if case .failed(let reason) = latestState?.status {
        status = .failed(String(describing: reason))
      } else if latestState?.status == .shutdown {
        status = .idle
      } else {
        status = .connecting
      }

      onStatus(login, status)
    }
  }

  private func publishFailure(_ error: Error) {
    for login in desired {
      onStatus(login, .failed(String(describing: error)))
    }
  }

  private func stop() {
    generation = UUID()

    setupTask?.cancel()
    messageTask?.cancel()
    stateTask?.cancel()
    membershipTask?.cancel()

    for task in retryTasks.values {
      task.cancel()
    }

    setupTask = nil
    messageTask = nil
    stateTask = nil
    membershipTask = nil
    retryTasks.removeAll()

    latestState = nil
    observersInstalled = false

    let client = client
    self.client = nil

    if let client {
      Task {
        await client.shutdown()
      }
    }
  }
}
