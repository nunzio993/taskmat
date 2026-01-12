import 'package:flutter/material.dart';

/// Messages/Inbox page for desktop
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int? _selectedThreadIndex;

  final List<_Thread> _threads = [
    _Thread('Mario Rossi', 'Perfetto, ci vediamo domani alle 10!', DateTime.now().subtract(const Duration(minutes: 5)), true, 'Pulizia appartamento'),
    _Thread('Laura Bianchi', 'Ho finito il lavoro, puoi confermare?', DateTime.now().subtract(const Duration(hours: 2)), true, 'Montaggio IKEA'),
    _Thread('Giuseppe Verdi', 'Grazie mille, ottimo lavoro!', DateTime.now().subtract(const Duration(days: 1)), false, 'Riparazione rubinetto'),
    _Thread('Anna Neri', 'A che ora posso venire?', DateTime.now().subtract(const Duration(days: 2)), false, 'Giardinaggio'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          // Thread list
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Search header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cerca conversazioni...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Threads
                Expanded(
                  child: ListView.builder(
                    itemCount: _threads.length,
                    itemBuilder: (context, index) => _buildThreadItem(index),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          
          // Chat area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _selectedThreadIndex == null
                  ? _buildEmptyChat()
                  : _buildChatArea(_threads[_selectedThreadIndex!]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadItem(int index) {
    final thread = _threads[index];
    final isSelected = _selectedThreadIndex == index;
    final diff = DateTime.now().difference(thread.lastMessageAt);
    final timeAgo = diff.inMinutes < 60 ? '${diff.inMinutes}m' : (diff.inHours < 24 ? '${diff.inHours}h' : '${diff.inDays}g');

    return Material(
      color: isSelected ? Colors.teal.shade50 : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedThreadIndex = index),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.teal.shade100,
                child: Text(thread.name[0], style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(thread.name, style: TextStyle(fontWeight: thread.hasUnread ? FontWeight.bold : FontWeight.w500)),
                        ),
                        Text(timeAgo, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(thread.taskTitle, style: TextStyle(color: Colors.teal.shade600, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      thread.lastMessage,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (thread.hasUnread)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(color: Colors.teal.shade600, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Seleziona una conversazione', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildChatArea(_Thread thread) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal.shade100,
                child: Text(thread.name[0], style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(thread.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text(thread.taskTitle, style: TextStyle(color: Colors.teal.shade600, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.phone_outlined)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
            ],
          ),
        ),
        
        // Messages
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildMessage('Ciao! Sono interessato al tuo task.', false, '14:30'),
              _buildMessage('Ciao! Quando saresti disponibile?', true, '14:35'),
              _buildMessage('Posso venire domani mattina alle 10, ti va bene?', false, '14:40'),
              _buildMessage(thread.lastMessage, false, 'Ora'),
            ],
          ),
        ),
        
        // Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              IconButton(onPressed: () {}, icon: Icon(Icons.attach_file, color: Colors.grey.shade500)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Scrivi un messaggio...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.send, color: Colors.teal.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal.shade600 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.grey.shade800)),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Thread {
  final String name;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool hasUnread;
  final String taskTitle;

  _Thread(this.name, this.lastMessage, this.lastMessageAt, this.hasUnread, this.taskTitle);
}
