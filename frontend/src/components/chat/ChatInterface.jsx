import React, { useState, useRef, useEffect } from 'react';
import styled from 'styled-components';
import { Send, RotateCcw, Trash2, AlertCircle } from 'lucide-react';
import { useChat } from '../../hooks/useChat';
import MessageBubble from './MessageBubble';
import TypingIndicator from './TypingIndicator';

const ChatContainer = styled.div`
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: var(--bg-secondary);
  overflow: hidden;
`;

const Header = styled.div`
  flex-shrink: 0;
  background: var(--bg-primary);
  border-bottom: 1px solid var(--border-color);
  padding: 1rem 1.5rem;
  
  .header-content {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }
  
  .title {
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0;
  }
  
  .subtitle {
    font-size: 0.875rem;
    color: var(--text-secondary);
    margin: 0.25rem 0 0 0;
  }
  
  .header-actions {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
`;

const ErrorAlert = styled.div`
  flex-shrink: 0;
  background: #fef2f2;
  border-left: 4px solid var(--error-color);
  padding: 1rem;
  margin: 1rem 1.5rem;
  border-radius: var(--border-radius);
  
  .error-content {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  
  .error-text {
    flex: 1;
    font-size: 0.875rem;
    color: #b91c1c;
  }
  
  .close-btn {
    background: none;
    border: none;
    color: var(--error-color);
    cursor: pointer;
    font-size: 1.25rem;
    padding: 0;
    
    &:hover {
      color: #dc2626;
    }
  }
`;

const MessagesArea = styled.div`
  flex: 1;
  overflow-y: auto;
  padding: 1rem 1.5rem;
  min-height: 0; /* Important for flex scrolling */
  
  .messages-container {
    max-width: 64rem;
    margin: 0 auto;
    
    .message-list {
      display: flex;
      flex-direction: column;
      gap: 1rem;
    }
  }
`;

const WelcomeScreen = styled.div`
  text-align: center;
  padding: 3rem 0;
  
  .welcome-icon {
    font-size: 4rem;
    margin-bottom: 1rem;
  }
  
  .welcome-title {
    font-size: 1.125rem;
    font-weight: 500;
    color: var(--text-primary);
    margin-bottom: 0.5rem;
  }
  
  .welcome-subtitle {
    color: var(--text-secondary);
    margin-bottom: 1.5rem;
  }
  
  .feature-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1rem;
    max-width: 32rem;
    margin: 0 auto 1.5rem;
  }
  
  .feature-card {
    background: var(--bg-primary);
    padding: 1rem;
    border-radius: var(--border-radius);
    border: 1px solid var(--border-color);
    text-align: left;
    
    .feature-title {
      font-weight: 500;
      color: var(--text-primary);
      margin-bottom: 0.5rem;
    }
    
    .feature-list {
      list-style: none;
      padding: 0;
      margin: 0;
      
      li {
        font-size: 0.875rem;
        color: var(--text-secondary);
        margin-bottom: 0.25rem;
      }
    }
  }
  
  .welcome-hint {
    font-size: 0.875rem;
    color: var(--text-secondary);
  }
`;

const InputArea = styled.div`
  flex-shrink: 0;
  background: var(--bg-primary);
  border-top: 1px solid var(--border-color);
  padding: 1rem 1.5rem;
  
  .input-container {
    max-width: 64rem;
    margin: 0 auto;
  }
  
  .input-form {
    display: flex;
    align-items: end;
    gap: 0.75rem;
  }
  
  .input-wrapper {
    flex: 1;
  }
  
  .message-input {
    width: 100%;
    resize: none;
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    padding: 0.75rem;
    font-size: 0.875rem;
    background: var(--bg-primary);
    color: var(--text-primary);
    font-family: inherit;
    transition: all 0.2s ease;
    
    &:focus {
      outline: none;
      border-color: var(--accent-color);
      box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }
    
    &:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
  }
  
  .send-btn {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1rem;
    border: none;
    border-radius: var(--border-radius);
    font-size: 0.875rem;
    font-weight: 500;
    color: white;
    background: var(--accent-color);
    cursor: pointer;
    transition: all 0.2s ease;
    
    &:hover:not(:disabled) {
      background: #4338ca;
      transform: translateY(-1px);
    }
    
    &:disabled {
      opacity: 0.6;
      cursor: not-allowed;
      transform: none;
    }
  }
  
  .input-meta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-top: 0.5rem;
    font-size: 0.75rem;
    color: var(--text-secondary);
  }
`;

const ClearButton = styled.button`
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.5rem 0.75rem;
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--text-primary);
  background: var(--bg-primary);
  cursor: pointer;
  transition: all 0.2s ease;
  
  &:hover:not(:disabled) {
    background: var(--bg-secondary);
  }
  
  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
`;

const ChatInterface = () => {
  const [inputMessage, setInputMessage] = useState('');
  const messagesEndRef = useRef(null);
  const inputRef = useRef(null);
  
  const { 
    messages, 
    isLoading, 
    error, 
    sendMessage, 
    clearMessages,
    clearError 
  } = useChat();

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isLoading]);

  // Focus input on mount
  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const handleSendMessage = async (e) => {
    e.preventDefault();
    
    if (!inputMessage.trim() || isLoading) {
      return;
    }
    
    const messageToSend = inputMessage.trim();
    setInputMessage('');
    
    try {
      await sendMessage(messageToSend);
    } catch (error) {
      console.error('Failed to send message:', error);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage(e);
    }
  };

  const handleClearChat = () => {
    if (window.confirm('Are you sure you want to clear all messages?')) {
      clearMessages();
    }
  };

  return (
    <ChatContainer>
      {/* Header */}
      <Header>
        <div className="header-content">
          <div>
            <h1 className="title">
              🎓 Physics & Mathematics AI Assistant
            </h1>
            <p className="subtitle">
              Ask questions about physics and mathematics concepts
            </p>
          </div>
          
          <div className="header-actions">
            <ClearButton
              onClick={handleClearChat}
              disabled={messages.length === 0}
              title="Clear conversation"
            >
              <Trash2 size={16} />
              Clear
            </ClearButton>
          </div>
        </div>
      </Header>

      {/* Error Alert */}
      {error && (
        <ErrorAlert>
          <div className="error-content">
            <AlertCircle size={20} />
            <div className="error-text">{error}</div>
            <button onClick={clearError} className="close-btn">
              ×
            </button>
          </div>
        </ErrorAlert>
      )}

      {/* Messages Area */}
      <MessagesArea>
        <div className="messages-container">
          {messages.length === 0 ? (
            <WelcomeScreen>
              <div className="welcome-icon">🎓</div>
              <h3 className="welcome-title">
                Welcome to Physics & Mathematics AI Assistant
              </h3>
              <p className="welcome-subtitle">
                I can help you with:
              </p>
              <div className="feature-grid">
                <div className="feature-card">
                  <h4 className="feature-title">📐 Mathematics</h4>
                  <ul className="feature-list">
                    <li>• Calculus and derivatives</li>
                    <li>• Function plotting</li>
                    <li>• Linear algebra</li>
                    <li>• Statistics</li>
                  </ul>
                </div>
                <div className="feature-card">
                  <h4 className="feature-title">⚡ Physics</h4>
                  <ul className="feature-list">
                    <li>• Mechanics and motion</li>
                    <li>• Electromagnetism</li>
                    <li>• Thermodynamics</li>
                    <li>• Wave phenomena</li>
                  </ul>
                </div>
              </div>
              <div className="welcome-hint">
                Try asking: "Draw a sine function graph" or "Explain Newton's laws"
              </div>
            </WelcomeScreen>
          ) : (
            <div className="message-list">
              {messages.map((message) => (
                <MessageBubble key={message.id} message={message} />
              ))}
              
              {isLoading && <TypingIndicator />}
              <div ref={messagesEndRef} />
            </div>
          )}
        </div>
      </MessagesArea>

      {/* Input Area */}
      <InputArea>
        <div className="input-container">
          <form onSubmit={handleSendMessage} className="input-form">
            <div className="input-wrapper">
              <textarea
                ref={inputRef}
                value={inputMessage}
                onChange={(e) => setInputMessage(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Ask a question about physics or mathematics..."
                className="message-input"
                rows="2"
                disabled={isLoading}
              />
            </div>
            
            <button
              type="submit"
              disabled={!inputMessage.trim() || isLoading}
              className="send-btn"
            >
              {isLoading ? (
                <RotateCcw size={16} className="animate-spin" />
              ) : (
                <Send size={16} />
              )}
              <span>
                {isLoading ? 'Sending...' : 'Send'}
              </span>
            </button>
          </form>
          
          <div className="input-meta">
            <span>Press Enter to send, Shift+Enter for new line</span>
            <span>{inputMessage.length}/1000</span>
          </div>
        </div>
      </InputArea>
    </ChatContainer>
  );
};

export default ChatInterface; 