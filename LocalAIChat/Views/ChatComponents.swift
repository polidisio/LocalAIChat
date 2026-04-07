import SwiftUI

struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: animationPhase
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .onAppear {
            animationPhase = 1
        }
    }
}

struct EmptyChatView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            
            Text("Start a conversation")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Ask anything and get intelligent responses")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SendButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    @Environment(\.isEnabled) private var isEnabledEnv
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(isEnabled ? Color.accentColor : Color.gray.opacity(0.5))
                .cornerRadius(12)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

struct MessageBubble: View {
    let content: String
    let isUser: Bool
    let timestamp: Date?
    @State private var appeared = false
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(isUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(bubbleBackground)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                
                if let timestamp = timestamp {
                    Text(timestamp, style: .time)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 300, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer(minLength: 60) }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                appeared = true
            }
        }
    }
    
    private var bubbleBackground: Color {
        if isUser {
            return Color.accentColor
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
}
