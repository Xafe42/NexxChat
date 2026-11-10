class ChatCommand {
  final String type;        
  final Map<String, dynamic> data;  
  final String? previewText; 
       
  const ChatCommand({
    required this.type,
    required this.data,
    this.previewText,
  });
}
