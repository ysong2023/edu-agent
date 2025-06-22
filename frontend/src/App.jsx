import React, { useState } from 'react';
import './styles/App.css';

function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const sendMessage = async () => {
    if (!input.trim()) return;

    const userMessage = { role: 'user', content: input };
    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      const response = await fetch('/api/v1/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: input,
          history: messages
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      console.log('Received response data:', data);
      
      const assistantMessage = {
        role: 'assistant',
        content: data.response || 'Sorry, I could not process your request.',
        plots: data.plots || []
      };
      
      setMessages(prev => [...prev, assistantMessage]);
    } catch (error) {
      console.error('Error sending message:', error);
      const errorMessage = {
        role: 'assistant',
        content: 'Sorry, there was an error processing your request. Please try again.',
        plots: []
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>🎓 Math & Physics Education AI</h1>
        <p>Powered by Claude 3.5 Sonnet</p>
      </header>

      <div className="chat-container">
        <div className="messages">
          {messages.length === 0 && (
            <div className="welcome-message">
              <h2>Welcome to Math & Physics Education AI!</h2>
              <p>Ask me anything about physics, mathematics, or science. I can:</p>
              <ul>
                <li>Explain complex physics concepts with historical context</li>
                <li>Create interactive simulations and visualizations</li>
                <li>Help you understand mathematical relationships</li>
                <li>Provide step-by-step problem solving</li>
              </ul>
              <p>Try asking: "Explain the brachistochrone problem" or "Show me how magnets work"</p>
            </div>
          )}
          
          {messages.map((message, index) => (
            <div key={index} className={`message ${message.role}`}>
              <div className="message-content">
                {message.content}
              </div>
              {message.plots && message.plots.length > 0 && (
                <div className="plots-container">
                  {message.plots.map((plot, plotIndex) => (
                    <div key={plotIndex} className="plot">
                      <img 
                        src={`data:image/png;base64,${plot.image}`} 
                        alt={`Physics visualization ${plotIndex + 1}`}
                        className="plot-image"
                      />
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
          
          {isLoading && (
            <div className="message assistant loading">
              <div className="typing-indicator">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          )}
        </div>

        <div className="input-container">
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Ask about physics, math, or science..."
            className="message-input"
            disabled={isLoading}
          />
          <button 
            onClick={sendMessage} 
            disabled={isLoading || !input.trim()}
            className="send-button"
          >
            Send
          </button>
        </div>
      </div>
    </div>
  );
}

export default App; 