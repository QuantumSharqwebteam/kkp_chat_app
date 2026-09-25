# Chat Screen Architecture

## Files
- `lib/presentation/marketing/screen/agent_chat_screen.dart` — Agent side
- `lib/presentation/customer/screen/customer_chat_screen.dart` — Customer side
- `lib/core/services/chat_storage_service.dart` — Hive persistence layer
- `lib/data/repositories/chat_reopsitory.dart` — API calls

---

## Message Loading Flow (current — WhatsApp-style)

### On screen open (`initState` → `_loadPreviousMessages`)

**Step 1 — Cache-first (instant, no shimmer)**
- `Hive.boxExists(boxName)` — synchronous check
- If box exists: `_chatStorageService.getMessages/getCustomerMessages(boxName)`
- `_removeDuplicates()` populates `_loadedMessageIds` Set
- `setState()` with sorted messages + `_isInitialized = true`
- `_jumpToBottom()` — instant `jumpTo(maxExtent)`, no visible animation

**Step 2 — Silent background API sync**
- `fetchAgentMessages / fetchCustomerMessages(limit: 20)`
- `_removeDuplicates(apiMessages)` — only IDs not already in `_loadedMessageIds` pass through
- If new messages: `saveMessages()` to Hive, `setState()` to append
- Only scrolls to bottom if `wasAtBottom == true` or no cache existed

**Step 3 — Read-status sync (non-blocking)**
- `fetchCustomerLastMessageTimestampForAgent / fetchUserLastTimestamp`
- `_updateMessagesReadStatus(timestamp)` marks messages as read in-memory + Hive
- Does not trigger any scroll or shimmer

### Shimmer rule
```dart
!_isInitialized ? ShimmerMessageList() : messages.isEmpty ? NoChatConversation() : ListView
```
- Shimmer shows **only** when `_isInitialized == false` (fresh conversation, no cache ever)
- `_isInitialized` is set `true` after the first cache read OR after API response
- Returning users with any cached messages: **zero shimmer**

---

## Scroll Behaviour

### `_jumpToBottom()` — instant, no animation
Used when: opening a chat (cache or API first load)
```dart
_scrollController.jumpTo(_scrollController.position.maxScrollExtent);
```

### `_scrollToBottom()` — smooth 200ms animation
Used when: new socket message arrives, user sends a message
```dart
_scrollController.animateTo(maxExtent, duration: 200ms, curve: easeOut);
```

### Auto-scroll guard for incoming socket messages
```dart
final wasAtBottom = _isAtBottom;
setState(() { messages.add(message); });
if (wasAtBottom) _scrollToBottom();
```
- If user has scrolled up to read old messages → no auto-scroll (a "scroll to bottom" FAB appears instead)
- If user is at bottom → smooth scroll to show new message

### `_isAtBottom` tracking
- `_scrollController.addListener(_checkIfAtBottom)` in `initState`
- `_isAtBottom = pixels == maxScrollExtent`

### Loading more (scroll to top edge)
- `_loadMoreMessages()` is triggered when `pixels == 0`
- Prepends old messages with `insertAll(0, newMessages)` + re-sort
- Does NOT scroll — preserves the user's reading position

---

## Hive Box Names

| Data | Box name |
|------|----------|
| Agent↔Customer chat | `'$agentEmail$customerEmail'` |
| Customer↔Agent chat | `'$customerEmail'` |
| Unread count (agent) | `'${agentEmail}_unreadCounts'` |
| Last message time | `'$agentEmail${customerEmail}lastMessageTime'` |
| Customer unread count | `'${customerEmail}count'` |

---

## Deduplication

`_removeDuplicates(List<ChatMessageModel> messages)` filters against two persistent Sets:
- `_loadedMessageIds` — for text/media/voice messages (keyed by `messageId`)
- `_loadedCallIds` — for call-type messages (keyed by `callId`)

These Sets are **never cleared** within a screen session. This means:
- Cache read populates the Sets first
- API sync only appends truly new messages (IDs not seen in cache)
- Socket incoming messages are checked before adding

---

## ChatStorageService

### `getMessages(boxName, {page, limit})` — used by AgentChatScreen
- Opens Hive box
- Returns all messages from `startIndex` onwards (limit param not enforced — known quirk)
- Sorted newest-first, then reversed for display

### `getCustomerMessages(boxName, {limit, before})` — used by CustomerChatScreen
- Supports `before` timestamp for pagination
- Correctly respects `limit`
- Sorted newest-first

### Write methods
- `saveMessage(message, boxName)` — single message, key = `timestamp.toString()`
- `saveMessages(messages, boxName)` — batch `putAll()`

> **Note:** Messages are keyed by timestamp string. If two messages share a timestamp (rare), one overwrites the other. A future improvement is to key by `messageId`.

---

## Socket Integration

| Event | Handler | Side effect |
|-------|---------|-------------|
| `receiveMessage` | `_handleIncomingMessage` | append + save + conditional scroll |
| `messageDeleted` | `_handleMessageDeleted` | mark deleted in-memory + Hive |
| `chatStatus` | `_handleChatStatus` | update typing/seen indicators |
| `messagesReadUpTo` | `_handleMessagesReadUpTo` | mark read up to timestamp |

Socket callbacks are registered in `initState` and auto-cleaned by the socket service when the chat page closes (`setChatPageState(isOpen: false)`).

---

## Key Differences: Agent vs Customer

| Aspect | Agent | Customer |
|--------|-------|----------|
| Storage query | `getMessages(page)` | `getCustomerMessages()` |
| Box name | `agentEmail + customerEmail` | `customerEmail` |
| Sort on socket msg | ✅ sorts every time | ❌ no sort (appends to end) |
| Pagination tracking | `_currentPage` + `_fetchedPages` Set | No page tracking |

---

## Known Issues / Future Work

1. **`getMessages` ignores limit param** — returns all messages from `startIndex` instead of `startIndex + limit`. Fix: `allMessages.sublist(startIndex, min(startIndex + limit, allMessages.length))`.
2. **Customer screen doesn't sort on socket incoming** — message could appear out of order if timestamp is old. Fix: add `messages.sort(...)` in `_handleIncomingMessage`.
3. **Hive key is timestamp string** — should be `messageId` for reliability.
4. **`_loadedMessageIds` never cleared** — if a message is deleted server-side and resent with same ID, it won't appear. Acceptable trade-off for now.
