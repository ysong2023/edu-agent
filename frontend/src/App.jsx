import React, { useState, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';
import 'katex/dist/katex.min.css';
import './styles/App.css';

function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showWelcome, setShowWelcome] = useState(true);

  // Load messages from localStorage on component mount
  useEffect(() => {
    const savedMessages = localStorage.getItem('chat-messages');
    if (savedMessages) {
      try {
        const parsedMessages = JSON.parse(savedMessages);
        setMessages(parsedMessages);
        if (parsedMessages.length > 0) {
          setShowWelcome(false);
        }
      } catch (error) {
        console.error('Failed to load saved messages:', error);
      }
    }
  }, []);

  // Save messages to localStorage whenever messages change
  useEffect(() => {
    if (messages.length > 0) {
      localStorage.setItem('chat-messages', JSON.stringify(messages));
      setShowWelcome(false);
    }
  }, [messages]);

  const sendMessage = async () => {
    if (!input.trim()) return;

    const userMessage = { role: 'user', content: input };
    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      // Get API URL from environment variable with fallback
      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:8000';
      console.log('🚀 Sending request to:', `${apiUrl}/api/v1/chat`);
      
      const response = await fetch(`${apiUrl}/api/v1/chat`, {
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
      console.log('Plots data:', data.plots);
      
      const assistantMessage = {
        role: 'assistant',
        content: data.message || 'Sorry, I could not process your request.',
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

  const handleExit = () => {
    // Clear messages and return to welcome screen
    setMessages([]);
    setShowWelcome(true);
    setInput('');
    localStorage.removeItem('chat-messages');
  };

  // Custom code block renderer for syntax highlighting
  const CodeBlock = ({ node, inline, className, children, ...props }) => {
    const match = /language-(\w+)/.exec(className || '');
    const language = match ? match[1] : '';
    
    return !inline && language ? (
      <SyntaxHighlighter
        style={vscDarkPlus}
        language={language}
        PreTag="div"
        customStyle={{
          margin: '1rem 0',
          borderRadius: '8px',
          fontSize: '0.9rem'
        }}
        {...props}
      >
        {String(children).replace(/\n$/, '')}
      </SyntaxHighlighter>
    ) : (
      <code className={className} {...props}>
        {children}
      </code>
    );
  };

  // Custom image renderer for generated plots
  const ImageRenderer = ({ src, alt, ...props }) => {
    // Check if this is a plot reference (starts with @plot_)
    if (src && src.startsWith('@plot_')) {
      const plotId = src.substring(1); // Remove the @ symbol
      
      // Find the corresponding plot in the current message's plots
      // This is a bit tricky since we need access to the current message context
      // For now, we'll just return a placeholder or the original src
      return (
        <div className="plot-reference">
          <em>Plot reference: {plotId}</em>
        </div>
      );
    }
    
    // Regular image
    return (
      <img 
        src={src} 
        alt={alt} 
        className="markdown-image"
        {...props}
      />
    );
  };

  return (
    <div className="app">
      <header className="app-header">
        <div className="header-content">
          <div className="header-text">
            <h1>🎓 Math & Physics Education AI</h1>
            <p>Powered by Claude 3.5 Sonnet</p>
          </div>
          {!showWelcome && (
            <button className="exit-button" onClick={handleExit} title="Return to Home">
              ← Exit
            </button>
          )}
        </div>
      </header>

      <div className="chat-container">
        <div className="messages">
          {showWelcome && (
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
                {message.role === 'assistant' ? (
                                    <div className="markdown-content">
                    <ReactMarkdown 
                      remarkPlugins={[remarkMath]}
                      rehypePlugins={[rehypeKatex]}
                      components={{
                        code: CodeBlock,
                        img: ImageRenderer
                      }}
                    >
                      {message.content}
                    </ReactMarkdown>
                  </div>
                ) : (
                  message.content
                )}
              </div>
              {message.plots && message.plots.length > 0 && (
                <div className="plots-container">
                  {message.plots.map((plot, plotIndex) => {
                    // Handle both old Base64 format and new URL format
                    const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:8000';
                    let imageUrl;
                    
                    if (plot.url) {
                      // New URL format from backend
                      imageUrl = `${apiUrl}${plot.url}`;
                    } else if (plot.image) {
                      // Old Base64 format
                      imageUrl = `data:image/png;base64,${plot.image}`;
                    } else if (typeof plot === 'string') {
                      // Direct Base64 string
                      imageUrl = `data:image/png;base64,${plot}`;
                    } else {
                      console.warn('Invalid plot data in App.jsx:', plot);
                      return null;
                    }
                    
                    return (
                      <div key={plotIndex} className="plot">
                        <img 
                          src={imageUrl} 
                          alt={`Physics visualization ${plotIndex + 1}`}
                          className="plot-image"
                        />
                      </div>
                    );
                  })}
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