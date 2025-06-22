import React, { useState } from 'react';
import styled from 'styled-components';
import { 
  FiMessageCircle, 
  FiPlus, 
  FiTrash2, 
  FiChevronLeft, 
  FiChevronRight 
} from 'react-icons/fi';

const SidebarContainer = styled.div`
  width: ${props => props.collapsed ? '60px' : '280px'};
  height: 100vh;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-right: 1px solid rgba(255, 255, 255, 0.2);
  display: flex;
  flex-direction: column;
  transition: width 0.3s ease;
  position: relative;
  overflow: hidden;
`;

const Header = styled.div`
  padding: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 60px;
`;

const Logo = styled.div`
  color: white;
  font-size: 1.2rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 10px;
  opacity: ${props => props.collapsed ? 0 : 1};
  transition: opacity 0.3s ease;
`;

const CollapseButton = styled.button`
  background: none;
  border: none;
  color: white;
  cursor: pointer;
  padding: 5px;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.2s ease;
  
  &:hover {
    background: rgba(255, 255, 255, 0.1);
  }
`;

const NavSection = styled.div`
  flex: 1;
  padding: 20px 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
`;

const SectionTitle = styled.div`
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.8rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 1px;
  padding: 0 20px;
  margin-bottom: 10px;
  opacity: ${props => props.collapsed ? 0 : 1};
  transition: opacity 0.3s ease;
`;

const NavItem = styled.div`
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  color: ${props => props.active ? 'white' : 'rgba(255, 255, 255, 0.7)'};
  background: ${props => props.active ? 'rgba(255, 255, 255, 0.1)' : 'transparent'};
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
  
  &:hover {
    background: rgba(255, 255, 255, 0.1);
    color: white;
  }
  
  &::before {
    content: '';
    position: absolute;
    left: 0;
    top: 0;
    bottom: 0;
    width: 3px;
    background: white;
    opacity: ${props => props.active ? 1 : 0};
    transition: opacity 0.2s ease;
  }
`;

const NavIcon = styled.div`
  font-size: 1.1rem;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 20px;
`;

const NavText = styled.span`
  font-size: 0.9rem;
  opacity: ${props => props.collapsed ? 0 : 1};
  transition: opacity 0.3s ease;
  white-space: nowrap;
`;

const ActionButton = styled.button`
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  background: ${props => props.primary ? 'rgba(255, 255, 255, 0.2)' : 'transparent'};
  border: ${props => props.primary ? '1px solid rgba(255, 255, 255, 0.3)' : 'none'};
  color: white;
  cursor: pointer;
  transition: all 0.2s ease;
  border-radius: ${props => props.primary ? '8px' : '0'};
  margin: ${props => props.primary ? '0 20px' : '0'};
  
  &:hover {
    background: rgba(255, 255, 255, 0.2);
  }
`;

const ToolIndicator = styled.div`
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 20px;
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.8rem;
  opacity: ${props => props.collapsed ? 0 : 1};
  transition: opacity 0.3s ease;
`;

const ToolIcon = styled.span`
  font-size: 1rem;
`;

const Sidebar = ({ onNewChat, onClearChat, activeSection = 'chat' }) => {
  const [collapsed, setCollapsed] = useState(false);

  // Navigation items (simplified to only chat)
  const navItems = [
    { id: 'chat', icon: FiMessageCircle, label: 'Chat', path: '/' }
  ];

  // Available tools
  const tools = [
    { name: 'Python Execute', icon: '🐍', color: '#3776ab' },
    { name: 'Physics Simulate', icon: '⚡', color: '#ff6b35' },
    { name: 'Math Visualize', icon: '📊', color: '#4caf50' },
    { name: 'Education Context', icon: '🎓', color: '#2196f3' },
  ];

  const handleNewChat = () => {
    const confirmed = window.confirm('Start a new conversation? Current chat will be cleared.');
    if (confirmed) {
      onNewChat();
    }
  };

  const handleClearChat = () => {
    const confirmed = window.confirm('Clear current conversation?');
    if (confirmed) {
      onClearChat();
    }
  };

  return (
    <SidebarContainer collapsed={collapsed}>
      <Header>
        <Logo collapsed={collapsed}>
          🎓 Physics AI
        </Logo>
        <CollapseButton onClick={() => setCollapsed(!collapsed)}>
          {collapsed ? <FiChevronRight /> : <FiChevronLeft />}
        </CollapseButton>
      </Header>

      <NavSection>
        <ActionButton primary onClick={handleNewChat}>
          <FiPlus />
          {!collapsed && <span>New Chat</span>}
        </ActionButton>

        <SectionTitle collapsed={collapsed}>Navigation</SectionTitle>
        
        {navItems.map(item => (
          <NavItem key={item.id} active={activeSection === item.id}>
            <NavIcon>
              <item.icon />
            </NavIcon>
            <NavText collapsed={collapsed}>{item.label}</NavText>
          </NavItem>
        ))}

        <SectionTitle collapsed={collapsed}>Available Tools</SectionTitle>
        
        {tools.map((tool, index) => (
          <ToolIndicator key={index} collapsed={collapsed}>
            <ToolIcon>{tool.icon}</ToolIcon>
            <span>{tool.name}</span>
          </ToolIndicator>
        ))}
      </NavSection>

      <ActionButton onClick={handleClearChat}>
        <FiTrash2 />
        <NavText collapsed={collapsed}>Clear Chat</NavText>
      </ActionButton>
    </SidebarContainer>
  );
};

export default Sidebar; 