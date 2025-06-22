import React from 'react';
import styled from 'styled-components';
import { motion } from 'framer-motion';
import ReactMarkdown from 'react-markdown';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { InlineMath, BlockMath } from 'react-katex';
import 'katex/dist/katex.min.css';
import { FiUser, FiCpu, FiCode, FiBarChart, FiZap, FiSearch, FiBookOpen, FiPlay, FiRefreshCw } from 'react-icons/fi';
import { User, Bot, AlertCircle, CheckCircle } from 'lucide-react';

const MessageContainer = styled(motion.div)`
  display: flex;
  gap: 0.75rem;
  align-items: flex-start;
  ${props => props.isUser && 'flex-direction: row-reverse;'}
`;

const Avatar = styled.div`
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 0.875rem;
  flex-shrink: 0;
  
  ${props => props.isUser ? `
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
  ` : `
    background: rgba(255, 255, 255, 0.1);
    color: white;
    border: 2px solid rgba(255, 255, 255, 0.2);
  `}
`;

const MessageContent = styled.div`
  flex: 1;
  max-width: 70%;
  
  ${props => props.isUser && `
    display: flex;
    flex-direction: column;
    align-items: flex-end;
  `}
`;

const MessageBubbleStyled = styled.div`
  padding: 1rem 1.25rem;
  border-radius: 18px;
  position: relative;
  word-wrap: break-word;
  line-height: 1.5;
  
  ${props => props.isUser ? `
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border-bottom-right-radius: 4px;
  ` : `
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    color: white;
    border-bottom-left-radius: 4px;
  `}
`;

const MessageText = styled.div`
  .markdown-content {
    h1, h2, h3, h4, h5, h6 {
      margin: 1rem 0 0.5rem;
      color: ${props => props.isUser ? 'rgba(255,255,255,0.9)' : '#e2e8f0'};
    }
    
    p {
      margin: 0.5rem 0;
    }
    
    code {
      background: rgba(0, 0, 0, 0.3);
      padding: 0.2rem 0.4rem;
      border-radius: 4px;
      font-family: 'Monaco', 'Menlo', monospace;
      font-size: 0.85em;
    }
    
    pre {
      margin: 1rem 0;
      border-radius: 8px;
      overflow: hidden;
    }
    
    blockquote {
      border-left: 3px solid rgba(255, 255, 255, 0.3);
      padding-left: 1rem;
      margin: 1rem 0;
      font-style: italic;
      opacity: 0.9;
    }
    
    ul, ol {
      margin: 0.5rem 0;
      padding-left: 1.5rem;
    }
    
    li {
      margin: 0.25rem 0;
    }
  }
`;

const Timestamp = styled.div`
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.5);
  margin-top: 0.5rem;
  ${props => props.isUser && 'text-align: right;'}
`;

const ToolResults = styled.div`
  margin-top: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
`;

const ToolResult = styled.div`
  background: rgba(0, 0, 0, 0.2);
  border-radius: 12px;
  padding: 1rem;
  border-left: 3px solid ${props => props.color || '#4f46e5'};
`;

const ToolHeader = styled.div`
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
  font-weight: 600;
  font-size: 0.875rem;
  color: ${props => props.color || '#e2e8f0'};
`;

const ToolIcon = styled.div`
  display: flex;
  align-items: center;
  justify-content: center;
`;

const ToolOutput = styled.div`
  font-family: 'Monaco', 'Menlo', monospace;
  font-size: 0.8rem;
  background: rgba(0, 0, 0, 0.3);
  padding: 0.75rem;
  border-radius: 8px;
  overflow-x: auto;
  white-space: pre-wrap;
  max-height: 300px;
  overflow-y: auto;
`;

const ImageOutput = styled.img`
  max-width: 100%;
  border-radius: 8px;
  margin: 0.5rem 0;
`;

const GifContainer = styled.div`
  position: relative;
  display: inline-block;
  margin: 0.5rem 0;
`;

const ReplayButton = styled.button`
  position: absolute;
  top: 10px;
  right: 10px;
  background: rgba(0, 0, 0, 0.7);
  border: none;
  border-radius: 20px;
  color: white;
  padding: 8px 12px;
  font-size: 0.75rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  backdrop-filter: blur(5px);
  transition: all 0.2s ease;
  
  &:hover {
    background: rgba(0, 0, 0, 0.9);
    transform: scale(1.05);
  }
  
  &:active {
    transform: scale(0.95);
  }
`;

const PhysicsInfoBadge = styled.div`
  position: absolute;
  bottom: 10px;
  left: 10px;
  background: rgba(139, 92, 246, 0.9);
  color: white;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.7rem;
  font-weight: 600;
  backdrop-filter: blur(5px);
`;

// Tool icon mapping
const getToolIcon = (toolName) => {
  switch (toolName) {
    case 'python_execute':
      return <FiCode />;
    case 'physics_simulate':
      return <FiZap />;
    case 'math_visualize':
      return <FiBarChart />;
    case 'knowledge_search':
      return <FiSearch />;
    case 'education_context':
      return <FiBookOpen />;
    default:
      return <FiCpu />;
  }
};

// Tool color mapping
const getToolColor = (toolName) => {
  switch (toolName) {
    case 'python_execute':
      return '#3776ab';
    case 'physics_simulate':
      return '#ff6b35';
    case 'math_visualize':
      return '#4caf50';
    case 'knowledge_search':
      return '#2196f3';
    case 'education_context':
      return '#8b5cf6';
    default:
      return '#6b7280';
  }
};

// Custom code renderer
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
        fontSize: '0.85rem'
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

// Math formula renderer
const MathBlock = ({ value }) => {
  return <BlockMath math={value} />;
};

const MathInline = ({ value }) => {
  return <InlineMath math={value} />;
};

const MessageBubble = ({ message }) => {
  const isUser = message.type === 'user';
  
  const formatToolResults = (toolResults) => {
    if (!toolResults || toolResults.length === 0) return null;
    
    return (
      <ToolResults>
        {toolResults.map((result, index) => {
          const toolColor = getToolColor(result.tool_name);
          return (
            <ToolResult key={index} color={toolColor}>
              <ToolHeader color={toolColor}>
                <ToolIcon>
                  {getToolIcon(result.tool_name)}
                </ToolIcon>
                <span>Tool: {result.tool_name}</span>
                {result.error ? (
                  <AlertCircle size={16} color="#ef4444" />
                ) : (
                  <CheckCircle size={16} color="#10b981" />
                )}
              </ToolHeader>
              
              {result.error ? (
                <div style={{ color: '#ef4444', fontSize: '0.875rem' }}>
                  Error: {result.error}
                </div>
              ) : (
                <div>
                  {result.result?.success !== false ? (
                    <div>
                      <div style={{ 
                        color: '#10b981', 
                        fontWeight: '600', 
                        marginBottom: '0.5rem',
                        fontSize: '0.875rem'
                      }}>
                        ✓ Execution successful
                      </div>
                      {result.result?.output && (
                        <ToolOutput>
                          {result.result.output}
                        </ToolOutput>
                      )}
                      {result.result?.plots && result.result.plots.length > 0 && (
                        <div style={{ marginTop: '1rem' }}>
                          <div style={{ 
                            fontSize: '0.75rem', 
                            color: 'rgba(255,255,255,0.7)', 
                            marginBottom: '0.5rem' 
                          }}>
                            Generated plots:
                          </div>
                          {result.result.plots.map((plot, plotIndex) => {
                            const plotData = typeof plot === 'object' ? plot : { image: plot, type: 'png' };
                            const isGif = plotData.type === 'gif';
                            const imageKey = `plot-${plotIndex}-${Date.now()}`;
                            
                            const handleReplay = () => {
                              // Force re-render by changing the key
                              const img = document.querySelector(`[data-plot-key="${imageKey}"]`);
                              if (img) {
                                const src = img.src;
                                img.src = '';
                                setTimeout(() => {
                                  img.src = src;
                                }, 50);
                              }
                            };
                            
                            return isGif ? (
                              <GifContainer key={plotIndex}>
                                <ImageOutput
                                  data-plot-key={imageKey}
                                  src={`data:image/gif;base64,${plotData.image}`}
                                  alt={`Generated GIF ${plotIndex + 1}`}
                                />
                                <ReplayButton onClick={handleReplay} title="Replay GIF">
                                  <FiRefreshCw size={12} />
                                  Replay
                                </ReplayButton>
                                {plotData.physics_topic && (
                                  <PhysicsInfoBadge>
                                    🔬 {plotData.physics_topic}
                                  </PhysicsInfoBadge>
                                )}
                              </GifContainer>
                            ) : (
                              <ImageOutput
                                key={plotIndex}
                                src={`data:image/png;base64,${plotData.image || plotData}`}
                                alt={`Generated plot ${plotIndex + 1}`}
                              />
                            );
                          })}
                        </div>
                      )}
                    </div>
                  ) : (
                    <div style={{ color: '#ef4444', fontSize: '0.875rem' }}>
                      Failed: {result.result?.error || 'Unknown error'}
                    </div>
                  )}
                </div>
              )}
            </ToolResult>
          );
        })}
      </ToolResults>
    );
  };

  return (
    <MessageContainer
      isUser={isUser}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <Avatar isUser={isUser}>
        {isUser ? <User size={16} /> : <Bot size={16} />}
      </Avatar>
      
      <MessageContent isUser={isUser}>
        <MessageBubbleStyled isUser={isUser}>
          <MessageText isUser={isUser}>
            <ReactMarkdown
              className="markdown-content"
              components={{
                code: CodeBlock,
                math: MathBlock,
                inlineMath: MathInline,
              }}
            >
              {message.content}
            </ReactMarkdown>
          </MessageText>
          
          {!isUser && formatToolResults(message.tool_results)}
        </MessageBubbleStyled>
        
        <Timestamp isUser={isUser}>
          {new Date(message.timestamp).toLocaleTimeString()}
        </Timestamp>
      </MessageContent>
    </MessageContainer>
  );
};

export default MessageBubble;